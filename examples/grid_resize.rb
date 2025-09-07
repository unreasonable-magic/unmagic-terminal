#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo showing Grid layout responding to terminal resize events
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic/terminal/grid'
require 'unmagic/terminal/emulator/generic'
require 'unmagic/terminal/style/background'
require 'unmagic/terminal/style/border'

# Create emulator for resize detection
emulator = Unmagic::Terminal::Emulator::Generic::Generic.new

# Track stats
resize_count = 0
last_resize = nil

# Function to create and render grid based on terminal size
def create_responsive_grid(width, height, resize_count, last_resize)
  grid = Unmagic::Terminal::Grid.new(width: width)

  # Responsive column layout based on width
  if width < 60
    # Single column for narrow terminals
    grid.template_columns = [ :fr ]
    column_mode = 'Single Column'
  elsif width < 100
    # Two columns for medium terminals
    grid.template_columns = %i[fr fr]
    column_mode = 'Two Column'
  else
    # Three columns for wide terminals
    grid.template_columns = [ 20, :fr, { fr: 2 }, 20 ]
    column_mode = 'Multi Column'
  end

  grid.column_gap = 2
  grid.row_gap = 1

  # Header - spans all columns
  num_columns = grid.column_tracks.size
  grid.add_item(
    content: '🎯 Responsive Grid Demo',
    column: 1,
    column_span: num_columns,
    border: Unmagic::Terminal::Style::Border.new(style: :double, color: :cyan),
    background: Unmagic::Terminal::Style::Background.new(color: :blue),
    padding: 1,
    align: :center,
    justify: :center
  )

  # Info panel
  info_content = [
    "Terminal: #{width}×#{height}",
    "Layout: #{column_mode}",
    "Resizes: #{resize_count}",
    '',
    'Resize your terminal',
    'to see the grid adapt!',
    '',
    "Press 'q' to quit"
  ].join("\n")

  grid.add_item(
    content: info_content,
    column: 1,
    row: 2,
    border: Unmagic::Terminal::Style::Border.new(style: :rounded, color: :green),
    padding: 1
  )

  # Add content panels based on column mode
  if num_columns >= 2
    # Content panel
    content_lines = []
    content_lines << 'Dynamic Content Area'
    content_lines << '─' * 20
    content_lines << ''
    content_lines << 'This panel appears when'
    content_lines << 'the terminal is wide'
    content_lines << 'enough for 2+ columns.'
    content_lines << ''
    content_lines << 'Grid features:'
    content_lines << '• Fractional units (fr)'
    content_lines << '• Fixed widths'
    content_lines << '• Auto-sizing'
    content_lines << '• Column/row gaps'
    content_lines << '• Borders & padding'

    grid.add_item(
      content: content_lines.join("\n"),
      column: 2,
      row: 2,
      column_span: [ num_columns - 2, 1 ].max,
      border: Unmagic::Terminal::Style::Border.new(style: :single, color: :yellow),
      background: Unmagic::Terminal::Style::Background.new(pattern: :dots, color: :gray),
      padding: 1
    )
  end

  if num_columns >= 3
    # Side panel for 3+ column layout
    grid.add_item(
      content: "Side Panel\n\nFixed width\ncolumn that\nonly appears\nin wide mode",
      column: num_columns,
      row: 2,
      border: Unmagic::Terminal::Style::Border.new(style: :single, color: :magenta),
      padding: 1
    )
  end

  # Last resize info (if any)
  if last_resize
    resize_info = "Last resize: #{last_resize.old_width}×#{last_resize.old_height} → #{last_resize.width}×#{last_resize.height}"

    grid.add_item(
      content: resize_info,
      column: 1,
      row: 3,
      column_span: num_columns,
      background: Unmagic::Terminal::Style::Background.new(color: :gray),
      align: :center,
      justify: :center
    )
  end

  # Status bar at bottom
  status_items = []

  # Add emoji indicators based on width
  status_items << if width >= 120
                    '🖥️  Desktop'
  elsif width >= 80
                    '💻 Laptop'
  else
                    '📱 Mobile'
  end

  status_items << '│'
  status_items << "Cols: #{num_columns}"
  status_items << '│'
  status_items << Time.now.strftime('%H:%M:%S')

  grid.add_item(
    content: status_items.join(' '),
    column: 1,
    row: 4,
    column_span: num_columns,
    background: Unmagic::Terminal::Style::Background.new(color: :blue),
    justify: :center,
    align: :center
  )

  grid
end

# Function to render the grid
def render_grid(emulator, resize_count, last_resize)
  width = emulator.width
  height = emulator.height

  # Clear and reset cursor
  emulator.clear
  emulator.move_cursor(1, 1)

  # Create and render grid
  grid = create_responsive_grid(width, height, resize_count, last_resize)
  renderer = Unmagic::Terminal::Grid::Renderer.new(grid)

  print renderer
  $stdout.flush
end

# Initial setup
emulator.clear
emulator.hide_cursor

# Set up resize handler
emulator.on_resize do |event|
  resize_count += 1
  last_resize = event
  render_grid(emulator, resize_count, last_resize)
end

# Enable resize events
emulator.enable_resize_events

# Initial render
render_grid(emulator, resize_count, last_resize)

# Main event loop
begin
  puts "\e[999;1H" # Move cursor to bottom
  print "Ready. Press 'q' to quit."
  $stdout.flush

  loop do
    # Read input with timeout
    event = emulator.event_reader.read_event(timeout: 0.1)

    if event
      case event
      when Unmagic::Terminal::Emulator::ResizeEvent
        # Already handled by the resize handler
      else
        # Check for quit
        break if event.respond_to?(:char) && event.char == 'q'
      end
    end

    # Update time in status bar every second
    if Time.now.sec != @last_sec
      @last_sec = Time.now.sec
      render_grid(emulator, resize_count, last_resize)
    end
  end
rescue Interrupt
  # Handle Ctrl+C gracefully
ensure
  # Clean up
  emulator.disable_resize_events
  emulator.clear
  emulator.show_cursor
  emulator.move_cursor(1, 1)

  puts 'Grid resize demo ended.'
  puts "Total resize events: #{resize_count}"

  puts "Final size: #{last_resize.width}×#{last_resize.height}" if last_resize
end
