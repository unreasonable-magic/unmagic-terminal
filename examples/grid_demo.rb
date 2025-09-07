#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/grid'
require 'unmagic/terminal/style/background'
require 'unmagic/terminal/style/border'

# Get terminal size
def terminal_size
  require 'io/console'
  IO.console.winsize.reverse
rescue StandardError
  [ 80, 24 ]
end

# Demo 1: Simple layout with fixed and flexible columns
def demo_simple_layout
  width, = terminal_size
  grid = Unmagic::Terminal::Grid.new(width: width)

  # Set up column template: fixed sidebar, flexible main area, fixed sidebar
  grid.template_columns = [ 20, :fr, 15 ] # 20 chars, 1fr, 15 chars
  grid.column_gap = 2
  grid.row_gap = 1

  # Add header spanning all columns
  grid.add_item(
    content: 'HEADER - Spanning All Columns',
    column: 1,
    column_span: 3,
    border: Unmagic::Terminal::Style::Border.new(style: :double, color: :cyan),
    background: Unmagic::Terminal::Style::Background.new(color: :blue),
    padding: 1,
    align: :center,
    justify: :center
  )

  # Add left sidebar
  grid.add_item(
    content: "Left Sidebar\n\nFixed width\n20 characters\n\n• Item 1\n• Item 2\n• Item 3",
    column: 1,
    row: 2,
    border: Unmagic::Terminal::Style::Border.new(style: :single, color: :green),
    padding: 1
  )

  # Add main content
  grid.add_item(
    content: "Main Content Area\n\nThis column uses 1fr\nso it expands to fill\nthe available space.\n\nThe grid automatically\ncalculates the width\nbased on terminal size.",
    column: 2,
    row: 2,
    border: Unmagic::Terminal::Style::Border.new(style: :rounded, color: :yellow),
    background: Unmagic::Terminal::Style::Background.new(pattern: :dots, color: :gray),
    padding: 1,
    align: :start
  )

  # Add right sidebar
  grid.add_item(
    content: "Right Bar\n\nFixed:\n15 chars",
    column: 3,
    row: 2,
    border: Unmagic::Terminal::Style::Border.new(style: :single, color: :magenta),
    padding: 1
  )

  # Add footer
  grid.add_item(
    content: 'Footer - Auto-sized row height',
    column: 1,
    row: 3,
    column_span: 3,
    background: Unmagic::Terminal::Style::Background.new(color: :gray),
    align: :center,
    justify: :center
  )

  grid
end

# Demo 2: Complex layout with mixed column sizes
def demo_complex_layout
  width, = terminal_size
  grid = Unmagic::Terminal::Grid.new(width: width)

  # Complex column template: auto, 1fr, 2fr, fixed
  grid.template_columns = [ :auto, :fr, { fr: 2 }, 10 ]
  grid.column_gap = 1

  # Row 1: Title spanning most columns
  grid.add_item(
    content: 'Dashboard',
    column: 1,
    column_span: 3,
    border: Unmagic::Terminal::Style::Border.new(style: :bold, color: :cyan),
    padding: 1,
    justify: :center
  )

  # Row 1: Status indicator
  grid.add_item(
    content: '●',
    column: 4,
    row: 1,
    background: Unmagic::Terminal::Style::Background.new(color: :green),
    justify: :center,
    align: :center
  )

  # Row 2: Navigation (auto-width)
  grid.add_item(
    content: "Nav\n----\nHome\nUsers\nSettings\nLogout",
    column: 1,
    row: 2,
    border: Unmagic::Terminal::Style::Border.new(style: :single),
    padding: 1
  )

  # Row 2: Stats (1fr)
  grid.add_item(
    content: "Statistics\n\nUsers: 1,234\nPosts: 5,678\nViews: 90.1k",
    column: 2,
    row: 2,
    background: Unmagic::Terminal::Style::Background.new(pattern: :shaded_light, color: :blue),
    padding: 1
  )

  # Row 2: Main content (2fr)
  grid.add_item(
    content: "Main Content (2fr)\n\nThis column gets twice\nthe space of the 1fr column.\n\nThe 'auto' column sizes\nbased on its content.\n\nRows auto-grow to fit\ntheir content!",
    column: 3,
    row: 2,
    border: Unmagic::Terminal::Style::Border.new(style: :double, color: :yellow),
    padding: 1
  )

  # Row 2: Fixed width icons
  grid.add_item(
    content: "[i]\n[?]\n[x]",
    column: 4,
    row: 2,
    justify: :center
  )

  grid
end

# Demo 3: Responsive-like behavior with fractional units
def demo_responsive
  width, = terminal_size
  grid = Unmagic::Terminal::Grid.new(width: width)

  # All flexible columns
  grid.template_columns = [ :fr, { fr: 2 }, :fr ]
  grid.column_gap = 1

  # Create a card-like layout
  3.times do |row|
    3.times do |col|
      content = "Card #{row * 3 + col + 1}\n\n" \
                "Flexible\n" +
                (col == 1 ? '2fr wide' : '1fr wide')

      grid.add_item(
        content: content,
        column: col + 1,
        row: row + 1,
        border: Unmagic::Terminal::Style::Border.new(
          style: %i[single double rounded].sample,
          color: %i[red green blue yellow magenta cyan].sample
        ),
        padding: 1,
        align: :center,
        justify: :center
      )
    end
  end

  grid
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  # Clear screen
  print "\e[2J\e[H"

  demos = {
    '1' => { name: 'Simple Layout', method: :demo_simple_layout },
    '2' => { name: 'Complex Layout', method: :demo_complex_layout },
    '3' => { name: 'Responsive Cards', method: :demo_responsive }
  }

  # Get demo choice from command line or show menu
  choice = ARGV[0]

  if !choice || !demos[choice]
    puts "CSS Grid Demo - Choose a demo:\n\n"
    demos.each do |key, info|
      puts "  #{key}) #{info[:name]}"
    end
    puts "\nUsage: #{$PROGRAM_NAME} [1|2|3]"
    exit
  end

  # Run selected demo
  demo = demos[choice]
  grid = send(demo[:method])

  # Render the grid
  renderer = Unmagic::Terminal::Grid::Renderer.new(grid)
  renderer.render

  # Show info at bottom
  width, height = terminal_size
  print "\e[#{height};1H"
  puts "\nGrid Demo: #{demo[:name]} | Terminal: #{width}x#{height} | Press Ctrl+C to exit"
end
