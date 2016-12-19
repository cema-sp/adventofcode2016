#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  gem 'minitest'
  gem 'pry'
end

class Validator
  class << self
    def valid?(array)
      pairs = array.size.times.map do |idx|
        array.partition.with_index { |_, idx2| idx2 == idx }
      end

      pairs.all? { |pair| pair.last.inject(&:+) > pair.first.first }
    end
  end
end

# ------ tests ------

class TestValidator < Minitest::Test
  def test_valid?
    assert !Validator.valid?([5, 10, 25])

    assert !Validator.valid?([15, 10, 25])

    assert Validator.valid?([15, 11, 25])

    assert Validator.valid?([100, 100, 100])

    assert !Validator.valid?([100, 200, 100])

    assert Validator.valid?([101, 200, 100])
  end
end

# ------ main ------

file_name = ARGV[0]

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

valid = 0
invalid = 0

File.open(file_name).readlines.each do |line|
  clean_line = line.strip!

  sides = clean_line.split.map(&:to_i)

  if Validator.valid?(sides)
    valid += 1
  else
    invalid += 1
  end
end

puts "Valid: #{valid}"
puts "Invalid: #{invalid}"

valid = 0
invalid = 0

File.open(file_name).readlines.each_slice(3) do |lines|
  clean_lines = lines.map(&:strip!)

  sides3 = clean_lines.map { |line| line.split.map!(&:to_i) }.transpose

  sides3.each do |sides|
    if Validator.valid?(sides)
      valid += 1
    else
      invalid += 1
    end
  end
end

puts "Valid: #{valid}"
puts "Invalid: #{invalid}"

