# frozen_string_literal: true

module Unmagic
  module Terminal
    module ASCII
      class Table
        attr_reader :headers, :rows, :options

        def initialize(headers: [], rows: [], **options)
          @headers = headers
          @rows = rows
          @options = {
            borders: true,
            header_separator: true,
            row_separators: false,
            alignment: :left, # Can be :left, :right, :center, or array of alignments per column
            padding: 1,
            style: :unicode,  # :unicode, :ascii, :markdown, :simple
            header_color: nil,
            row_colors: nil,  # Can be an array of colors to alternate
            column_colors: nil # Colors per column
          }.merge(options)
        end

        def render
          return "" if rows.empty? && headers.empty?

          # Calculate column widths
          column_widths = calculate_column_widths

          # Get border characters for the selected style
          borders = border_style(options[:style])

          # Build the table
          lines = []

          if options[:borders] && borders[:top]
            lines << draw_border(borders[:top], borders[:top_join], borders[:top_right], column_widths)
          end

          if headers.any?
            lines << draw_row(headers, column_widths, borders[:left], borders[:column_divider], borders[:right],
                              :header)
            if options[:header_separator]
              lines << if borders[:header]
                         draw_border(borders[:header], borders[:header_join], borders[:header_right], column_widths)
              else
                         draw_border(borders[:middle], borders[:cross], borders[:middle_right], column_widths)
              end
            elsif options[:borders] && borders[:middle]
              lines << draw_border(borders[:middle], borders[:cross], borders[:middle_right], column_widths)
            end
          end

          rows.each_with_index do |row, index|
            lines << draw_row(row, column_widths, borders[:left], borders[:column_divider], borders[:right], :data,
                              index)
            if options[:row_separators] && index < rows.length - 1 && borders[:middle]
              lines << draw_border(borders[:middle], borders[:cross], borders[:middle_right], column_widths)
            end
          end

          if options[:borders] && borders[:bottom]
            lines << draw_border(borders[:bottom], borders[:bottom_join], borders[:bottom_right], column_widths)
          end

          lines.join("\n")
        end

        def to_s
          render
        end

        private

        def calculate_column_widths
          widths = []

          # Start with header widths
          headers.each_with_index do |header, i|
            widths[i] = strip_ansi(header.to_s).length
          end

          # Check each row for wider content
          rows.each do |row|
            row.each_with_index do |cell, i|
              cell_length = strip_ansi(cell.to_s).length
              widths[i] = [ widths[i] || 0, cell_length ].max
            end
          end

          widths
        end

        def strip_ansi(text)
          # Remove ANSI color codes for accurate length calculation
          text.gsub(/\e\[[\d;]*m/, "")
        end

        def border_style(style)
          case style
          when :unicode
            {
              top: "─", top_join: "┬", top_right: "┐", top_left: "┌",
              middle: "─", cross: "┼", middle_right: "┤", middle_left: "├",
              bottom: "─", bottom_join: "┴", bottom_right: "┘", bottom_left: "└",
              left: "│", right: "│", column_divider: "│",
              header: "═", header_join: "╪", header_right: "┤", header_left: "├"
            }
          when :ascii
            {
              top: "-", top_join: "+", top_right: "+", top_left: "+",
              middle: "-", cross: "+", middle_right: "+", middle_left: "+",
              bottom: "-", bottom_join: "+", bottom_right: "+", bottom_left: "+",
              left: "|", right: "|", column_divider: "|",
              header: "=", header_join: "+", header_right: "+", header_left: "+"
            }
          when :markdown
            {
              top: nil, top_join: nil, top_right: nil, top_left: nil,
              middle: "-", cross: "|", middle_right: "|", middle_left: "|",
              bottom: nil, bottom_join: nil, bottom_right: nil, bottom_left: nil,
              left: "|", right: "|", column_divider: "|",
              header: "-", header_join: "|", header_right: "|", header_left: "|"
            }
          when :simple
            {
              top: nil, top_join: nil, top_right: nil, top_left: nil,
              middle: nil, cross: nil, middle_right: nil, middle_left: nil,
              bottom: nil, bottom_join: nil, bottom_right: nil, bottom_left: nil,
              left: "", right: "", column_divider: "  ",
              header: nil, header_join: nil, header_right: nil, header_left: nil
            }
          else
            border_style(:unicode)
          end
        end

        def draw_border(char, join_char, right_char, widths)
          return nil unless char

          borders = border_style(options[:style])
          left_char = case char
          when borders[:top] then borders[:top_left]
          when borders[:middle] then borders[:middle_left]
          when borders[:bottom] then borders[:bottom_left]
          when borders[:header] then borders[:header_left]
          else borders[:middle_left]
          end

          padding = options[:padding] * 2
          left_char + widths.map { |w| char * (w + padding) }.join(join_char) + right_char
        end

        def draw_row(row, widths, left_border, middle_border, right_border, row_type = :data, row_index = 0)
          cells = row.each_with_index.map do |cell, col_index|
            text = cell.to_s

            # Apply colors
            if row_type == :header && options[:header_color]
              color_args = Array(options[:header_color])
              text = if color_args.first.is_a?(Array) || (color_args.length == 3 && color_args.all? do |c|
                c.is_a?(Integer)
              end)
                       Unmagic::Terminal::ANSI.rgb_text(text, color_args.flatten[0..2])
              else
                       Unmagic::Terminal::ANSI.text(text, color: color_args.first)
              end
            elsif row_type == :data
              if options[:row_colors].is_a?(Array)
                color = options[:row_colors][row_index % options[:row_colors].length]
                if color
                  color_args = Array(color)
                  text = if color_args.first.is_a?(Array) || (color_args.length == 3 && color_args.all? do |c|
                    c.is_a?(Integer)
                  end)
                           Unmagic::Terminal::ANSI.rgb_text(text, color_args.flatten[0..2])
                  else
                           Unmagic::Terminal::ANSI.text(text, color: color_args.first)
                  end
                end
              elsif options[:column_colors] && options[:column_colors][col_index]
                color_args = Array(options[:column_colors][col_index])
                text = if color_args.first.is_a?(Array) || (color_args.length == 3 && color_args.all? do |c|
                  c.is_a?(Integer)
                end)
                         Unmagic::Terminal::ANSI.rgb_text(text, color_args.flatten[0..2])
                else
                         Unmagic::Terminal::ANSI.text(text, color: color_args.first)
                end
              end
            end

            align_text(text, widths[col_index] || 0, col_index)
          end

          padding = " " * options[:padding]
          left_border + padding + cells.join(padding + middle_border + padding) + padding + right_border
        end

        def align_text(text, width, column_index = 0)
          stripped = strip_ansi(text)
          padding_needed = width - stripped.length

          # Determine alignment for this column
          alignment = if options[:alignment].is_a?(Array)
                        options[:alignment][column_index] || :left
          else
                        options[:alignment]
          end

          case alignment
          when :right
            " " * padding_needed + text
          when :center
            left_pad = padding_needed / 2
            right_pad = padding_needed - left_pad
            " " * left_pad + text + " " * right_pad
          else # :left
            text + " " * padding_needed
          end
        end

        # Convenience class methods
        def self.generate(headers: [], rows: [], **options)
          new(headers: headers, rows: rows, **options).render
        end

        # Create a simple table without borders
        def self.simple(headers: [], rows: [], **options)
          generate(headers: headers, rows: rows,
                   **options.merge(style: :simple, borders: false, header_separator: false))
        end

        # Create a markdown-style table
        def self.markdown(headers: [], rows: [], **options)
          generate(headers: headers, rows: rows, **options.merge(style: :markdown, borders: false))
        end
      end
    end
  end
end
