require 'spec_helper'

class Test1
  def sleep_sec
    sleep 1
  end

  def sleep_three_secs
    3.times { sleep_sec }
  end
end

describe Kantox::Chronoscope do
  let(:test) { Test1 }

  it 'has a version number' do
    expect(Kantox::Chronoscope::VERSION).not_to be nil
  end

  it 'calculates proper time on sleep_three_sec' do
    subject.attach(test, :sleep_sec)
    test.new.sleep_three_secs
    result = ⌛
    expect(result).to match "sleep_sec"
    expect(result).to match "total"
    expect(result).to match "3.00"
  end

  it 'can attach to all methods of a class' do
    subject.attach(test)
    test.new.sleep_three_secs
    result = ⌛
    expect(result).to match "sleep_three_secs"
    expect(result).to match "total"
    expect(result).to match "3.00"
  end
end
