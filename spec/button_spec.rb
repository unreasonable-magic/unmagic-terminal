# frozen_string_literal: true

require 'spec_helper'
require 'unmagic/terminal/button'

RSpec.describe Unmagic::Terminal::Button do
  describe '#initialize' do
    it 'creates a button with text' do
      button = described_class.new(text: "Test Button")
      expect(button.text).to eq("Test Button")
      expect(button.state).to eq(:default)
    end

    it 'accepts optional styling parameters' do
      background = Unmagic::Terminal::Style::Background.new(color: :blue)
      border = Unmagic::Terminal::Style::Border.new(style: :single)
      text_style = Unmagic::Terminal::Style::Text.new(color: :white)

      button = described_class.new(
        text: "Styled Button",
        background: background,
        border: border,
        text_style: text_style
      )

      expect(button.background).to eq(background)
      expect(button.border).to eq(border)
      expect(button.text_style).to eq(text_style)
    end
  end

  describe '#set_state' do
    let(:button) { described_class.new(text: "Test") }

    it 'changes the button state' do
      button.set_state(:hover)
      expect(button.state).to eq(:hover)
    end

    it 'accepts all valid states' do
      %i[default hover focus pressed].each do |state|
        button.set_state(state)
        expect(button.state).to eq(state)
      end
    end

    it 'raises error for invalid states' do
      expect { button.set_state(:invalid) }.to raise_error(ArgumentError)
    end
  end

  describe '#interact' do
    it 'calls the block when provided' do
      callback_called = false
      button = described_class.new(text: "Test") do |state|
        callback_called = true
      end

      button.interact
      expect(callback_called).to be true
    end

    it 'passes the current state to the block' do
      received_state = nil
      button = described_class.new(text: "Test") do |state|
        received_state = state
      end

      button.set_state(:hover)
      button.interact
      expect(received_state).to eq(:hover)
    end

    it 'changes state when interaction_state is provided' do
      button = described_class.new(text: "Test")
      button.interact(:pressed)
      expect(button.state).to eq(:pressed)
    end

    it 'does nothing when no block is provided' do
      button = described_class.new(text: "Test")
      expect { button.interact }.not_to raise_error
    end
  end

  describe '#render' do
    it 'renders basic button text' do
      button = described_class.new(text: "Test")
      result = button.render
      expect(result).to include("Test")
    end

    it 'adds padding around text' do
      button = described_class.new(text: "Test")
      result = button.render
      expect(result).to eq(" Test ")
    end

    it 'applies border when provided' do
      border = Unmagic::Terminal::Style::Border.new(style: :single)
      button = described_class.new(text: "Test", border: border)
      result = button.render
      
      expect(result).to include("┌")
      expect(result).to include("└")
      expect(result).to include("│")
      expect(result).to include("Test")
    end
  end
end