#!/usr/bin/env ruby

require 'minitest'

class Recoverer
  attr_reader :store

  def initialize
    @store = []
  end

  def recover
    store.map { |letter_hash| letter_hash.max_by(&:last) }.map(&:first).join
  end

  def recover_rev
    store.map { |letter_hash| letter_hash.min_by(&:last) }.map(&:first).join
  end

  def add(word)
    word.each_char.with_index do |char, idx|
      letter_hash = store[idx] || {}
      letter_hash[char] ||= 0
      letter_hash[char] += 1

      store[idx] = letter_hash
    end
  end
end

# ------ tests ------

class RecovererTest < Minitest::Test
  def test_add
    rec = Recoverer.new

    rec.add 'eedadn'
    assert_equal rec.store, [
      { 'e' => 1 },
      { 'e' => 1 },
      { 'd' => 1 },
      { 'a' => 1 },
      { 'd' => 1 },
      { 'n' => 1 },
    ]

    rec.add 'drvtee'
    assert_equal rec.store, [
      { 'e' => 1, 'd' => 1 },
      { 'e' => 1, 'r' => 1 },
      { 'd' => 1, 'v' => 1},
      { 'a' => 1, 't' => 1 },
      { 'd' => 1, 'e' => 1 },
      { 'n' => 1, 'e' => 1 },
    ]
  end

  def test_recover
    rec = Recoverer.new

    words = <<-EOF
      eedadn
      drvtee
      eandsr
      raavrd
      atevrs
      tsrnev
      sdttsa
      rasrtv
      nssdts
      ntnada
      svetve
      tesnvt
      vntsnd
      vrdear
      dvrsen
      enarar
    EOF

    words.split("\n").map(&:strip!).each { |word| rec.add word }

    assert_equal rec.recover, 'easter'
    assert_equal rec.recover_rev, 'advent'
  end
end

# ------ main ------

file_name = ARGV[0]

fail 'No file name / "test" provided' unless file_name

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

rec = Recoverer.new
File.open(file_name).readlines.each do |line|
  rec.add(line.strip!)
end

puts "Message: #{rec.recover.inspect}"
puts "Message Reverse: #{rec.recover_rev.inspect}"

