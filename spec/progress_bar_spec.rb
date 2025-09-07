# frozen_string_literal: true

require 'spec_helper'
require 'unmagic/terminal/progress_bar'

RSpec.describe Unmagic::Terminal::ProgressBar do
  let(:progress_bar) { described_class.new(total: 100, width: 20) }

  describe '#initialize' do
    it 'sets initial values' do
      expect(progress_bar.current).to eq(0)
      expect(progress_bar.total).to eq(100)
      expect(progress_bar.width).to eq(20)
    end
  end

  describe '#update' do
    it 'updates current progress' do
      progress_bar.update(50)
      expect(progress_bar.current).to eq(50)
    end

    it 'does not exceed total' do
      progress_bar.update(150)
      expect(progress_bar.current).to eq(100)
    end
  end

  describe '#increment' do
    it 'increases progress by one' do
      progress_bar.increment
      expect(progress_bar.current).to eq(1)

      progress_bar.increment
      expect(progress_bar.current).to eq(2)
    end
  end

  describe '#percentage' do
    it 'calculates percentage correctly' do
      progress_bar.update(25)
      expect(progress_bar.percentage.value).to eq(25.0)

      progress_bar.update(50)
      expect(progress_bar.percentage.value).to eq(50.0)
    end

    it 'handles zero total' do
      zero_total_bar = described_class.new(total: 0)
      expect(zero_total_bar.percentage.value).to eq(0.0)
    end

    it 'returns Percentage object' do
      progress_bar.update(25)
      expect(progress_bar.percentage).to be_a(Unmagic::Support::Percentage)
    end
  end

  describe '#complete?' do
    it 'returns false when not complete' do
      progress_bar.update(50)
      expect(progress_bar.complete?).to be false
    end

    it 'returns true when complete' do
      progress_bar.update(100)
      expect(progress_bar.complete?).to be true
    end
  end

  describe '#render' do
    it 'renders progress bar with percentage' do
      progress_bar.update(50)
      output = progress_bar.render

      expect(output).to include('50.0%')
      expect(output).to include('█')
      expect(output).to include('░')
    end

    it 'includes time estimation by default' do
      progress_bar.update(10)
      output = progress_bar.render

      expect(output).to include('ETA:')
    end

    it 'excludes time estimation when disabled' do
      no_time_bar = described_class.new(total: 100, show_time: false)
      no_time_bar.update(10)
      output = no_time_bar.render

      expect(output).not_to include('ETA:')
    end
  end

  describe '#reset' do
    it 'resets progress to zero' do
      progress_bar.update(50)
      expect(progress_bar.current).to eq(50)

      progress_bar.reset
      expect(progress_bar.current).to eq(0)
      expect(progress_bar.percentage.value).to eq(0.0)
    end
  end
end
