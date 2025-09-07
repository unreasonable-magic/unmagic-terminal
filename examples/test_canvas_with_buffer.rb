#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Canvas classes with refactored Buffer
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/canvas'
require 'stringio'

# Create a StringIO to capture output
output = StringIO.new

# Test 1: Simple region without border
puts 'Test 1: Simple region without border'
canvas = Unmagic::Terminal::Canvas.new(output: output)
canvas.define_region(:simple, x: 0, y: 0, width: 20, height: 3)
canvas.regions[:simple] = "Hello World\nThis is a test\nWith multiple lines"

# Start canvas in background, give it a moment to process, then stop
thread = canvas.start(async: true)
sleep 0.1
canvas.stop
thread.join

# Check output contains expected content
result = output.string
puts "Output contains 'Hello World': #{result.include?('Hello World')}"
puts "Output contains 'This is a test': #{result.include?('This is a test')}"
puts

# Reset for next test
output = StringIO.new

# Test 2: Region with border
puts 'Test 2: Region with border'
canvas = Unmagic::Terminal::Canvas.new(output: output)
canvas.define_region(:bordered, x: 0, y: 0, width: 20, height: 5, border: true)
canvas.regions[:bordered] = 'Bordered content'

# Start canvas in background, give it a moment to process, then stop
thread = canvas.start(async: true)
sleep 0.1
canvas.stop
thread.join

# Check output contains borders
result = output.string
puts "Output contains top border '┌': #{result.include?('┌')}"
puts "Output contains bottom border '└': #{result.include?('└')}"
puts "Output contains side border '│': #{result.include?('│')}"
puts

# Test 3: Region with emoji content
puts 'Test 3: Region with emoji content'
output = StringIO.new
canvas = Unmagic::Terminal::Canvas.new(output: output)
canvas.define_region(:emoji, x: 0, y: 0, width: 15, height: 2)
canvas.regions[:emoji] = "Hi 👋\nBye 👋"

# Start canvas in background, give it a moment to process, then stop
thread = canvas.start(async: true)
sleep 0.1
canvas.stop
thread.join

# Check output contains emoji
result = output.string
puts "Output contains emoji '👋': #{result.include?('👋')}"
puts

# Test 4: Region with truncation
puts 'Test 4: Region with truncation'
output = StringIO.new
canvas = Unmagic::Terminal::Canvas.new(output: output)
canvas.define_region(:truncate, x: 0, y: 0, width: 10, height: 2)
canvas.regions[:truncate] = 'This is a very long line that should be truncated'

# Start canvas in background, give it a moment to process, then stop
thread = canvas.start(async: true)
sleep 0.1
canvas.stop
thread.join

# Check the output length is constrained
result = output.string
lines = result.split("\n").reject(&:empty?)
puts "First line length <= 10: #{lines.first && lines.first.gsub(/\e\[[^m]*m/, '').length <= 10}"
puts

puts 'All tests completed!'
