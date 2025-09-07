# frozen_string_literal: true

require_relative "terminal/ansi"
require_relative "terminal/palette_query"
require_relative "terminal/emulator"
require_relative "terminal/emulator/generic"
require_relative "terminal/emulator/kitty"
require_relative "terminal/canvas"
require_relative "terminal/progress_bar"
require_relative "terminal/ascii/duck"
require_relative "terminal/ascii/table"
require_relative "terminal/ascii/banner"
require_relative "terminal/ascii/line_merger"
require_relative "terminal/ascii/box"
require_relative "terminal/ascii/layout"

module Unmagic
  module Terminal
    #     _    ____   ____ ___ ___
    #    / \  / ___| / ___|_ _|_ _|
    #   / _ \ \___ \| |    | | | |
    #  / ___ \ ___) | |___ | | | |
    # /_/   \_\____/ \____|___|___|
    #
    # The ASCII module provides comprehensive ASCII art generation and formatting.
    # This is a core utility module used throughout the application for creating
    # rich terminal user interfaces with ASCII art, tables, banners, and more.
    #
    # ## Features
    #
    # - **ASCII Art Generation**: Create decorative text headers and banners
    # - **Table Formatting**: Build formatted tables for data display
    # - **Banner Creation**: Generate stylized banners with borders
    # - **Art Merging**: Combine multiple ASCII art pieces side by side
    # - **Colorization**: Apply colors to ASCII art using the Color module
    #
    # ## Components
    #
    # - `Unmagic::Terminal::ASCII::Duck` - The iconic duck ASCII art
    # - `Unmagic::Terminal::ASCII::Table` - Table generation and formatting
    # - `Unmagic::Terminal::ASCII::Banner` - Banner and header creation
    # - `Unmagic::Terminal::ASCII::LineMerger` - Utilities for merging ASCII art
    # - `Unmagic::Terminal::ASCII::Layout` - Multi-column layout management
    #
    # ## Examples
    #
    #   # Get the duck art
    #   puts Unmagic::Terminal::ASCII.duck
    #
    #   # Create a banner
    #   banner = Unmagic::Terminal::ASCII::Banner.new("Welcome")
    #   puts banner.render
    #
    #   # Merge two ASCII arts
    #   merged = Unmagic::Terminal::ASCII.merge(art1, art2, spacing: 3)
    #
    #   # Colorize merged art
    #   colored = Unmagic::Terminal::ASCII.colorize_merged(
    #     left_art,
    #     right_art,
    #     left_color: :yellow,
    #     right_colors: [:blue, :green]
    #   )
    #
    # ## Integration with Color Module
    #
    # The ASCII module works seamlessly with the Color module to create
    # colorful terminal displays. ASCII art can be enhanced with gradients,
    # time-based colors, and semantic coloring.
    #
    # @see Unmagic::Color For color formatting capabilities
    #
    module ASCII
      # Maintain backward compatibility
      def self.duck
        Duck.art
      end

      class << self
        # Merge two ASCII arts side by side
        # Delegates to LineMerger for the actual implementation
        def merge(left_art, right_art, spacing: 2, left_offset: 0)
          merger = LineMerger.new
          merger.merge(left_art, right_art, spacing: spacing, left_offset: left_offset)
        end

        # Apply colors to merged ASCII art
        # Delegates to LineMerger for the actual implementation
        def colorize_merged(left_art, right_art, left_color: nil, right_colors: nil, spacing: 2, left_offset: 0)
          merger = LineMerger.new
          merger.merge_with_colors(
            left_art,
            right_art,
            left_color: left_color,
            right_colors: right_colors,
            spacing: spacing,
            left_offset: left_offset
          )
        end
      end
    end

    # Get the current terminal emulator instance (auto-detected)
    def self.current
      @current ||= detect_emulator
    end

    # Reset the current terminal (useful for testing)
    def self.reset!
      @current = nil
    end

    # Detect which terminal emulator we're running in
    def self.detect_emulator
      # Check environment variables for terminal identification

      # Kitty sets KITTY_WINDOW_ID
      return Emulator::Kitty::Kitty.new if ENV["KITTY_WINDOW_ID"]

      # Check TERM_PROGRAM for various terminals
      case ENV["TERM_PROGRAM"]
      when "kitty", "WezTerm"
        Emulator::Kitty::Kitty.new
      when "iTerm.app"
        # Could create an ITerm2 emulator in the future
        Emulator::Generic::Generic.new
      when "Apple_Terminal"
        # Could create a Terminal.app specific emulator
        Emulator::Generic::Generic.new
      when "vscode"
        # VS Code's integrated terminal
        Emulator::Generic::Generic.new
      else
        # Check for other indicators
        if ENV["ALACRITTY_SOCKET"] || ENV["ALACRITTY_LOG"]
          # Alacritty terminal
        elsif ENV["TERMINATOR_UUID"]
          # Terminator
        elsif ENV["KONSOLE_VERSION"]
          # KDE Konsole
        elsif ENV["GNOME_TERMINAL_SERVICE"]
          # GNOME Terminal
        else
          # Default to generic
        end
        Emulator::Generic::Generic.new
      end
    end

    # Check what terminal we're running in (for debugging)
    def self.identify
      info = {
        term: ENV["TERM"],
        term_program: ENV["TERM_PROGRAM"],
        term_program_version: ENV["TERM_PROGRAM_VERSION"],
        detected_as: current.class.name
      }

      # Add terminal-specific info
      if ENV["KITTY_WINDOW_ID"]
        info[:kitty_window_id] = ENV["KITTY_WINDOW_ID"]
        info[:kitty_pid] = ENV["KITTY_PID"]
      end

      info
    end

    def self.render_image(attachable)
      require "base64"

      # Get the image data based on what type of attachable we have
      image_data = case attachable
      when AI::Response::Image
                     attachable.blob
      when ActiveStorage::Blob
                     attachable.download
      when ActiveStorage::Attached::One
                     attachable.blob.download
      when Avatar
                     attachable.image.blob.download
      when Hash
                     raise ArgumentError, "Hash must have :io key" unless attachable[:io]

                     io = attachable[:io]
                     io = io.call if io.respond_to?(:call)
                     io.rewind if io.respond_to?(:rewind)
                     io.read

      when String
                     # Assume it's a file path
                     File.read(attachable)
      else
                     raise ArgumentError, "Don't know how to render #{attachable.class}"
      end

      # Encode the image for Kitty graphics protocol
      encoded = Base64.strict_encode64(image_data)

      # Send to terminal using Kitty graphics protocol
      # a=T means "transmit and display"
      # f=100 means PNG format (we'll assume PNG)
      print "\e_Ga=T,f=100,m=1;#{encoded}\e\\"

      # Add some spacing after the image
      puts "\n"

      # Return a helpful message
      "Image displayed (#{image_data.bytesize} bytes)"
    rescue StandardError => e
      puts "Error displaying image: #{e.message}"
      nil
    end
  end
end
