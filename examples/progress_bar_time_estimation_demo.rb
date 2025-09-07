#!/usr/bin/env ruby
# frozen_string_literal: true

# Progress Bar with Time Estimation Demo using Rate
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../../unmagic-support/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'

# Clear screen and hide cursor
print "\e[2J\e[H\e[?25l"

puts '🎯 Progress Bar with Time Estimation Demo'
puts '=' * 50
puts ''

def demo_progress_bar(title, total, delay, show_time: true)
  puts "#{title}:"

  progress_bar = Unmagic::Terminal::ProgressBar.new(
    total: total,
    width: 40,
    show_time: show_time
  )

  start_time = Time.now

  (1..total).each do |i|
    progress_bar.update(i)

    # Move cursor up and clear line to update in place
    print "\e[1A\e[2K" if i > 1
    puts "  #{progress_bar.render}"

    sleep(delay) unless i == total # Don't sleep on the last iteration
  end

  end_time = Time.now
  elapsed = (end_time - start_time).round(1)

  puts "  ✅ Completed in #{elapsed}s"
  puts ''
end

begin
  # Demo 1: Fast processing (high rate)
  demo_progress_bar('Fast Processing (50 items)', 50, 0.02)

  puts 'Press Enter to continue to the next demo...'
  gets

  # Demo 2: Medium processing (medium rate)
  demo_progress_bar('Medium Processing (30 items)', 30, 0.1)

  puts 'Press Enter to continue to the next demo...'
  gets

  # Demo 3: Slow processing (low rate)
  demo_progress_bar('Slow Processing (20 items)', 20, 0.25)

  puts 'Press Enter to continue to the next demo...'
  gets

  # Demo 4: Variable rate processing
  puts 'Variable Rate Processing (simulating real-world scenario):'

  progress_bar = Unmagic::Terminal::ProgressBar.new(total: 100, width: 50)

  (1..100).each do |i|
    progress_bar.update(i)

    # Move cursor up and clear line to update in place
    print "\e[1A\e[2K" if i > 1
    puts "  #{progress_bar.render}"

    # Variable delays to simulate real processing times
    case i
    when 1..10
      sleep(0.05)  # Fast startup
    when 11..30
      sleep(0.15)  # Slower middle section
    when 31..80
      sleep(0.08)  # Faster section
    when 81..95
      sleep(0.2)   # Slow near end
    else
      sleep(0.03)  # Quick finish
    end
  end

  puts '  ✅ Variable rate demo completed!'
  puts ''

  # Demo 5: Progress bar without time estimation
  puts 'Progress without time estimation:'
  demo_progress_bar('No Time Display', 25, 0.08, show_time: false)
rescue Interrupt
  # Handle Ctrl+C gracefully
ensure
  # Show cursor and clean up
  print "\e[?25h"
  puts 'Demo completed!'
end
