#!/usr/bin/env ruby

require 'minitest'
require 'minitest/spec'

class MyClass
  def initialize
  end
end

# ------ tests ------

describe TinyScreen do
  describe 'test' do
    it { 1.must_equal 1 }
  end
end

# ------ main ------

file_name = ARGV[0]

fail 'No file name / "test" provided' unless file_name

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

File.open(file_name).readlines.each do |line|
  # require 'pry'; binding.pry
end

