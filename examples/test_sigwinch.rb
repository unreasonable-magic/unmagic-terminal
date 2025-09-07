#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test to verify SIGWINCH signal handling
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/emulator/generic'

puts 'SIGWINCH Test - Resize your terminal window!'
puts '=' * 50
puts

# Create emulator
emulator = Unmagic::Terminal::Emulator::Generic::Generic.new

# Initial size
puts "Initial terminal size: #{emulator.width}x#{emulator.height}"
puts

# Track resize events
resize_count = 0

# Set up resize handler
emulator.on_resize do |event|
  resize_count += 1
  puts "Resize event ##{resize_count}: #{event}"
  puts "  New size: #{event.width}x#{event.height}"
  puts "  Changed: #{event.changed?}"
  puts
end

# Enable resize events
emulator.enable_resize_events

puts 'Resize detection enabled!'
puts 'Resize your terminal window to trigger events.'
puts 'Press Ctrl+C to exit.'
puts

# Keep the script running to catch resize events
begin
  loop do
    sleep 0.1
    # Also manually check for resize as backup
    emulator.check_resize
  end
rescue Interrupt
  puts "\nExiting..."
ensure
  emulator.disable_resize_events
  puts "Total resize events detected: #{resize_count}"
end
