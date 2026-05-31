#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'zlib'

ICON_DIR = File.expand_path('../App/Assets.xcassets/AppIcon.appiconset', __dir__)

ICONS = {
  'AppIcon-20@2x.png' => 40,
  'AppIcon-20@3x.png' => 60,
  'AppIcon-29@2x.png' => 58,
  'AppIcon-29@3x.png' => 87,
  'AppIcon-40@2x.png' => 80,
  'AppIcon-40@3x.png' => 120,
  'AppIcon-60@2x.png' => 120,
  'AppIcon-60@3x.png' => 180,
  'AppIcon-20@1x-ipad.png' => 20,
  'AppIcon-20@2x-ipad.png' => 40,
  'AppIcon-29@1x-ipad.png' => 29,
  'AppIcon-29@2x-ipad.png' => 58,
  'AppIcon-40@1x-ipad.png' => 40,
  'AppIcon-40@2x-ipad.png' => 80,
  'AppIcon-76@1x.png' => 76,
  'AppIcon-76@2x.png' => 152,
  'AppIcon-83.5@2x.png' => 167,
  'AppIcon-1024.png' => 1024
}.freeze

def chunk(type, data)
  [data.bytesize].pack('N') + type + data + [Zlib.crc32(type + data)].pack('N')
end

def pixel(size, x, y)
  center = (size - 1) / 2.0
  dx = (x - center).abs / center
  dy = (y - center).abs / center
  distance = Math.sqrt((dx * dx) + (dy * dy))

  if distance > 0.92
    [12, 15, 18, 255]
  elsif (x - center).abs < size * 0.045 || (y - center).abs < size * 0.045
    [230, 246, 238, 255]
  elsif ((x - center).abs % [size * 0.18, 1].max) < size * 0.018
    [44, 192, 132, 255]
  else
    shade = (42 + (1.0 - distance) * 72).round
    [shade, shade + 22, shade + 18, 255]
  end
end

def png(size)
  rows = (0...size).map do |y|
    row = (0...size).flat_map { |x| pixel(size, x, y) }.pack('C*')
    "\x00".b + row
  end.join

  signature = "\x89PNG\r\n\x1A\n".b
  ihdr = [size, size, 8, 6, 0, 0, 0].pack('NNCCCCC')
  signature + chunk('IHDR', ihdr) + chunk('IDAT', Zlib::Deflate.deflate(rows, Zlib::BEST_COMPRESSION)) + chunk('IEND', ''.b)
end

FileUtils.mkdir_p(ICON_DIR)
ICONS.each do |filename, size|
  File.binwrite(File.join(ICON_DIR, filename), png(size))
end
