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
  def sleep_sec
    sleep 0.1
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
    result = ⌛
    expect(result).to match "sleep_sec"
    expect(result).to match "total"
    expect(result).to match "0.30"
  end

  it 'can attach to all methods of a class' do
    subject.attach(test)
    test.new.sleep_three_secs
    result = ⌛
    expect(result).to match "sleep_sec"
    expect(result).to match "sleep_three_secs"
    expect(result).to match "total"
    expect(result).to match "0.30"
  end

  it 'can distinguish methods with same names from different classes' do
    subject.attach(test)
    subject.attach(test2)
    test.new.sleep_three_secs
    test2.new.sleep_five_secs
    result = ⌛
    expect(result).to match "sleep_sec"
    expect(result).to match "sleep_three_secs"
    expect(result).to match "total"
    expect(result).to match "0.30"
    expect(result).to match "0.50"
    expect(result).to match "1.60"
  end
end
