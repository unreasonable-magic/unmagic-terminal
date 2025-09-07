#!/usr/bin/env ruby
# frozen_string_literal: true

# Test the simplified Buffer class with merge functionality
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/buffer'

puts 'Buffer Merge Tests'
puts '=' * 50
puts

# Test 1: Merge below (default)
puts 'Test 1: Merge below (<<)'
b1 = Unmagic::Terminal::Buffer.new(value: "AAA\nBBB")
b2 = Unmagic::Terminal::Buffer.new(value: "CCC\nDDD")
result = b1 << b2
puts 'b1:'
puts b1
puts "\nb2:"
puts b2
puts "\nResult (b1 << b2):"
puts result
puts "\n---\n\n"

# Test 2: Merge above
puts 'Test 2: Merge above'
result = b1.merge(b2, at: :above)
puts 'Result (b1.merge(b2, at: :above)):'
puts result
puts "\n---\n\n"

# Test 3: Merge right
puts 'Test 3: Merge right'
result = b1.merge(b2, at: :right)
puts 'Result (b1.merge(b2, at: :right)):'
puts result
puts "\n---\n\n"

# Test 4: Merge left
puts 'Test 4: Merge left'
result = b1.merge(b2, at: :left)
puts 'Result (b1.merge(b2, at: :left)):'
puts result
puts "\n---\n\n"

# Test 5: Merge at position
puts 'Test 5: Merge at position [1, 1]'
result = b1.merge(b2, at: [ 1, 1 ])
puts 'Result (b1.merge(b2, at: [1, 1])):'
puts result
puts "\n---\n\n"

# Test 6: Chain merging
puts 'Test 6: Chain merging'
header = Unmagic::Terminal::Buffer.new(value: '=== HEADER ===', width: 20)
content = Unmagic::Terminal::Buffer.new(value: 'Some content here')
footer = Unmagic::Terminal::Buffer.new(value: '=== FOOTER ===', width: 20)
page = header << content << footer
puts 'Header + Content + Footer:'
puts page
puts "\n---\n\n"

# Test 7: Building a box
puts 'Test 7: Building a box layout'
top = Unmagic::Terminal::Buffer.new(value: '┌────────┐')
middle = Unmagic::Terminal::Buffer.new(value: "│ Hello  │\n│ World  │")
bottom = Unmagic::Terminal::Buffer.new(value: '└────────┘')
box = top << middle << bottom
puts 'Box:'
puts box
puts "\n---\n\n"

# Test 8: Horizontal layout with different heights
puts 'Test 8: Horizontal layout with different heights'
left_col = Unmagic::Terminal::Buffer.new(value: "L1\nL2\nL3")
right_col = Unmagic::Terminal::Buffer.new(value: "R1\nR2")
layout = left_col.merge(right_col, at: :right)
puts 'Left column (3 lines) + Right column (2 lines):'
puts layout
puts "\n---\n\n"

# Test 9: Emoji handling in merge
puts 'Test 9: Emoji handling in merge'
emoji1 = Unmagic::Terminal::Buffer.new(value: 'Hi 👋')
emoji2 = Unmagic::Terminal::Buffer.new(value: 'Bye 👋')
result = emoji1.merge(emoji2, at: :below)
puts 'Emoji merge:'
puts result
puts "\n---\n\n"

# Test 10: Fixed dimensions with merge
puts 'Test 10: Fixed dimensions with merge'
fixed1 = Unmagic::Terminal::Buffer.new(value: 'A', width: 5, height: 2)
fixed2 = Unmagic::Terminal::Buffer.new(value: 'B', width: 5, height: 2)
result = fixed1.merge(fixed2, at: :right)
puts 'Fixed size buffers side by side:'
puts(result.to_s.lines.map { |line| "|#{line.chomp}|" })
puts

puts 'All tests completed!'
