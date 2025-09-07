#!/usr/bin/env ruby
# frozen_string_literal: true

# Test to verify canvas regions render at correct positions
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'
require 'unmagic/terminal/canvas'

# Clear screen first
print "\e[2J\e[H"

# Print some initial content to show canvas starts partway down
puts '=== Canvas Positioning Test ==='
puts 'This text is before the canvas'
puts 'The canvas should start below this line:'
puts ''

# Create canvas (it will save cursor position here)
canvas = Unmagic::Terminal::Canvas.new(fps: 1)

# Define multiple regions to test positioning
canvas.define_region(:box1, x: 0, y: 0, width: 20, height: 1)
canvas.define_region(:box2, x: 0, y: 1, width: 20, height: 1)
canvas.define_region(:box3, x: 0, y: 2, width: 20, height: 1)

# Set content for each region
canvas.regions[:box1] = 'Line 1 at (0,0)'
canvas.regions[:box2] = 'Line 2 at (0,1)'
canvas.regions[:box3] = 'Line 3 at (0,2)'

# Start canvas in background
thread = canvas.start(async: true)

# Let it render
sleep 2

# Update one region to test independent updates
canvas.regions[:box2] = 'UPDATED LINE 2'

sleep 2

# Test multi-line content in a single region
canvas.define_region(:multiline, x: 25, y: 0, width: 30, height: 3)
canvas.regions[:multiline] = "First line\nSecond line\nThird line"

sleep 2

# Clean up
canvas.stop
thread.join

# Move cursor below canvas area
print "\e[10;1H"
puts "\nTest complete!"
