#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test to verify Buffer class works
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/buffer'

# Test 1: Basic string
puts 'Test 1: Basic string'
buffer = Unmagic::Terminal::Buffer.new(value: "foo\nbar")
puts "Input: 'foo\\nbar'"
puts "Width: #{buffer.width} (expected: 3)"
puts "Height: #{buffer.height} (expected: 2)"
puts "Output:\n#{buffer}"
puts

# Test 2: String with emoji
puts 'Test 2: String with emoji'
buffer = Unmagic::Terminal::Buffer.new(value: 'Hi 👋')
puts "Input: 'Hi 👋'"
puts "Width: #{buffer.width} (expected: 5)"
puts "Height: #{buffer.height} (expected: 1)"
puts "Output: #{buffer}"
puts

# Test 3: CJK characters
puts 'Test 3: CJK characters'
buffer = Unmagic::Terminal::Buffer.new(value: '日本語')
puts "Input: '日本語'"
puts "Width: #{buffer.width} (expected: 6)"
puts "Height: #{buffer.height} (expected: 1)"
puts "Output: #{buffer}"
puts

# Test 4: Mixed content
puts 'Test 4: Mixed content'
buffer = Unmagic::Terminal::Buffer.new(value: "Hello 👋\nWorld 🌍\n日本語")
puts "Input: 'Hello 👋\\nWorld 🌍\\n日本語'"
puts "Width: #{buffer.width} (expected: 8)"
puts "Height: #{buffer.height} (expected: 3)"
puts "Output:\n#{buffer}"
puts

# Test 5: Write method
puts 'Test 5: Write method'
buffer = Unmagic::Terminal::Buffer.new(value: "     \n     \n     ")
buffer.write(0, 0, 'Hi')
buffer.write(1, 1, '👋')
puts "After writing 'Hi' at (0,0) and '👋' at (1,1):"
puts buffer
puts

puts 'All tests completed!'
