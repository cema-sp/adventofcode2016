#!/usr/bin/env ruby

require 'minitest'

class Room
  CHECKSUM_LENGTH = 5

  attr_reader :name
  attr_reader :id
  attr_reader :checksum

  def initialize(name, id, checksum)
    @name = name
    @id = id
    @checksum = checksum
  end

  def self.parse(room_str)
    matcher = /(.*)-(\d{3})\[(.*)\]/

    matches = room_str.match(matcher)

    fail "Invalid room: #{room_str.inspect}" unless matches

    Room.new(matches[1], matches[2].to_i, matches[3])
  end

  def calc_checksum
    dict = name.each_char.reject { |c| c == '-' }.reduce({}) do |acc, c|
      acc[c] ||= 0
      acc[c] += 1
      acc
    end

    sorted = dict.sort_by { |c, n| [n, -1 * c.ord] }.reverse

    sorted.first(CHECKSUM_LENGTH).map!(&:first).join
  end

  def valid?
    checksum == calc_checksum
  end

  def decrypt
    name.each_char.map do |c|
      if c == '-'
        ' '
      else
        ((c.ord - 'a'.ord + id) % 26 + 'a'.ord).chr
      end
    end.join
  end
end

# ------ tests ------

class RoomTest < Minitest::Test
  def test_parse
    room_str = 'aaaaa-bbb-z-y-x-123[abxyz]'
    room = Room.parse(room_str)
    assert_equal room.name, 'aaaaa-bbb-z-y-x'
    assert_equal room.id, 123
    assert_equal room.checksum, 'abxyz'
  end

  def test_calc_checksum
    room = Room.new('aaaaa-bbb-z-y-x', nil, nil)
    assert_equal room.calc_checksum, 'abxyz'

    room = Room.new('a-b-c-d-e-f-g-h', nil, nil)
    assert_equal room.calc_checksum, 'abcde'

    room = Room.new('not-a-real-room', nil, nil)
    assert_equal room.calc_checksum, 'oarel'
  end

  def test_valid?
    room = Room.new('aaaaa-bbb-z-y-x', 123, 'abxyz')
    assert room.valid?

    room = Room.new('a-b-c-d-e-f-g-h', 987, 'abcde')
    assert room.valid?

    room = Room.new('totally-real-room', 200, 'decoy')
    assert !room.valid?
  end

  def test_decrypt
    room = Room.new('qzmt-zixmtkozy-ivhz', 343, nil)
    assert_equal room.decrypt, 'very encrypted name'
  end

  def test_examples
    room_strs = <<-EOF
      aaaaa-bbb-z-y-x-123[abxyz]
      a-b-c-d-e-f-g-h-987[abcde]
      not-a-real-room-404[oarel]
      totally-real-room-200[decoy]
    EOF

    sum = room_strs.split.
      map { |str| Room.parse(str) }.
      select(&:valid?).
      map(&:id).
      reduce(0, :+)

    assert_equal sum, 1514
  end
end

# ------ main ------

file_name = ARGV[0]

fail 'No file name / "test" provided' unless file_name

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

valid_rooms = File.open(file_name).readlines.
  map { |str| Room.parse(str) }.
  select(&:valid?)

sum = valid_rooms.
  map(&:id).
  reduce(0, :+)

north_pole = valid_rooms.
  select { |r| r.decrypt =~ /north/ }

puts sum
puts north_pole.inspect

