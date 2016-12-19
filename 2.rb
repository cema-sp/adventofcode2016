#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  gem 'minitest'
  gem 'pry'
end

class NumPad
  MOVES = %i(R L U D)

  attr_reader :code

  def initialize
    @row = 1
    @col = 1

    @pads = [
      [1, 4, 7],
      [2, 5, 8],
      [3, 6, 9]
    ]

    @code = []
  end

  def apply_line(line)
    fail 'Not a string' unless line.is_a? String

    line.each_char do |move|
      apply_move(move.to_sym)
    end

    @code << @pads[@col][@row]
  end

  private

  def apply_move(move)
    fail "Invalid move: #{move}" unless MOVES.include? move

    case move
    when :R
      @col += 1 unless @col == 2
    when :L
      @col -= 1 unless @col == 0
    when :D
      @row += 1 unless @row == 2
    when :U
      @row -= 1 unless @row == 0
    end
  end
end

class DiamondPad
  MOVES = %i(R L U D)

  attr_reader :code

  def initialize
    @row = 2
    @col = 0

    @pads = [
      %w(- - 1 - -),
      %w(- 2 3 4 -),
      %w(5 6 7 8 9),
      %w(- A B C -),
      %w(- - D - -)
    ].transpose

    @code = []
  end

  def apply_line(line)
    fail 'Not a string' unless line.is_a? String

    line.each_char do |move|
      apply_move(move.to_sym)
    end

    @code << @pads[@col][@row]
  end

  private

  def apply_move(move)
    fail "Invalid move: #{move}" unless MOVES.include? move

    case move
    when :R
      next_col = @col + 1
      @col = next_col if @col != 4 && button?(next_col, @row)
    when :L
      next_col = @col - 1
      @col = next_col if @col != 0 && button?(next_col, @row)
    when :D
      next_row = @row + 1
      @row = next_row if @row != 4 && button?(@col, next_row)
    when :U
      next_row = @row - 1
      @row = next_row if @row != 0 && button?(@col, next_row)
    end
  end

  def button?(col, row)
    @pads[col][row] != '-'
  end
end


# ------ tests ------

class TestNumPad < Minitest::Test
  def test_apply_line
    pads = NumPad.new

    pads.apply_line('L')
    assert_equal pads.code, [4]

    pads.apply_line('RR')
    assert_equal pads.code, [4, 6]

    pads.apply_line('U')
    assert_equal pads.code, [4, 6, 3]

    pads.apply_line('DD')
    assert_equal pads.code, [4, 6, 3, 9]
  end

  def test_apply_move
    pads = NumPad.new
    pads.send(:apply_move, :R)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [2, 1]

    pads.send(:apply_move, :U)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [2, 0]

    pads.send(:apply_move, :U)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [2, 0]

    pads.send(:apply_move, :L)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [1, 0]

    pads.send(:apply_move, :D)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [1, 1]
  end

  def test_examples
    file = <<-EOF
      ULL
      RRDDD
      LURDL
      UUUUD
    EOF

    pads = NumPad.new

    file.split.each do |line|
      pads.apply_line(line)
    end

    assert_equal pads.code, [1, 9, 8, 5]
  end
end

class TestDiamondPad < Minitest::Test
  def test_apply_move
    pads = DiamondPad.new
    pads.send(:apply_move, :L)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [0, 2]

    pads.send(:apply_move, :U)
    pads.send(:apply_move, :D)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [0, 2]

    pads.send(:apply_move, :R)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [1, 2]

    pads.send(:apply_move, :D)
    pads.send(:apply_move, :D)
    position = [pads.instance_variable_get(:@col), pads.instance_variable_get(:@row)]

    assert_equal position, [1, 3]
  end

  def test_examples
    file = <<-EOF
      ULL
      RRDDD
      LURDL
      UUUUD
    EOF

    pads = DiamondPad.new

    file.split.each do |line|
      pads.apply_line(line)
    end

    assert_equal pads.code.map(&:to_s).join, '5DB3'
  end
end

# ------ main ------

file_name = ARGV[0]

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

num_pads = NumPad.new
diamond_pads = DiamondPad.new

File.open(file_name).readlines.each do |line|
  # puts "Line: #{line.strip!.inspect}"
  clean_line = line.strip!
  num_pads.apply_line(clean_line)
  diamond_pads.apply_line(clean_line)
end

puts "Code 1: #{num_pads.code.map(&:to_s).join}"
puts "Code 2: #{diamond_pads.code.map(&:to_s).join}"

