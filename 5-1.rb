#!/usr/bin/env ruby

require 'digest'
require 'minitest'

class Decryptor
  attr_reader :door_id
  attr_reader :zeroes

  def initialize(door_id, zeroes = 5)
    @door_id = door_id
    @zeroes  = zeroes
  end

  def crack(n = nil)
    if n
      puts ''
      code_chars = generator.take(n).map { |digest| digest[zeroes] }
      puts ''

      code_chars.join
    else
      puts ''
      digest = generator.next
      puts ''

      digest[zeroes]
    end
  end

  def crack_adv(n = nil)
    if n
      puts ''
      code_chars = Array.new(n)
      generator_adv.take_while do |digest|
        if code_chars.all?
          false
        else
          idx = digest[zeroes].to_i
          code_chars[idx] ||= digest[zeroes + 1]
          puts "\t Current code: #{code_chars.map { |c| c || '.' }.join}"

          if code_chars.all?
            false
          else
            true
          end
        end
      end
      puts ''

      code_chars.join
    else
      puts ''
      digest = generator_adv.next
      puts ''

      [digest[zeroes].to_i, digest[zeroes + 1]]
    end
  end

  def generator
    @generator ||= Enumerator.new do |yielder|
      idx = 0

      loop do
        combination = "#{door_id}#{idx}"
        digest = Digest::MD5.hexdigest combination

        print '|' if idx % 100_000 == 0

        yielder << digest if has_zeroes(digest)

        idx += 1
      end
    end
  end

  def generator_adv
    @generator_adv ||= Enumerator.new do |yielder|
      idx = 0

      loop do
        combination = "#{door_id}#{idx}"
        digest = Digest::MD5.hexdigest combination

        print '|' if idx % 100_000 == 0

        if has_zeroes(digest) && has_shift(digest)
          yielder << digest
        end

        idx += 1
      end
    end
  end

  def has_zeroes(digest)
    return false unless digest && digest.size > zeroes

    digest.each_char.take(zeroes).all? { |c| c == '0' }
  end

  def has_shift(digest)
    return false unless digest && digest.size > (zeroes + 1)

    (0..7).map(&:to_s).include? digest[zeroes]
  end
end

# ------ tests ------

class DecryptorTest < Minitest::Test
  def test_has_zeroes
    decr = Decryptor.new(nil, 3)

    assert !decr.has_zeroes('00')
    assert !decr.has_zeroes('')
    assert !decr.has_zeroes(nil)
    assert !decr.has_zeroes('01000')

    assert decr.has_zeroes('0000')
    assert decr.has_zeroes('0001')
  end

  def test_crack
    decr = Decryptor.new('abc')

    assert_equal decr.crack, '1'
    assert_equal decr.crack, '8'
  end

  def test_crack_adv
    decr = Decryptor.new('abc')

    assert_equal decr.crack_adv, [1, '5']
    assert_equal decr.crack_adv, [4, 'e']
  end

  def test_examples
    decr = Decryptor.new('abc')

    assert_equal decr.crack(8), '18f47a30'
  end

  def test_examples_adv
    decr = Decryptor.new('abc')

    assert_equal decr.crack_adv(8), '05ace8e3'
  end
end

# ------ main ------

door_id = ARGV[0] || 'abbhdwsy'

fail 'No door id / "test" provided' unless door_id

if door_id == 'test'
  Minitest.autorun

  exit(0)
end

decr = Decryptor.new(door_id.to_s)
puts "Code: #{decr.crack(8)}"
puts "Adv code: #{decr.crack_adv(8)}"

