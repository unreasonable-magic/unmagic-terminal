#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Buffer width calculation for emojis
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'
require 'unmagic/terminal/buffer'

# Test strings with various characters
test_strings = [
  'Hello World', # Plain ASCII
  '🚀 Rocket Ship',       # Emoji at start
  'Test 🎉 Party',        # Emoji in middle
  'Done ✅',              # Emoji at end
  '🔥💯👍', # Multiple emojis
  '日本語', # CJK characters
  'Hello 世界', # Mixed ASCII and CJK
  '→←↑↓' # Arrows
]

puts 'Buffer Width Testing'
puts '=' * 50
puts

# Calculate display widths
test_strings.each do |str|
  width = Unmagic::Terminal::Buffer.display_width(str)
  char_count = str.length

  puts "String: #{str.inspect}"
  puts "  Character count: #{char_count}"
  puts "  Display width:   #{width}"
  puts
end

# Test truncation
puts 'Truncation Testing'
puts '=' * 50
puts

test_strings.each do |str|
  truncated = Unmagic::Terminal::Buffer.truncate(str, 10)
  width = Unmagic::Terminal::Buffer.display_width(truncated)

  puts "Original: #{str.inspect}"
  puts "Truncated to 10: #{truncated.inspect} (width: #{width})"
  puts
end

# Test Buffer creation with multiline strings
puts 'Buffer Creation Testing'
puts '=' * 50
puts

test_content = "Hello 👋\nWorld 🌍\n日本語"
buffer = Unmagic::Terminal::Buffer.new(value: test_content)

puts 'Content:'
puts test_content
puts
puts "Buffer dimensions: #{buffer.width}x#{buffer.height}"
puts 'Buffer output:'
puts buffer
