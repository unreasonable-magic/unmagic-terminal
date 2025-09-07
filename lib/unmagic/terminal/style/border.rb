# frozen_string_literal: true

module Unmagic
  module Terminal
    module Style
      # Border style for grid cells. Provides various border styles.
      #
      # Example:
      #
      #   border = Border.new(style: :single)
      #   border = Border.new(style: :double, color: :red)
      #   border = Border.new(style: :rounded, color: [100, 200, 150])
      class Border
        # Border character sets for different styles
        STYLES = {
          single: {
            top_left: "┌",
            top: "─",
            top_right: "┐",
            left: "│",
            right: "│",
            bottom_left: "└",
            bottom: "─",
            bottom_right: "┘"
          },
          double: {
            top_left: "╔",
            top: "═",
            top_right: "╗",
            left: "║",
            right: "║",
            bottom_left: "╚",
            bottom: "═",
            bottom_right: "╝"
          },
          rounded: {
            top_left: "╭",
            top: "─",
            top_right: "╮",
            left: "│",
            right: "│",
            bottom_left: "╰",
            bottom: "─",
            bottom_right: "╯"
          },
          bold: {
            top_left: "┏",
            top: "━",
            top_right: "┓",
            left: "┃",
            right: "┃",
            bottom_left: "┗",
            bottom: "━",
            bottom_right: "┛"
          },
          ascii: {
            top_left: "+",
            top: "-",
            top_right: "+",
            left: "|",
            right: "|",
            bottom_left: "+",
            bottom: "-",
            bottom_right: "+"
          },
          dots: {
            top_left: "·",
            top: "·",
            top_right: "·",
            left: "·",
            right: "·",
            bottom_left: "·",
            bottom: "·",
            bottom_right: "·"
          },
          dashed: {
            top_left: "┌",
            top: "┄",
            top_right: "┐",
            left: "┆",
            right: "┆",
            bottom_left: "└",
            bottom: "┄",
            bottom_right: "┘"
          }
        }.freeze

        attr_reader :style, :color

        def initialize(style: :single, color: nil)
          @style = style
          @color = color
        end
      end
    end
  end
end
