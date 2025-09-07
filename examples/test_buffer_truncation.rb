#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Buffer truncation/padding with width and height parameters
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/buffer'

puts 'Buffer Truncation/Padding Tests'
puts '=' * 50
puts

# Test 1: Fixed width and height (truncation)
puts 'Test 1: Fixed width=8, height=2 (truncates long content)'
buffer = Unmagic::Terminal::Buffer.new(
  value: "Hello World\nThis is a long line\nThird line",
  width: 8,
  height: 2
)
puts "Input: 'Hello World\\nThis is a long line\\nThird line'"
puts "Width: #{buffer.width}"
puts "Height: #{buffer.height}"
puts 'Output:'
puts buffer
puts '---'
puts

# Test 2: Fixed width and height (padding)
puts 'Test 2: Fixed width=10, height=3 (pads short content)'
buffer = Unmagic::Terminal::Buffer.new(
  value: "Hi\nOk",
  width: 10,
  height: 3
)
puts "Input: 'Hi\\nOk'"
puts "Width: #{buffer.width}"
puts "Height: #{buffer.height}"
puts 'Output (| marks boundaries):'
puts(buffer.to_s.lines.map { |line| "|#{line.chomp}|" })
puts

# Test 3: Emoji truncation
puts 'Test 3: Emoji truncation (width=5)'
buffer = Unmagic::Terminal::Buffer.new(
  value: 'Hi 👋 Test',
  width: 5,
  height: 1
)
puts "Input: 'Hi 👋 Test'"
puts "Width: #{buffer.width}"
puts "Height: #{buffer.height}"
puts "Output: '#{buffer}'"
puts

# Test 4: CJK truncation
puts 'Test 4: CJK truncation (width=4)'
buffer = Unmagic::Terminal::Buffer.new(
  value: '日本語です',
  width: 4,
  height: 1
)
puts "Input: '日本語です'"
puts "Width: #{buffer.width}"
puts "Height: #{buffer.height}"
puts "Output: '#{buffer}'"
puts

# Test 5: Width only (height auto-calculated)
puts 'Test 5: Width only=6 (height auto)'
buffer = Unmagic::Terminal::Buffer.new(
  value: "Hello World\nTest Line\nAnother",
  width: 6
)
puts "Input: 'Hello World\\nTest Line\\nAnother'"
puts "Width: #{buffer.width}"
puts "Height: #{buffer.height} (auto-calculated)"
puts 'Output:'
puts buffer
puts

# Test 6: Height only (width auto-calculated)
puts 'Test 6: Height only=2 (width auto)'
buffer = Unmagic::Terminal::Buffer.new(
  value: "Hello World\nTest\nThird\nFourth",
  height: 2
)
puts "Input: 'Hello World\\nTest\\nThird\\nFourth'"
puts "Width: #{buffer.width} (auto-calculated)"
puts "Height: #{buffer.height}"
puts 'Output:'
puts buffer
puts

# Test 7: No dimensions (auto both)
puts 'Test 7: No dimensions (both auto)'
buffer = Unmagic::Terminal::Buffer.new(
  value: "Auto\nSize"
)
puts "Input: 'Auto\\nSize'"
puts "Width: #{buffer.width} (auto)"
puts "Height: #{buffer.height} (auto)"
puts 'Output:'
puts buffer
puts

puts 'All tests completed!'
