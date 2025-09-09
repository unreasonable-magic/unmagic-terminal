#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to load path
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../../unmagic-support/lib', __dir__))

require 'unmagic-terminal'

# Demo script showing Unmagic::Terminal::Button capabilities
def main
  puts '=== Unmagic::Terminal::Button Demo ==='
  puts

  # Basic button without styling
  puts '1. Basic button:'
  basic_button = Unmagic::Terminal::Button.new(text: "Click Me")
  puts basic_button.render
  puts

  # Button with background color
  puts '2. Button with blue background:'
  bg_button = Unmagic::Terminal::Button.new(
    text: "Blue Button",
    background: Unmagic::Terminal::Style::Background.new(color: :blue)
  )
  puts bg_button.render
  puts

  # Button with border
  puts '3. Button with rounded border:'
  border_button = Unmagic::Terminal::Button.new(
    text: "Bordered",
    border: Unmagic::Terminal::Style::Border.new(style: :rounded)
  )
  puts border_button.render
  puts

  # Button with text styling
  puts '4. Button with bold white text:'
  text_button = Unmagic::Terminal::Button.new(
    text: "Bold Text",
    text_style: Unmagic::Terminal::Style::Text.new(color: :white, style: :bold),
    background: Unmagic::Terminal::Style::Background.new(color: :green)
  )
  puts text_button.render
  puts

  # Fully styled button
  puts '5. Fully styled button:'
  styled_button = Unmagic::Terminal::Button.new(
    text: "Fancy Button",
    background: Unmagic::Terminal::Style::Background.new(color: :magenta),
    border: Unmagic::Terminal::Style::Border.new(style: :double, color: :cyan),
    text_style: Unmagic::Terminal::Style::Text.new(color: :white, style: :bold)
  )
  puts styled_button.render
  puts

  # Button with callback
  puts '6. Button with interaction callback:'
  callback_button = Unmagic::Terminal::Button.new(
    text: "Interactive",
    background: Unmagic::Terminal::Style::Background.new(color: :yellow),
    text_style: Unmagic::Terminal::Style::Text.new(color: :black, style: :bold)
  ) do |state|
    puts "  → Button was interacted with in '#{state}' state!"
  end
  
  puts "Before interaction:"
  puts callback_button.render
  puts "Triggering interaction..."
  callback_button.interact(:pressed)
  puts

  # Different states
  puts '7. Button in different states:'
  state_button = Unmagic::Terminal::Button.new(
    text: "State Button",
    border: Unmagic::Terminal::Style::Border.new(style: :single),
    background: Unmagic::Terminal::Style::Background.new(color: :blue),
    text_style: Unmagic::Terminal::Style::Text.new(color: :white)
  ) do |state|
    puts "  → Current state: #{state}"
  end

  %i[default hover focus pressed].each do |state|
    state_button.set_state(state)
    puts "#{state.to_s.capitalize} state:"
    puts state_button.render
    state_button.interact
    puts
  end

  # Pattern background
  puts '8. Button with pattern background:'
  pattern_button = Unmagic::Terminal::Button.new(
    text: "Pattern Button",
    background: Unmagic::Terminal::Style::Background.new(pattern: :dots),
    border: Unmagic::Terminal::Style::Border.new(style: :ascii)
  )
  puts pattern_button.render
  puts

  puts '=== Demo Complete ==='
end

main if __FILE__ == $PROGRAM_NAME