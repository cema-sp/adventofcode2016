#!/usr/bin/env ruby

require 'minitest'

class IPv7
  IP_DELIMS = /[\[\]]/
  ABBA_PARSER = /[[:alpha:]]*?([[:alpha:]])(?!\1)([[:alpha:]])(\2)(\1)[[:alpha:]]*/
  BAB_PARSER = /.*?([[:alpha:]])(?!\1)([[:alpha:]])(\1).*--.*?(\2\1\2).*/

  attr_reader :parts
  attr_reader :hypernets

  def initialize(str)
    @parts, @hypernets =
      str.split(IP_DELIMS).partition.with_index { |_, idx| idx.even? }
  end

  def tls?
    hypernets.none? { |h| abba? h } && parts.any? { |p| abba? p }
  end

  def ssl?
    str = "#{parts.join('-')}--#{hypernets.join('-')}"
    (BAB_PARSER =~ str) != nil
  end

  def abba?(str)
    (ABBA_PARSER =~ str) != nil
  end

  def bab?
    false
  end
end

# ------ tests ------

class IPv7Test < Minitest::Test
  def test_initialize
    str = 'abb[mnop]qrstff[lggd]ffs'
    ip = IPv7.new(str)

    assert_equal ip.parts.count, 3
    assert_equal ip.hypernets.count, 2

    assert_equal ip.parts[0], 'abb'
    assert_equal ip.parts[1], 'qrstff'
    assert_equal ip.parts[2], 'ffs'

    assert_equal ip.hypernets[0], 'mnop'
    assert_equal ip.hypernets[1], 'lggd'
  end

  def test_abba?
    ip = IPv7.new('')

    assert ip.abba?('abbay')
    assert !ip.abba?('mnop')
    assert ip.abba?('ioxxoj')
  end

  def test_tls?
    assert IPv7.new('abba[mnop]qrst').tls?
    assert !IPv7.new('abcd[bddb]xyyx').tls?
    assert !IPv7.new('aaaa[qwer]tyui').tls?
    assert IPv7.new('ioxxoj[asdfgh]zxcvbn').tls?
  end

  def test_ssl?
    assert IPv7.new('aba[bab]xyz').ssl?
    assert !IPv7.new('xyx[xyx]xyx').ssl?
    assert IPv7.new('aaa[kek]eke').ssl?
    assert IPv7.new('zazbz[bzb]cdb').ssl?
  end
end

# ------ main ------

file_name = ARGV[0]

fail 'No file name / "test" provided' unless file_name

if file_name == 'test'
  Minitest.autorun

  exit(0)
end

ips = File.open(file_name).readlines.map do |line|
  IPv7.new line.strip!
end

ips_tls = ips.select { |ip| ip.tls? }
ips_ssl = ips.select { |ip| ip.ssl? }

puts "IPs with TLS: #{ips_tls.count}"
puts "IPs with SSL: #{ips_ssl.count}"

