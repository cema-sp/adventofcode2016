#!/usr/bin/env ruby

require 'minitest'
require 'minitest/spec'

class TinyScreen
  CMD_PARSER = /^(rect|rotate column|rotate row)\s(x=|y=)*(\d+)(\sby\s|x)(\d+)/

  attr_reader :width
  attr_reader :height
  attr_reader :screen

  def initialize(w, h)
    @width  = w
    @height = h

    @screen = Array.new(w).map { |col| Array.new(h) }
  end

  def apply_cmd(cmd)
    fail "No command provided" unless cmd && !cmd.empty?

    captures = CMD_PARSER.match(cmd)&.captures

    fail "Invalid command: #{cmd.inspect}" unless captures && captures.size == 5

    cmd_name = captures[0]
    a = captures[2].to_i
    b = captures[4].to_i

    case cmd_name
    when 'rect'
      rect(a ,b)

    when 'rotate column'
      rotate_col(a, b)

    when 'rotate row'
      rotate_row(a, b)
    end

    self
  end

  def lit_pixels
    screen.reduce(0) { |acc, col| acc + (col.reduce(0) { |acc_, pixel| (pixel.nil? ? acc_ : acc_ + 1) }) }
  end

  def rect(w, h)
    (0...w.to_i).each do |x|
      (0...h.to_i).each do |y|
        @screen[x][y] = 1 if x < width && y < height
      end
    end

    self
  end

  def rotate_row(row, shift)
    return self unless row < height

    transposed = @screen.transpose

    transposed[row].rotate!(-1 * shift.to_i)

    @screen = transposed.transpose

    self
  end

  def rotate_col(col, shift)
    return self unless col < width

    @screen[col].rotate!(-1 * shift.to_i)

    self
  end

  def to_s
    str = ''

    screen.transpose.each do |row|
      row.each do |cell|
        str << (cell.nil? ? '.' : '#')
      end
      str << "\n"
    end

    str
  end

  def print
    puts to_s
  end

  def pretty_print
    str = "|#{'-' * screen.size}|\n"
    str << to_s.split("\n").map { |line| "|#{line}|\n" }.join
    str << "|#{'-' * screen.size}|"

    puts str
  end

end

# ------ tests ------

describe TinyScreen do

  describe '#rect(w, h)' do
    let(:scr) { TinyScreen.new(7, 3) }

    it 'adds small rect' do
      w = 2
      h = 1

      exp_str = (<<-EOF).tr!(' ', '')
      ##.....
      .......
      .......
      EOF

      result_str = scr.rect(w, h).to_s
      result_str.must_equal exp_str
    end

    it 'adds medium rect' do
      w = 4
      h = 2

      exp_str = (<<-EOF).tr!(' ', '')
      ####...
      ####...
      .......
      EOF

      result_str = scr.rect(w, h).to_s
      result_str.must_equal exp_str
    end

    it 'adds large rect' do
      w = 10
      h = 5

      exp_str = (<<-EOF).tr!(' ', '')
      #######
      #######
      #######
      EOF

      result_str = scr.rect(w, h).to_s
      result_str.must_equal exp_str
    end
  end

  describe '#rotate_row(row, shift)' do
    let(:scr) { TinyScreen.new(7, 3) }

    before do
      scr.rect(3, 2)
    end

    it 'shifts row' do
      row = 0
      shift = 2

      exp_str = (<<-EOF).tr!(' ', '')
      ..###..
      ###....
      .......
      EOF

      result_str = scr.rotate_row(row, shift).to_s
      result_str.must_equal exp_str
    end

    it 'rotates row' do
      row = 1
      shift = 12

      exp_str = (<<-EOF).tr!(' ', '')
      ###....
      #....##
      .......
      EOF

      result_str = scr.rotate_row(row, shift).to_s
      result_str.must_equal exp_str
    end
  end

  describe '#rotate_col(col, shift)' do
    let(:scr) { TinyScreen.new(7, 3) }

    before do
      scr.rect(3, 2)
    end

    it 'rotates col' do
      col = 2
      shift = 2

      exp_str = (<<-EOF).tr!(' ', '')
      ###....
      ##.....
      ..#....
      EOF

      result_str = scr.rotate_col(col, shift).to_s
      result_str.must_equal exp_str
    end
  end

  describe 'apply_cmd(cmd)' do
    let(:scr) { TinyScreen.new(7, 3) }

    it 'applies commands one by one' do
      cmds =<<-EOF
        rect 3x2
        rotate column x=1 by 1
        rotate row y=0 by 4
        rotate column x=1 by 1
      EOF

      exp_str = (<<-EOF).tr!(' ', '')
      .#..#.#
      #.#....
      .#.....
      EOF

      cmds.split("\n").map(&:strip).each do |cmd|
        scr.apply_cmd(cmd)
      end

      scr.to_s.must_equal exp_str
    end
  end

  describe 'lit_pixels' do
    let(:scr) { TinyScreen.new(7, 3) }

    it 'when no pixels lit == 0' do
      scr.lit_pixels.must_equal 0
    end

    it 'when some pixels lit' do
      scr.rect(3, 3)

      scr.lit_pixels.must_equal 9
    end

    it 'when all pixels lit' do
      scr.rect(10, 4)

      scr.lit_pixels.must_equal 21
    end
  end
end

# ------ main ------

file_name = ARGV[0]

fail 'No file name / "test" provided' unless file_name

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

screen = TinyScreen.new(50, 6)

File.open(file_name).readlines.each do |line|
  screen.apply_cmd(line.strip)
end

puts "Pixels lit: #{screen.lit_pixels}"

puts "Screen:"
screen.pretty_print

