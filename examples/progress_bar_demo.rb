#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to load path
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../../unmagic-support/lib', __dir__))

require 'unmagic-terminal'

# Demo script showing Unmagic::Terminal::ProgressBar capabilities
def main
  puts '=== Unmagic::Terminal::ProgressBar Demo ==='
  puts

  # Basic progress bar demo
  puts '1. Basic progress bar:'
  pb1 = Unmagic::Terminal::ProgressBar.new(total: 100, description: 'Processing files')
  pb1.update(65)
  puts "#{pb1.description}: #{pb1.render}"
  puts

  # Different total values
  puts '2. Different total values:'
  pb2 = Unmagic::Terminal::ProgressBar.new(total: 50, description: 'Smaller task')
  pb2.update(30)
  puts "#{pb2.description}: #{pb2.render}"
  puts

  # Different widths
  puts '3. Different widths:'

  puts 'Narrow (20 chars):'
  pb_narrow = Unmagic::Terminal::ProgressBar.new(total: 100, width: 20)
  pb_narrow.update(40)
  puts pb_narrow.render

  puts 'Wide (60 chars):'
  pb_wide = Unmagic::Terminal::ProgressBar.new(total: 100, width: 60)
  pb_wide.update(40)
  puts pb_wide.render
  puts

  # Animated progress demo
  puts '4. Simulated progress animation:'
  pb_animated = Unmagic::Terminal::ProgressBar.new(
    total: 100,
    description: 'Installing packages'
  )

  puts "#{pb_animated.description}..."
  # Simulate progress over time
  (0..100).step(5) do |i|
    pb_animated.update(i)
    print "\e[2K\r" # Clear line and return to start
    print pb_animated.render
    sleep(0.1)
  end
  print "\n\n"

  # Without time estimation
  puts '5. Without time estimation:'
  pb_no_time = Unmagic::Terminal::ProgressBar.new(total: 100, show_time: false)
  pb_no_time.update(75)
  puts pb_no_time.render
  puts

  # Complete progress bar
  puts '6. Complete progress bar:'
  pb_complete = Unmagic::Terminal::ProgressBar.new(total: 100, description: 'Task completed')
  pb_complete.update(100)
  puts "#{pb_complete.description}: #{pb_complete.render}"
  puts

  # Empty progress bar
  puts '7. Empty progress bar:'
  pb_empty = Unmagic::Terminal::ProgressBar.new(total: 100, description: 'Waiting to start')
  puts "#{pb_empty.description}: #{pb_empty.render}"
  puts

  # Using increment method
  puts '8. Using increment method:'
  pb_increment = Unmagic::Terminal::ProgressBar.new(total: 10, description: 'Step by step')
  5.times { pb_increment.increment }
  puts "#{pb_increment.description}: #{pb_increment.render}"
  puts

  puts '=== Demo Complete ==='
end

main if __FILE__ == $PROGRAM_NAME
