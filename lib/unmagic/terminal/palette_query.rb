# frozen_string_literal: true

require "timeout"
require "unmagic-color"

module Unmagic
  module Terminal
    class PaletteQuery
      # Query terminal for background color using OSC 11 escape sequence
      # Works with Kitty, iTerm2, and other modern terminals that support this
      def self.detect
        new.detect
      end

      def detect
        return :dark unless tty?

        begin
          save_terminal_state
          response = query_terminal_background
          parse_background_color(response)
        rescue Timeout::Error, Interrupt, StandardError
          :dark # Default to dark on any error
        ensure
          restore_terminal_state
        end
      end

      # Get the actual RGB color if available
      def detect_rgb
        return nil unless tty?

        begin
          save_terminal_state
          response = query_terminal_background
          parse_rgb_color(response)
        rescue Timeout::Error, Interrupt, StandardError
          nil
        ensure
          restore_terminal_state
        end
      end

      private

      def tty?
        $stdin.tty? && $stdout.tty?
      end

      def save_terminal_state
        require "io/console"
        @old_state = begin
          `stty -g`.chomp
        rescue StandardError
          nil
        end
      end

      def restore_terminal_state
        system("stty #{@old_state}") if @old_state
      end

      def query_terminal_background
        # Use Kitty's native palette query approach for better compatibility
        if kitty_terminal?
          query_kitty_background
        else
          query_standard_background
        end
      end

      def kitty_terminal?
        !!(ENV["KITTY_WINDOW_ID"] || ENV["TERM_PROGRAM"]&.include?("kitty") || ENV["TERM"]&.include?("kitty"))
      end

      def query_kitty_background
        require "io/console"

        # Save current terminal state and set to raw mode
        old_tty = begin
          `stty -g`.chomp
        rescue StandardError
          nil
        end

        begin
          # Set terminal to raw mode BEFORE sending query
          system("stty raw -echo -icanon")

          # Send Kitty's OSC 21 palette query sequence
          $stdout.print "\033]21;background=?\007"
          $stdout.flush

          # Read response with timeout
          response = String.new
          Timeout.timeout(0.5) do
            while (char = $stdin.getc)
              response << char
              # Kitty OSC 21 response pattern: ESC ] 21 ; background=rgb:xxxx/yyyy/zzzz BEL
              # Look for the end of response (BEL character \007)
              break if char == "\007" || response.include?("\007")
              # Safety: stop if response gets too long
              break if response.length > 150
            end
          end

          response
        ensure
          # Always restore terminal state
          system("stty #{old_tty}") if old_tty

          # Clear any remaining input to avoid leaking into the console
          begin
            require "io/wait"
            # Read any remaining characters in the buffer
            $stdin.getc while $stdin.ready?
          rescue StandardError
            # Ignore - not all platforms support ready?
          end
          $stdout.flush
        end
      end

      def query_standard_background
        require "io/console"

        # Save current terminal state and set to raw mode
        old_tty = begin
          `stty -g`.chomp
        rescue StandardError
          nil
        end

        begin
          # Set terminal to raw mode BEFORE sending query
          system("stty raw -echo -icanon")

          # Send OSC 11 query sequence
          $stdout.print "\e]11;?\e\\"
          $stdout.flush

          # Read response with timeout
          response = String.new
          Timeout.timeout(0.5) do
            while (char = $stdin.getc)
              response << char
              # OSC response pattern: ESC ] 11 ; rgb:xxxx/yyyy/zzzz ESC \ or BEL
              # Check if we have a complete response
              if response =~ %r{\]11;rgb:[0-9a-f]+/[0-9a-f]+/[0-9a-f]+}i
                # Read a bit more to consume the terminator
                begin
                  Timeout.timeout(0.1) do
                    while (term_char = $stdin.getc)
                      response << term_char
                      break if [ "\\", "\a" ].include?(term_char)
                      break if response.length > 150
                    end
                  end
                rescue Timeout::Error
                  # That's fine, we have what we need
                end
                break
              end
              # Safety: stop if response gets too long
              break if response.length > 100
            end
          end

          response
        ensure
          # Always restore terminal state
          system("stty #{old_tty}") if old_tty

          # Clear any remaining input to avoid leaking into the console
          begin
            require "io/wait"
            # Read any remaining characters in the buffer
            $stdin.getc while $stdin.ready?
          rescue StandardError
            # Ignore - not all platforms support ready?
          end
          $stdout.flush
        end
      end

      def parse_background_color(response)
        rgb_color = parse_rgb_color(response)
        return :dark unless rgb_color

        # Use the rgb gem to convert to HSL and check lightness
        hsl = rgb_color.to_hsl

        # If lightness > 0.5 (50%), it's a light background
        hsl[2] > 0.5 ? :light : :dark
      end

      def parse_rgb_color(response)
        # Handle both Kitty OSC 21 and standard OSC 11 response formats
        # Kitty OSC 21 format: \033]21;background=rgb:RRRR/GGGG/BBBB\007
        # Standard OSC 11 format: \e]11;rgb:RRRR/GGGG/BBBB\e\\

        # Look for rgb: pattern in either format
        return unless response =~ %r{(?:background=)?rgb:([0-9a-f]+)/([0-9a-f]+)/([0-9a-f]+)}i

        # Convert from 16-bit to 8-bit values (0-255 range)
        # Kitty returns 4-digit hex values (0000-ffff), need to scale to 8-bit (00-ff)
        r = (::Regexp.last_match(1).to_i(16) / 256.0).round
        g = (::Regexp.last_match(2).to_i(16) / 256.0).round
        b = (::Regexp.last_match(3).to_i(16) / 256.0).round

        Unmagic::Color::RGB.new(red: r, green: g, blue: b)
      end

      # Cache the detected background color for the session
      def self.cached
        @cached ||= detect
      end

      # Cache the actual RGB color
      def self.cached_rgb
        @cached_rgb || new.detect_rgb
      end

      # Allow manual override
      def self.set(color)
        @cached = color
      end

      def self.set_rgb(rgb_color)
        @cached_rgb = rgb_color
        @cached = rgb_color && rgb_color.to_hsl[2] > 0.5 ? :light : :dark
      end

      # Check if terminal supports background detection
      def self.supported?
        tty_check = $stdin.tty? && $stdout.tty?

        if ENV["DEBUG_CONSOLE"]
          puts "PaletteQuery.supported? debug:"
          puts "  $stdin.tty? = #{$stdin.tty?}"
          puts "  $stdout.tty? = #{$stdout.tty?}"
          puts "  tty_check = #{tty_check}"
        end

        return false unless tty_check

        # Check for known terminal emulators that support OSC 11
        term = ENV["TERM_PROGRAM"] || ENV["TERM"] || ""
        kitty = ENV["KITTY_WINDOW_ID"]

        !kitty.nil? ||
          term.include?("kitty") ||
          term.include?("iTerm") ||
          term.include?("alacritty") ||
          term.include?("wezterm")
      end

      # Get palette info for debugging
      def self.info
        rgb = cached_rgb
        {
          detected: cached,
          rgb: rgb&.to_hex,
          hsl: if rgb
                 {
                   h: rgb.to_hsl.hue.round,
                   s: rgb.to_hsl.saturation.round,
                   l: rgb.to_hsl.lightness.round
                 }
               end,
          supported: supported?,
          term: ENV["TERM"],
          term_program: ENV["TERM_PROGRAM"],
          kitty: !ENV["KITTY_WINDOW_ID"].nil?
        }
      end

      # Get a contrasting color for the detected background
      def self.contrast_color
        rgb = cached_rgb
        return nil unless rgb

        rgb.contrast_color
      end

      # Generate a color that's visible on the detected background
      def self.adjust_color_for_background(color)
        background = cached_rgb
        return color unless background

        # Parse the color if it's a string
        color = Unmagic::Color.parse(color) if color.is_a?(String)
        return color unless color

        color.adjust_for_contrast(background)
      end

      # Get a slightly darker version of the background color
      # Useful for creating subtle UI variations like borders or hover states
      def self.darker_background(amount = 0.15)
        rgb = cached_rgb
        return nil unless rgb

        hsl = rgb.to_hsl # Returns [hue (0-360), saturation (0-1), lightness (0-1)]
        new_lightness = [ hsl[2] - amount, 0 ].max
        # Convert back to RGB using Color module's hsl_to_rgb method
        rgb_array = Unmagic::Color.send(:hsl_to_rgb, hsl[0] / 360.0, hsl[1], new_lightness)
        Unmagic::Color::RGB.new(red: (rgb_array[0] * 255).round, green: (rgb_array[1] * 255).round,
                                blue: (rgb_array[2] * 255).round)
      end

      # Get a slightly lighter version of the background color
      # Useful for creating subtle UI variations like highlights or panels
      def self.lighter_background(amount = 0.15)
        rgb = cached_rgb
        return nil unless rgb

        hsl = rgb.to_hsl # Returns [hue (0-360), saturation (0-1), lightness (0-1)]
        new_lightness = [ hsl[2] + amount, 1.0 ].min
        # Convert back to RGB using Color module's hsl_to_rgb method
        rgb_array = Unmagic::Color.send(:hsl_to_rgb, hsl[0] / 360.0, hsl[1], new_lightness)
        Unmagic::Color::RGB.new(red: (rgb_array[0] * 255).round, green: (rgb_array[1] * 255).round,
                                blue: (rgb_array[2] * 255).round)
      end

      # Get a background variant that's slightly adjusted in the appropriate direction
      # For dark backgrounds, returns a lighter version
      # For light backgrounds, returns a darker version
      def self.subtle_background_variant(amount = 0.10)
        return nil unless cached_rgb

        if cached == :dark
          lighter_background(amount)
        else
          darker_background(amount)
        end
      end
    end
  end
end
