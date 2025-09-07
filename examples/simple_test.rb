#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple test script to demonstrate the terminal form system
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'

puts '🎮 Terminal Form System Demo'
puts '=' * 40
puts

# Show terminal info
info = Unmagic::Terminal.identify
puts '📊 Terminal Information:'
puts "  Terminal: #{info[:term]}"
puts "  Detected as: #{info[:detected_as].split('::').last}"
puts "  Kitty ID: #{info[:kitty_window_id]}" if info[:kitty_window_id]
puts

# Test RadioGroup
puts '📻 Radio Group Demo:'
puts '-' * 20

radio = Unmagic::Terminal::Form::RadioGroup.new(
  options: %w[Red Blue Green],
  default: 'Blue',
  label: 'Pick your favorite color:'
) do |chosen|
  puts "\n✨ You chose: #{chosen}!"
end

result = radio.render

puts "\nFinal selection: #{result || '(cancelled)'}"
puts

# Test with autosubmit
puts '⚡ Autosubmit Radio Demo:'
puts '-' * 20

auto_radio = Unmagic::Terminal::Form::RadioGroup.new(
  options: %w[Slow Normal Fast Ludicrous],
  default: 'Normal',
  label: 'Select speed (changes immediately):',
  autosubmit: true
) do |speed|
  print "\r#{' ' * 40}\r" # Clear line
  print "Speed set to: #{speed}"
end

speed = auto_radio.render
puts "\n\nFinal speed: #{speed || '(cancelled)'}"

puts
puts '✅ Demo complete!'
