#!/usr/bin/env ruby

require 'stringio'
require 'minitest'
require 'minitest/spec'

class Decompressor
  MODES    = %i(NORMAL CMD)
  VERSIONS = %i(v1 v2)

  def self.process(io, version = :v1, only_len = false)
    mode   = :NORMAL
    cmd    = nil
    buffer = nil
    out    = ''
    len    = 0

    while (char = io.read(1)) do
      case mode
      when :NORMAL
        if char == '('
          cmd = Cmd.new
          mode = :CMD
          next
        else
          out << char unless only_len
          len += 1 unless ['', "\n", ' '].include? char
        end
      when :CMD
        if char == ')'
          buffer_size, n = cmd.parse

          buffer = io.read(buffer_size)
          buffer_len = 0

          if version == :v1
            buffer_len = Decompressor.len(buffer)
          elsif version == :v2
            buffer, buffer_len = Decompressor.process(StringIO.new(buffer), :v2)
          else
            fail "Invalid version: #{version.inspect}"
          end

          unless only_len
            expanded = buffer.to_s * n.to_i
            out << expanded
          end

          len += buffer_len * n.to_i

          print '.'
          mode = :NORMAL
          next
        else
          cmd << char
        end
      else
        fail "Invalid mode: #{mode.inspect}"
      end
    end

    [out, len]
  end

  def self.len(decompressed)
    decompressed.gsub(/\s+/, '').length
  end

  class Cmd
    def initialize
      @str = ''
    end

    def <<(char)
      @str << char
    end

    def parse
      /(\d+?)x(\d+)/.match(@str).captures.map(&:to_i)
    end
  end
end

# ------ tests ------

describe Decompressor do
  describe '#process(io, version = :v1)' do
    let(:io) { StringIO.new(input) }
    let(:result) { Decompressor.process(io).tap { puts ')' } }

    describe 'when no compression' do
      let(:input) { "ADVENT" }

      it 'returns inputs string' do
        result.must_equal [input, 6]
      end
    end

    describe 'when 1 char compressed' do
      let(:input) { "A(1x5)BC" }

      it 'returns valid string' do
        result.must_equal ["ABBBBBC", 7]
      end
    end

    describe 'when compressed in the beginning' do
      let(:input) { "(3x3)XYZ" }

      it 'returns valid string' do
        result.must_equal ["XYZXYZXYZ", 9]
      end
    end

    describe 'when compressed in 2 places' do
      let(:input) { "A(2x2)BCD(2x2)EFG" }

      it 'returns valid string' do
        result.must_equal ["ABCBCDEFEFG", 11]
      end
    end

    describe 'when cmd inside compressed' do
      let(:input) { "(6x1)(1x3)A" }

      it 'returns valid string' do
        result.must_equal ["(1x3)A", 6]
      end
    end

    describe 'when cmd inside compressed' do
      let(:input) { "X(8x2)(3x3)ABCY" }

      it 'returns valid string' do
        result.must_equal ["X(3x3)ABC(3x3)ABCY", 18]
      end
    end
  end

  describe '#process(io, version = :v1)' do
    let(:io) { StringIO.new(input) }
    let(:result) { Decompressor.process(io, :v2).tap { puts ')' } }

    describe 'when no compression' do
      let(:input) { "ADVENT" }

      it 'returns inputs string' do
        result.must_equal [input, 6]
      end
    end

    describe 'when compressed in the beginning' do
      let(:input) { "(3x3)XYZ" }

      it 'returns valid string' do
        result.must_equal ["XYZXYZXYZ", 9]
      end
    end

    describe 'when cmd inside compressed' do
      let(:input) { "X(8x2)(3x3)ABCY" }

      it 'returns valid string' do
        result.must_equal ["XABCABCABCABCABCABCY", 20]
      end
    end

    describe 'when a lot of compression' do
      let(:input) { "(27x12)(20x12)(13x14)(7x10)(1x12)A" }
      let(:result) { Decompressor.process(io, :v2, true).tap { puts ')' } }

      it 'returns valid string' do
        result.must_equal ['', 241920]
      end
    end

    describe 'when a lot of compression' do
      let(:input) { "(25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN" }
      let(:result) { Decompressor.process(io, :v2, true).tap { puts ')' } }

      it 'returns valid string' do
        result.must_equal ['', 445]
      end
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

results = []
File.open(file_name) do |file|
  results << Decompressor.process(file).tap { puts ')' }
  file.rewind
  results << Decompressor.process(file, :v2, true).tap { puts ')' }
end

puts "Lengths: #{results.map(&:last).inspect}"

