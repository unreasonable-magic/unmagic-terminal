# frozen_string_literal: true

module Unmagic
  module Terminal
    module Style
      # Background style for grid cells. Provides patterns and colors.
      #
      # Example:
      #
      #   background = Background.new(color: :blue)
      #   background = Background.new(color: [100, 150, 200])  # RGB color
      #   background = Background.new(pattern: :dots)  # Pattern fill
      class Background
        PATTERNS = {
          dots: "·",
          lines: "─",
          crosses: "+",
          diamonds: "◆",
          blocks: "█",
          shaded_light: "░",
          shaded_medium: "▒",
          shaded_dark: "▓",
          waves: "~",
          checkers: "▚"
        }.freeze

        attr_reader :color, :pattern, :char

        def initialize(color: nil, pattern: nil, char: nil)
          @color = color
          @pattern = pattern
          @char = char || " "
        end
      end
    end
  end
end
