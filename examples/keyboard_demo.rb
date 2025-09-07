#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'unmagic-terminal'

# Demonstrate keyboard input capabilities
terminal = Unmagic::Terminal.current

puts 'Terminal Detection:'
puts '==================='
Unmagic::Terminal.identify.each do |key, value|
  puts "#{key}: #{value}"
end
puts

puts 'Keyboard Input Demo'
puts '==================='
puts "Your terminal: #{terminal.class.name.split('::').last}"
puts "Enhanced keyboard support: #{terminal.supports_enhanced_keyboard? ? 'Yes' : 'No'}"
puts

# Enable enhanced keyboard if available
if terminal.supports_enhanced_keyboard? && terminal.is_a?(Unmagic::Terminal::Emulator::Kitty::Kitty)
  puts 'Enabling Kitty enhanced keyboard protocol...'
  terminal.keyboard.enable_enhanced_mode
  puts 'Enhanced mode enabled!'
  puts
end

puts 'Press keys to see events (Ctrl+C or ESC to exit):'
puts '-------------------------------------------'

# Open a log file for debugging
log_file = File.open('keyboard_debug.log', 'w')
log_file.puts '=== Keyboard Debug Log ==='
log_file.puts "Terminal: #{terminal.class.name}"
log_file.puts "Enhanced keyboard: #{terminal.supports_enhanced_keyboard?}"
log_file.puts "Starting at: #{Time.now}"
log_file.puts '=' * 40
log_file.flush

begin
  terminal.raw_mode do
    terminal.hide_cursor

    loop do
      event = terminal.keyboard.read_event(timeout: 0.1)

      next unless event

      # Log raw data
      log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Raw bytes: #{event.raw.inspect} (#{event.raw.bytes.map do |b|
        '0x%02X' % b
      end.join(' ')})"
      log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Event class: #{event.class}"
      log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Key: #{event.key.inspect}"
      log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Modifiers: #{event.modifiers.inspect}"

      # Log Kitty-specific data if available
      if event.respond_to?(:unicode_codepoint)
        log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Unicode: #{event.unicode_codepoint}"
        if event.respond_to?(:event_type)
          log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] Event type: #{event.event_type}"
        end
      end
      log_file.puts '-' * 40
      log_file.flush

      # Clear the line and display event info
      terminal.clear_line
      terminal.output.write "\r"

      case event
      when Unmagic::Terminal::Emulator::Kitty::KeyDownEvent
        info = "Kitty KeyDown: key=#{event.key.inspect}"
        info += " mods=#{event.modifiers.inspect}" unless event.modifiers.empty?
        info += " unicode=#{event.unicode_codepoint}" if event.unicode_codepoint
        info += ' (repeat)' if event.repeat?
        terminal.output.write info
      when Unmagic::Terminal::Emulator::Kitty::KeyUpEvent
        info = "Kitty KeyUp: key=#{event.key.inspect}"
        info += " mods=#{event.modifiers.inspect}" unless event.modifiers.empty?
        info += " unicode=#{event.unicode_codepoint}" if event.unicode_codepoint
        terminal.output.write info
      when Unmagic::Terminal::Emulator::Generic::KeyDownEvent
        info = "KeyDown: key=#{event.key.inspect}"
        info += " mods=#{event.modifiers.inspect}" unless event.modifiers.empty?
        info += " raw=#{event.raw.bytes.map { |b| '0x%02X' % b }.join(' ')}"
        terminal.output.write info
      else
        terminal.output.write "Unknown event: #{event.class}"
      end

      terminal.output.flush

      # Check multiple ways to exit
      should_exit = false

      # Check for Ctrl+C (0x03)
      if event.key == :ctrl_c ||
         (event.key == 'c' && event.ctrl?) ||
         (event.raw && event.raw.bytes == [ 3 ])
        log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] CTRL+C detected - exiting"
        log_file.flush
        should_exit = true
      end

      # Check for ESC (0x1B)
      if event.key == :escape ||
         (event.raw && event.raw.bytes.first == 27 && event.raw.bytes.length == 1)
        log_file.puts "[#{Time.now.strftime('%H:%M:%S.%L')}] ESC detected - exiting"
        log_file.flush
        should_exit = true
      end

      break if should_exit
    end
  ensure
    terminal.show_cursor
    log_file.puts "=== Session ended at #{Time.now} ==="
    log_file.close
  end
rescue Interrupt
  # Clean exit
ensure
  terminal.keyboard.disable_enhanced_mode if terminal.keyboard.respond_to?(:disable_enhanced_mode)
  puts
  puts
  puts 'Goodbye!'
end
