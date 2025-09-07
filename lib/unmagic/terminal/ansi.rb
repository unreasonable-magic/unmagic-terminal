# frozen_string_literal: true

module Unmagic
  module Terminal
    # ANSI escape codes and text formatting for terminal output
    module ANSI
      # ANSI escape codes for terminal color and style formatting
      module Codes
        # Reset all formatting
        RESET = "\e[0m"

        # Text styles
        BOLD = "\e[1m"
        DIM = "\e[2m"
        ITALIC = "\e[3m"
        UNDERLINE = "\e[4m"

        # Standard foreground colors (30-37)
        BLACK = "\e[30m"
        RED = "\e[31m"
        GREEN = "\e[32m"
        YELLOW = "\e[33m"
        BLUE = "\e[34m"
        MAGENTA = "\e[35m"
        CYAN = "\e[36m"
        WHITE = "\e[37m"

        # Background colors (40-47)
        BG_BLACK = "\e[40m"
        BG_RED = "\e[41m"
        BG_GREEN = "\e[42m"
        BG_YELLOW = "\e[43m"
        BG_BLUE = "\e[44m"
        BG_MAGENTA = "\e[45m"
        BG_CYAN = "\e[46m"
        BG_WHITE = "\e[47m"

        # Bright/high-intensity foreground colors (90-97)
        BRIGHT_BLACK = "\e[90m" # Also known as gray
        BRIGHT_RED = "\e[91m"
        BRIGHT_GREEN = "\e[92m"
        BRIGHT_YELLOW = "\e[93m"
        BRIGHT_BLUE = "\e[94m"
        BRIGHT_MAGENTA = "\e[95m"
        BRIGHT_CYAN = "\e[96m"
        BRIGHT_WHITE = "\e[97m"
      end

      # Colors used for automatic enum value coloring
      ENUM_COLORS = %i[
        blue
        green
        cyan
        magenta
        yellow
        bright_blue
        bright_green
        bright_cyan
        bright_magenta
        bright_yellow
      ].freeze

      # Semantic color mappings for common enum values
      SEMANTIC_ENUM_COLORS = {
        empty: :gray,
        pending: :yellow,
        running: :blue,
        active: :green,
        completed: :green,
        success: :green,
        succeeded: :green,
        failed: :red,
        error: :red,
        abandoned: :magenta,
        cancelled: :gray,
        inactive: :gray,
        warning: :yellow,
        thinking: :blue,
        ready: :green,

        public: :green,
        private: :red,
        protected: :yellow,
        internal: :cyan,

        low: :gray,
        medium: :yellow,
        high: :red,
        critical: :bright_red,

        true => :green,
        false => :red,
        yes: :green,
        no: :red,
        on: :green,
        off: :gray,
        enabled: :green,
        disabled: :gray
      }.freeze

      # Nerdfonts icons for common enum values
      SEMANTIC_ENUM_ICONS = {
        # Status/State icons
        empty: "○",
        pending: "",
        running: "",
        active: "●",
        completed: "",
        success: "",
        succeeded: "",
        failed: "",
        error: "",
        abandoned: "",
        cancelled: "",
        inactive: "",
        warning: "",
        thinking: "󰭎",
        ready: "",

        # Visibility icons
        public: "",
        private: "",
        protected: "",
        internal: "󰗇",

        # Priority icons
        low: "",
        medium: "",
        high: "",
        critical: "",

        # Boolean icons
        true => "",
        false => "",
        yes: "",
        no: "",
        on: "󰔐",
        off: "󰔑",
        enabled: "",
        disabled: ""
      }.freeze

      # Time-based color schemes for different periods of the day
      TIME_COLORS = {
        night: {
          name: "Night",
          hours: 0..5,
          start: [ 25, 25, 112 ], # MidnightBlue
          end: [ 75, 0, 130 ]         # Indigo
        },
        morning: {
          name: "Morning",
          hours: 6..11,
          start: [ 255, 140, 0 ],     # DarkOrange
          end: [ 255, 215, 0 ]        # Gold
        },
        day: {
          name: "Day",
          hours: 12..17,
          start: [ 0, 191, 255 ],     # DeepSkyBlue
          end: [ 0, 255, 255 ]        # Cyan
        },
        evening: {
          name: "Evening",
          hours: 18..23,
          start: [ 255, 69, 0 ],      # OrangeRed
          end: [ 138, 43, 226 ]       # BlueViolet
        }
      }.freeze

      class << self
        # Apply ANSI color and style formatting to text
        def text(text, color: nil, background: nil, style: nil)
          parts = []

          parts << style_code(style) if style
          parts << color_code(color) if color
          parts << background_code(background) if background

          parts << text
          parts << Codes::RESET if parts.compact.any? { |p| p != text }

          parts.join
        end

        # Apply RGB color formatting to text using 24-bit true color
        def rgb_text(text, rgb, style: nil, background_rgb: false)
          parts = []

          parts << style_code(style) if style

          # Handle both Color objects and arrays
          if rgb.respond_to?(:red) && rgb.respond_to?(:green) && rgb.respond_to?(:blue)
            r = rgb.red
            g = rgb.green
            b = rgb.blue
          elsif rgb.is_a?(Array)
            r = rgb[0]
            g = rgb[1]
            b = rgb[2]
          else
            return text # Can't format, return plain text
          end

          if background_rgb
            # RGB background with white text
            parts << "\e[38;2;255;255;255m" # White text
            parts << "\e[48;2;#{r};#{g};#{b}m" # RGB background
          else
            # RGB foreground
            parts << "\e[38;2;#{r};#{g};#{b}m"
          end

          parts << text
          parts << Codes::RESET

          parts.join
        end

        # Apply a gradient effect to multi-line text
        def gradient_text(text, from_color, to_color, style: nil)
          lines = text.is_a?(Array) ? text : text.to_s.split("\n")
          return "" if lines.empty?
          return rgb_text(lines.first, parse_color(from_color), style: style) if lines.size == 1

          # Parse colors to RGB arrays
          from_rgb = parse_color(from_color)
          to_rgb = parse_color(to_color)

          # Calculate color for each line
          colored_lines = lines.map.with_index do |line, index|
            # Calculate interpolation factor (0.0 to 1.0)
            factor = lines.size > 1 ? index.to_f / (lines.size - 1) : 0.0

            # Interpolate between colors
            interpolated_rgb = interpolate_rgb(from_rgb, to_rgb, factor)

            # Apply color to line
            rgb_text(line, interpolated_rgb, style: style)
          end

          colored_lines.join("\n")
        end

        # Create a gradient of RGB colors between start and end
        def create_gradient(start_rgb, end_rgb, steps)
          return [] if steps <= 0
          return [ start_rgb ] if steps == 1

          (0...steps).map do |i|
            ratio = i.to_f / (steps - 1)
            interpolate_rgb(start_rgb, end_rgb, ratio)
          end
        end

        # Get the color scheme for the current time of day
        def time_based_colors(time = Time.current)
          hour = time.hour
          TIME_COLORS.values.find { |scheme| scheme[:hours].include?(hour) }
        end

        # Get the name of the current time period
        def time_period(time = Time.current)
          time_based_colors(time)[:name]
        end

        # Apply a time-appropriate gradient to text
        def time_gradient_text(text, time = Time.current, style: nil)
          scheme = time_based_colors(time)
          gradient_text(text, scheme[:start], scheme[:end], style: style)
        end

        # Create a badge-style formatted text with padding
        def badge(text, color: nil, background: nil, style: nil)
          parts = []

          parts << style_code(style) if style
          parts << color_code(color) if color
          parts << background_code(background) if background

          parts << " #{text} " if parts.any?
          parts << Codes::RESET if parts.any?

          parts.join
        end

        # Apply semantic coloring to enum values
        def enum(enum_value, badge: false, background_color: :dark)
          text = enum_value.to_s
          normalized = text.downcase.to_sym
          display_text = text.upcase

          # Add icon if available and nerdfonts are enabled
          if ENV["PRINTER_NERDFONTS"] != "false" && SEMANTIC_ENUM_ICONS.key?(normalized)
            icon = SEMANTIC_ENUM_ICONS[normalized]
            display_text = "#{icon} #{display_text}"
          end

          if SEMANTIC_ENUM_COLORS.key?(normalized)
            if badge
              self.badge(display_text, color: :white, background: SEMANTIC_ENUM_COLORS[normalized])
            else
              self.text(display_text, color: SEMANTIC_ENUM_COLORS[normalized], style: :bold)
            end
          elsif (rgb = enum_rgb(text, background_color))
            if badge
              rgb_text(" #{display_text} ", rgb, background_rgb: true)
            else
              rgb_text(display_text, rgb, style: :bold)
            end
          else
            hash = text.each_byte.reduce(0) { |h, b| (h * 31 + b) % 1_000_000_007 }
            fallback_color = ENUM_COLORS[hash % ENUM_COLORS.length]

            if badge
              self.badge(display_text, color: :white, background: fallback_color)
            else
              self.text(display_text, color: fallback_color, style: :bold)
            end
          end
        end

        # Generate a consistent RGB color for an enum value
        def enum_rgb(value, background_color = :dark)
          hash = value.to_s.each_byte.reduce(0) { |h, b| (h * 31 + b) % 1_000_000_007 }

          hue = (hash % 360) / 360.0
          saturation = (70 + (hash % 30)) / 100.0
          lightness = background_color == :light ? 0.35 : 0.65

          rgb = hsl_to_rgb(hue, saturation, lightness)
          rgb.map { |c| (c * 255).round }
        rescue StandardError
          nil
        end

        # Adjust a color for better visibility on different backgrounds
        def adjust_for_background(color, background_color)
          return color unless background_color

          if background_color == :light
            case color
            when :white, :bright_white then :black
            when :yellow, :bright_yellow then :brown
            when :cyan, :bright_cyan then :blue
            else color
            end
          else
            color
          end
        end

        # Interpolate between two RGB colors
        def interpolate_rgb(from_rgb, to_rgb, factor)
          [
            (from_rgb[0] * (1 - factor) + to_rgb[0] * factor).round,
            (from_rgb[1] * (1 - factor) + to_rgb[1] * factor).round,
            (from_rgb[2] * (1 - factor) + to_rgb[2] * factor).round
          ]
        end

        private

        def parse_color(color)
          case color
          when Array
            color # Already RGB array
          when String
            # Parse hex color
            if color.start_with?("#")
              hex = color[1..]
              [ hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16) ]
            else
              [ 0, 0, 0 ] # Default to black if can't parse
            end
          else
            [ 0, 0, 0 ] # Default to black
          end
        end

        def hsl_to_rgb(h, s, l)
          if s.zero?
            [ l, l, l ]
          else
            q = l < 0.5 ? l * (1 + s) : l + s - l * s
            p = 2 * l - q

            r = hue_to_rgb(p, q, h + 1 / 3.0)
            g = hue_to_rgb(p, q, h)
            b = hue_to_rgb(p, q, h - 1 / 3.0)

            [ r, g, b ]
          end
        end

        def hue_to_rgb(p, q, t)
          t += 1 if t.negative?
          t -= 1 if t > 1

          if t < 1 / 6.0
            p + (q - p) * 6 * t
          elsif t < 1 / 2.0
            q
          elsif t < 2 / 3.0
            p + (q - p) * (2 / 3.0 - t) * 6
          else
            p
          end
        end

        def style_code(style)
          case style
          when :bold then Codes::BOLD
          when :dim then Codes::DIM
          when :italic then Codes::ITALIC
          when :underline then Codes::UNDERLINE
          end
        end

        def color_code(color)
          case color
          when :black then Codes::BLACK
          when :red then Codes::RED
          when :green then Codes::GREEN
          when :yellow then Codes::YELLOW
          when :blue then Codes::BLUE
          when :magenta then Codes::MAGENTA
          when :cyan then Codes::CYAN
          when :white then Codes::WHITE
          when :bright_black, :gray, :grey then Codes::BRIGHT_BLACK
          when :bright_red then Codes::BRIGHT_RED
          when :bright_green then Codes::BRIGHT_GREEN
          when :bright_yellow then Codes::BRIGHT_YELLOW
          when :bright_blue then Codes::BRIGHT_BLUE
          when :bright_magenta then Codes::BRIGHT_MAGENTA
          when :bright_cyan then Codes::BRIGHT_CYAN
          when :bright_white then Codes::BRIGHT_WHITE
          when :dim then Codes::DIM
          end
        end

        def background_code(color)
          case color
          when :black then Codes::BG_BLACK
          when :red then Codes::BG_RED
          when :green then Codes::BG_GREEN
          when :yellow then Codes::BG_YELLOW
          when :blue then Codes::BG_BLUE
          when :magenta then Codes::BG_MAGENTA
          when :cyan then Codes::BG_CYAN
          when :white then Codes::BG_WHITE
          end
        end
      end
    end
  end
end
