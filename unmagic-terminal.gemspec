# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'unmagic-terminal'
  spec.version = '0.1.0'
  spec.authors = [ 'Keith Pitt' ]
  spec.email = [ 'me@keithpitt.com' ]
  spec.summary = 'Terminal utilities for ANSI formatting, ASCII art, and image rendering'
  spec.description = 'Provides comprehensive terminal capabilities including ANSI escape codes, color formatting, palette detection, Kitty graphics protocol support, ASCII art generation, table formatting, and banner creation'
  spec.homepage = 'https://github.com/unreasonable-magic/unmagic-terminal'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.files = Dir['lib/**/*']
  spec.require_paths = [ 'lib' ]

  # Dependencies
  spec.add_dependency 'unmagic-color'
  spec.add_dependency 'unmagic-support'
end
