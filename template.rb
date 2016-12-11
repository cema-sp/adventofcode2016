#!/usr/bin/env ruby

require 'minitest'

class MyClass
  def initialize
  end
end

# ------ tests ------

class MyClassTest < Minitest::Test
  def test_one
    assert_equal 1, 1
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

