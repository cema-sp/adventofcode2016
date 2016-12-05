#!/usr/bin/env ruby

# Improvement: read by 4, read more by 1
class Unit
  NORTH = :N
  EAST  = :E
  SOUTH = :S
  WEST  = :W

  attr_reader :first

  def initialize
    @direction = NORTH
    @x = 0
    @y = 0

    @visited = { 0 => { 0 => 1 } }
    @first = nil
  end

  def apply(move)
    mtch = move.match(/(\D)(\d+)/)

    fail 'Invalid move' unless mtch

    turn!(mtch[1])
    go!(mtch[2])
  end

  def mileage
    @x.abs + @y.abs
  end

  private

  def turn!(dir)
    right = dir == 'R'

    @direction = case @direction
                 when NORTH
                   right ? EAST : WEST
                 when EAST
                   right ? SOUTH : NORTH
                 when SOUTH
                   right ? WEST : EAST
                 when WEST
                   right ? NORTH : SOUTH
                 else
                   fail 'Invalid turn'
                 end
  end

  def go!(_disp)
    disp = _disp.to_i

    case @direction
    when NORTH
      from = @y + 1
      to   = @y + disp
      (from..to).each { |y| visit!(@x, y) }

      @y += disp
    when SOUTH
      from = @y - disp
      to   = @y - 1
      (from..to).each { |y| visit!(@x, y) }

      @y -= disp
    when EAST
      from = @x + 1
      to   = @x + disp
      (from..to).each { |x| visit!(x, @y) }

      @x += disp
    when WEST
      from = @x - disp
      to   = @x - 1
      (from..to).each { |x| visit!(x, @y) }

      @x -= disp
    end
  end

  def visit!(x, y)
    @visited[x] ||= {}

    if @visited[x][y] == 1
      @first ||= x.abs + y.abs
      @visited[x][y] += 1
    else
      @visited[x][y] = 1
    end
  end
end

# ------ main ------

MAX_SIZE = 7

file_name = ARGV[0]

me = Unit.new

cnt = 0
File.open(file_name) do |file|
  while chunk = file.read(MAX_SIZE)
    parts = chunk.partition(',')
    move = parts[0]

    puts "#{cnt}. Move: #{move}"
    me.apply(move)

    next if parts.last == ''

    pos = move.size - MAX_SIZE
    file.seek(pos + 2, :CUR)
    cnt += 1
  end
end

puts "Moved: #{me.mileage}"
puts "First: #{me.first}"

