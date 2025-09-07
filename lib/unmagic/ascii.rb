# frozen_string_literal: true

# Backward compatibility layer for unmagic-ascii gem
# All functionality has been moved to Unmagic::Terminal::ASCII

require_relative "terminal"

module Unmagic
  # Legacy ASCII module - delegates to Terminal::ASCII for backward compatibility
  module ASCII
    # Delegate all calls to Terminal::ASCII
    def self.duck
      Terminal::ASCII.duck
    end

    def self.merge(left_art, right_art, spacing: 2, left_offset: 0)
      Terminal::ASCII.merge(left_art, right_art, spacing: spacing, left_offset: left_offset)
    end

    def self.colorize_merged(left_art, right_art, left_color: nil, right_colors: nil, spacing: 2, left_offset: 0)
      Terminal::ASCII.colorize_merged(
        left_art,
        right_art,
        left_color: left_color,
        right_colors: right_colors,
        spacing: spacing,
        left_offset: left_offset
      )
    end

    # Delegate classes for backward compatibility
    Duck = Terminal::ASCII::Duck
    Table = Terminal::ASCII::Table
    Banner = Terminal::ASCII::Banner
    LineMerger = Terminal::ASCII::LineMerger
    Box = Terminal::ASCII::Box
    Layout = Terminal::ASCII::Layout
  end
end
