#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
OUTPUT_DIR = File.join(ROOT, "SoundLibrary", "RenderedVerification")
SAMPLE_RATE = 48_000
CHANNEL_COUNT = 1
BIT_DEPTH = 16
MASTER_GAIN = 1.0
ACCENT_BOOST = 1.0

PRESETS = {
  classic: {
    decay_power: 4.0,
    roles: {
      downbeat: { frequency: 1_600.0, duration: 0.035, gain: 0.85 * ACCENT_BOOST },
      beat: { frequency: 1_050.0, duration: 0.028, gain: 0.62 },
      subdivision: { frequency: 820.0, duration: 0.018, gain: 0.42 },
      cue: { frequency: 1_300.0, duration: 0.050, gain: 0.70 }
    }
  },
  wood: {
    decay_power: 5.0,
    roles: {
      downbeat: { frequency: 720.0, duration: 0.032, gain: 0.80 * ACCENT_BOOST },
      beat: { frequency: 560.0, duration: 0.026, gain: 0.58 },
      subdivision: { frequency: 440.0, duration: 0.018, gain: 0.36 },
      cue: { frequency: 660.0, duration: 0.040, gain: 0.62 }
    }
  },
  bell: {
    decay_power: 2.8,
    roles: {
      downbeat: { frequency: 2_100.0, duration: 0.055, gain: 0.78 * ACCENT_BOOST },
      beat: { frequency: 1_420.0, duration: 0.040, gain: 0.52 },
      subdivision: { frequency: 1_080.0, duration: 0.024, gain: 0.34 },
      cue: { frequency: 1_800.0, duration: 0.060, gain: 0.64 }
    }
  },
  mechanical: {
    decay_power: 7.0,
    roles: {
      downbeat: { frequency: 1_250.0, duration: 0.022, gain: 0.90 * ACCENT_BOOST },
      beat: { frequency: 920.0, duration: 0.018, gain: 0.66 },
      subdivision: { frequency: 700.0, duration: 0.012, gain: 0.40 },
      cue: { frequency: 1_100.0, duration: 0.030, gain: 0.72 }
    }
  }
}.freeze

MUTED_ROLE = { frequency: 200.0, duration: 0.004, gain: 0.0 }.freeze

def render_samples(frequency:, duration:, gain:, decay_power:)
  frame_count = (SAMPLE_RATE * duration).to_i
  (0...frame_count).map do |frame|
    progress = frame.to_f / frame_count
    envelope = (1.0 - progress)**decay_power
    sample = Math.sin((frame.to_f / SAMPLE_RATE) * frequency * 2.0 * Math::PI)
    value = sample * gain * MASTER_GAIN * envelope
    [[value, 1.0].min, -1.0].max
  end
end

def wav_bytes(samples)
  pcm_data = samples.map { |sample| (sample * 32_767).round.clamp(-32_768, 32_767) }.pack("s<*")
  byte_rate = SAMPLE_RATE * CHANNEL_COUNT * (BIT_DEPTH / 8)
  block_align = CHANNEL_COUNT * (BIT_DEPTH / 8)

  [
    "RIFF",
    36 + pcm_data.bytesize,
    "WAVE",
    "fmt ",
    16,
    1,
    CHANNEL_COUNT,
    SAMPLE_RATE,
    byte_rate,
    block_align,
    BIT_DEPTH,
    "data",
    pcm_data.bytesize,
    pcm_data
  ].pack("A4VA4A4VvvVVvvA4VA*")
end

def write_readme(files)
  content = +<<~MARKDOWN
    # Rendered Verification Clicks

    These WAV files are verification fixtures only. The app synthesizes clicks at runtime and does not bundle these files in the app target.

    Render command:

    ```sh
    ruby Tools/render_click_verification_assets.rb
    ```

    Render settings:

    - Sample rate: #{SAMPLE_RATE} Hz
    - Channel count: #{CHANNEL_COUNT}
    - Bit depth: #{BIT_DEPTH}
    - Master gain: #{MASTER_GAIN}
    - Accent boost: #{ACCENT_BOOST}
    - Waveform: sine oscillator with exponential decay envelope
    - Source parameters: `Tools/render_click_verification_assets.rb` and `Sources/AudioEngine/MetronomeAudioEngine.swift`

    Files:

  MARKDOWN

  files.each do |file|
    content << "- `#{File.basename(file)}`\n"
  end

  File.write(File.join(OUTPUT_DIR, "README.md"), content)
end

FileUtils.rm_rf(OUTPUT_DIR)
FileUtils.mkdir_p(OUTPUT_DIR)

rendered_files = []
PRESETS.each do |preset, profile|
  roles = profile.fetch(:roles).merge(muted: MUTED_ROLE)
  roles.each do |role, parameters|
    samples = render_samples(**parameters, decay_power: profile.fetch(:decay_power))
    filename = "#{preset}-#{role}.wav"
    path = File.join(OUTPUT_DIR, filename)
    File.binwrite(path, wav_bytes(samples))
    rendered_files << path
  end
end

checksums = rendered_files.sort.map do |path|
  "#{Digest::SHA256.file(path).hexdigest}  #{File.basename(path)}"
end
File.write(File.join(OUTPUT_DIR, "SHA256SUMS"), "#{checksums.join("\n")}\n")
write_readme(rendered_files.sort)

puts "Rendered #{rendered_files.count} click verification WAV files to #{OUTPUT_DIR}"
