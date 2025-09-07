#!/usr/bin/env ruby
# frozen_string_literal: true

# Add vendor gems to load path
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'unmagic-terminal'

# Demonstrate RadioGroup form component
puts 'RadioGroup Demo'
puts '==============='
puts

# Simple selection
puts '1. Basic Radio Group:'
puts '---------------------'

radio = Unmagic::Terminal::Form::RadioGroup.new(
  options: [ 'Small', 'Medium', 'Large', 'Extra Large' ],
  default: 'Medium',
  label: 'Select size:'
) do |choice|
  puts "\n✓ You selected: #{choice}"
end

result = radio.render
puts "Final result: #{result.inspect}"
puts

# Theme selector with autosubmit
puts '2. Theme Selector (with autosubmit):'
puts '------------------------------------'

current_theme = 'Auto'
theme_radio = Unmagic::Terminal::Form::RadioGroup.new(
  options: [ 'Light', 'Dark', 'Auto', 'High Contrast' ],
  default: current_theme,
  label: 'Choose your theme:',
  autosubmit: true
) do |theme|
  # This gets called immediately when selection changes
  puts "\r#{' ' * 50}\r" # Clear line
  puts "Theme changed to: #{theme}"
  current_theme = theme
end

selected_theme = theme_radio.render
puts "Final theme: #{selected_theme || 'Cancelled'}"
puts

# Color picker
puts '3. Favorite Color:'
puts '------------------'

colors = %w[Red Blue Green Yellow Purple Orange Pink Black White]
color_radio = Unmagic::Terminal::Form::RadioGroup.new(
  options: colors,
  label: "What's your favorite color?"
) do |color|
  # Use ANSI colors to show the selection
  color_code = case color.downcase
  when 'red' then :red
  when 'blue' then :blue
  when 'green' then :green
  when 'yellow' then :yellow
  when 'purple' then :magenta
  when 'orange' then :yellow
  when 'pink' then :bright_magenta
  when 'black' then :black
  when 'white' then :white
  else :white
  end

  puts
  puts Unmagic::Terminal::ANSI.text("You chose #{color}!", color: color_code, style: :bold)
end

favorite_color = color_radio.render
puts "Your favorite: #{favorite_color || 'No selection'}"
puts

# Survey with multiple questions
puts '4. Quick Survey:'
puts '----------------'

answers = {}

# Question 1
radio1 = Unmagic::Terminal::Form::RadioGroup.new(
  options: [ 'Strongly Agree', 'Agree', 'Neutral', 'Disagree', 'Strongly Disagree' ],
  label: 'This demo is helpful:'
) do |answer|
  answers[:helpful] = answer
end
radio1.render

# Question 2
radio2 = Unmagic::Terminal::Form::RadioGroup.new(
  options: [ 'Very Easy', 'Easy', 'Moderate', 'Difficult', 'Very Difficult' ],
  label: 'How easy was it to use?'
) do |answer|
  answers[:ease] = answer
end
radio2.render

# Question 3
radio3 = Unmagic::Terminal::Form::RadioGroup.new(
  options: [ 'Definitely', 'Probably', 'Maybe', 'Probably Not', 'Definitely Not' ],
  label: 'Would you use this in your project?'
) do |answer|
  answers[:would_use] = answer
end
radio3.render

puts
puts 'Survey Results:'
puts '---------------'
answers.each do |key, value|
  puts "#{key}: #{value}"
end

puts
puts 'Demo complete!'
