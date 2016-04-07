require 'spec_helper'

class Test1
  def sleep_sec
    sleep 0.1
  end

  def sleep_three_secs
    3.times { sleep_sec }
  end
end

class Test2
  def raise_error
    raise ArgumentError, 'Hey, I am an argument error'
  end

  def sleep_fifth_sec
    sleep 0.02
  end

  def sleep_sec
    5.times { sleep_fifth_sec }
  end

  def sleep_five_secs
    5.times { sleep_sec }
  end
end

class Test3
  attr_accessor :var

  def var?
    !@var.nil?
  end

  def simple_params(arg1, arg2)
    sleep 0.1
    arg1 + arg2
  end

  def rest_params(arg, *args)
    sleep 0.1
    [arg, *args].inject(&:+)
  end

  def hash_params(arg, *args, param: 42)
    sleep 0.1
    [arg, *args].inject(&:+) + param
  end

  def splat_params(arg, *args, param: 42, **params)
    sleep 0.1
    [arg, *args].inject(&:+) + param + params.values.inject(&:+)
  end

  # rubocop:disable Performance/RedundantBlockCall
  def block_params(arg, *args, param: 42, **params, &cb)
    sleep 0.1
    [arg, *args].inject(&:+) + param + params.values.inject(&:+) + cb.call
  end
  # rubocop:enable Performance/RedundantBlockCall
end

class Test4
  class << self
    def c_m1(arg, *args, param: 42, **params)
      sleep 0.1
      [arg, *args].inject(&:+) + param + params.values.inject(&:+)
    end
  end
end

describe Kantox::Chronoscope do
  let(:test) { Test1 }
  let(:test2) { Test2 }
  let(:test3) { Test3 }
  let(:test4) { Test4 }

  it 'has a version number' do
    expect(Kantox::Chronoscope::VERSION).not_to be nil
  end

  it 'calculates proper time on sleep_three_sec' do
    subject.attach(test, :sleep_sec)
    test.new.sleep_three_secs
    result = ⌛[:string]
    expect(result).to match "sleep_sec"
    expect(result).to match "total"
    expect(result).to match "0.3"
  end

  it 'can attach to all methods of a class' do
    subject.attach(test)
    test.new.sleep_three_secs
    result = ⌛[:string]
    expect(result).to match "sleep_sec"
    expect(result).to match "sleep_three_secs"
    expect(result).to match "total"
    expect(result).to match "0.3"
  end

  it 'builds the tree in resulting report' do
    subject.attach(test2)
    test2.new.sleep_five_secs
    result = ⌛[:string]
    expect(result).to match "sleep_fifth_sec"
    expect(result).to match "sleep_sec"
    expect(result).to match "sleep_five_secs"
    expect(result).to match "total"
  end

  it 'can distinguish methods with same names from different classes' do
    subject.attach(test)
    subject.attach(test2)
    test.new.sleep_three_secs
    test2.new.sleep_five_secs
    result = harvest
    # rubocop:disable Style/ParallelAssignment
    result, data = [result[:string], result[:data]]
    # rubocop:enable Style/ParallelAssignment
    expect(result).to match "sleep_sec"
    expect(result).to match "sleep_three_secs"
    expect(result).to match "total"
    expect(result).to match(/25.*?::.*?0.5/)
    expect(result).to match(/1.*?::.*?0.5/)
    expect(result).to match(/1.*?::.*?0.3/)
    expect(data).to be_a(Hash)
    expect(data.inspect).to match(/:stack=>\["Test2#sleep_sec", "Test2#sleep_five_secs"\]/)
  end

  it 'handles the exceptions raised from wrapped methods' do
    subject.attach(test2)
    expect { test2.new.raise_error }.to raise_error(ArgumentError)
  end

  it 'handles any parameter type properly' do
    subject.attach(test3)
    inst = test3.new
    expect(inst.var?).to be_falsey
    expect(inst.var = 42).to eq(42)
    expect(inst.var).to eq(42)
    expect(inst.var?).to be_truthy

    expect(inst.simple_params(1, 2)).to eq(3)
    expect(inst.rest_params(1, 2, 3, 4)).to eq(10)
    expect(inst.hash_params(1, 2)).to eq(45)
    expect(inst.hash_params(1, 2, param: 3)).to eq(6)
    expect(inst.splat_params(1, 2, a: 3, b: 4)).to eq(52)
    expect(inst.splat_params(1, 2, param: 3, a: 4)).to eq(10)
    expect(inst.block_params(1, 2, param: 3, a: 4) { 32 }).to eq(42)
  end

  it 'handles class methods properly' do
    subject.attach(test4, cms: :c_m1)
    inst = test4

    expect(inst.c_m1(1, 2, param: 3, a: 4)).to eq(10)
  end
end
