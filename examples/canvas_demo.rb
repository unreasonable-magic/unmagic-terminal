#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo of the terminal canvas system with multiple updating regions
$LOAD_PATH.unshift(File.expand_path('../../unmagic-color/lib', __dir__))
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'unmagic-terminal'
require 'unmagic/terminal/canvas'

# Clear screen and hide cursor for cleaner display
print "\e[2J\e[H\e[?25l"

# Create canvas
canvas = Unmagic::Terminal::Canvas.new(fps: 30)

# Define regions
canvas.define_region(:title, x: 0, y: 0, width: 80, height: 3, bg: :blue, fg: :white)
canvas.define_region(:logs, x: 0, y: 4, width: 50, height: 15, border: true)
canvas.define_region(:status, x: 52, y: 4, width: 28, height: 5, bg: :green, fg: :black)
canvas.define_region(:metrics, x: 52, y: 10, width: 28, height: 9, border: true)

# Set initial content
canvas.regions[:title] = '  🚀 Terminal Canvas Demo'
canvas.regions[:status] = ' Status: Initializing...'
canvas.regions[:logs] << "System starting up...\n"

# Thread 1: Simulated log entries
Thread.new do
  messages = [
    'Loading configuration files',
    'Connecting to database',
    'Initializing cache',
    'Starting web server',
    'Loading plugins',
    'Checking dependencies',
    'Running migrations',
    'Compiling assets',
    'Starting background jobs',
    'Ready to accept connections'
  ]

  messages.each do |msg|
    canvas.regions[:logs] << "[#{Time.now.strftime('%H:%M:%S')}] #{msg}...\n"
    sleep(0.5 + rand)
  end

  # Continue with random logs
  loop do
    level = %w[INFO DEBUG WARN ERROR].sample
    action = %w[Processing Completed Failed Retrying Queued].sample
    canvas.regions[:logs] << "[#{Time.now.strftime('%H:%M:%S')}] #{level}: #{action} job #{rand(1000)}\n"
    sleep(1 + rand * 2)
  end
end

# Thread 2: Status updates
Thread.new do
  statuses = [ '🟢 Running', '⚡ Processing', '🔄 Syncing', '✨ Optimizing' ]
  loop do
    status = statuses.sample
    uptime = Time.now - $start_time
    actual_fps = canvas.actual_fps.round(1)
    target_fps = canvas.target_fps
    canvas.regions[:status] =
      " Status: #{status}\n Uptime: #{uptime.to_i}s\n FPS: #{actual_fps}/#{target_fps}\n Tasks: #{rand(10..50)}"
    sleep(2)
  end
end

# Thread 3: Progress bars updates
Thread.new do
  # Progress tracking for different tasks
  download_progress = 0
  process_progress = 0
  upload_progress = 0
  deploy_progress = 0

  loop do
    # Simulate different progress rates
    download_progress = [ download_progress + rand(1..3), 100 ].min
    process_progress = [ process_progress + rand(0..2), 100 ].min if download_progress > 20
    upload_progress = [ upload_progress + rand(0..1), 100 ].min if process_progress > 50
    deploy_progress = [ deploy_progress + rand(0..1), 100 ].min if upload_progress > 80

    # Reset when all complete
    if [ download_progress, process_progress, upload_progress, deploy_progress ].all? { |p| p >= 100 }
      sleep(2)
      download_progress = process_progress = upload_progress = deploy_progress = 0
    end

    progress_bars = [
      ' Build Progress',
      " #{'─' * 25}",
      " DL:   #{download_progress.to_s.rjust(3)}% #{'█' * (download_progress / 10)}",
      " PROC: #{process_progress.to_s.rjust(3)}% #{'█' * (process_progress / 10)}",
      " UP:   #{upload_progress.to_s.rjust(3)}% #{'█' * (upload_progress / 10)}",
      " DEPL: #{deploy_progress.to_s.rjust(3)}% #{'█' * (deploy_progress / 10)}"
    ].join("\n")

    canvas.regions[:metrics] = progress_bars

    sleep(0.3)
  end
end

# Record start time
$start_time = Time.now

# Start the canvas - this will block until Ctrl+C
puts 'Starting canvas demo... Press Ctrl+C to exit.'
begin
  canvas.start # Blocks main thread, handles Ctrl+C automatically
rescue Interrupt
  # Canvas.start already calls stop() on interrupt, but let's be explicit
  canvas.stop
ensure
  # Show cursor again
  print "\e[?25h"

  # Move cursor below our regions
  print "\e[21;1H"

  puts 'Demo terminated.'
end
