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

describe Kantox::Chronoscope do
  let(:test) { Test1 }
  let(:test2) { Test2 }

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
    result = ⌛[:string]
    expect(result).to match "sleep_sec"
    expect(result).to match "sleep_three_secs"
    expect(result).to match "total"
    expect(result).to match(/25.*?::.*?0.5/)
    expect(result).to match(/1.*?::.*?0.5/)
    expect(result).to match(/1.*?::.*?0.3/)
  end

  it 'handles the exceptions raised from wrapped methods' do
    subject.attach(test2)
    expect { test2.new.raise_error }.to raise_error(ArgumentError)
  end
end
