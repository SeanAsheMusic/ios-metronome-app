#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'
require 'fileutils'

PROJECT_NAME = 'Metronome'
PROJECT_PATH = "#{PROJECT_NAME}.xcodeproj"
DEPLOYMENT_TARGET = '17.0'

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)

main_group = project.main_group
app_group = main_group.new_group('App', 'App')
sources_group = main_group.new_group('Sources', 'Sources')
tests_group = main_group.new_group('Tests', 'Tests')

rhythm_group = sources_group.new_group('RhythmModel', 'RhythmModel')
audio_group = sources_group.new_group('AudioEngine', 'AudioEngine')
rhythm_tests_group = tests_group.new_group('RhythmModelTests', 'RhythmModelTests')

rhythm_target = project.new_target(:framework, 'RhythmModel', :ios, DEPLOYMENT_TARGET)
audio_target = project.new_target(:framework, 'AudioEngine', :ios, DEPLOYMENT_TARGET)
app_target = project.new_target(:application, 'Metronome', :ios, DEPLOYMENT_TARGET)
tests_target = project.new_target(:unit_test_bundle, 'RhythmModelTests', :ios, DEPLOYMENT_TARGET)

def add_source(group, target, path)
  file = group.new_file(path)
  target.add_file_references([file])
  file
end

add_source(rhythm_group, rhythm_target, 'Sources/RhythmModel/RhythmModel.swift')
add_source(audio_group, audio_target, 'Sources/AudioEngine/MetronomeAudioEngine.swift')
add_source(app_group, app_target, 'App/MetronomeApp.swift')
add_source(app_group, app_target, 'App/MainMetronomeView.swift')
add_source(rhythm_tests_group, tests_target, 'Tests/RhythmModelTests/RhythmModelTests.swift')

audio_target.add_dependency(rhythm_target)
app_target.add_dependency(rhythm_target)
app_target.add_dependency(audio_target)
tests_target.add_dependency(rhythm_target)

app_target.frameworks_build_phase.add_file_reference(rhythm_target.product_reference)
app_target.frameworks_build_phase.add_file_reference(audio_target.product_reference)
audio_target.frameworks_build_phase.add_file_reference(rhythm_target.product_reference)
tests_target.frameworks_build_phase.add_file_reference(rhythm_target.product_reference)

embed_frameworks_phase = app_target.new_copy_files_build_phase('Embed Frameworks')
embed_frameworks_phase.dst_subfolder_spec = '10'
[rhythm_target.product_reference, audio_target.product_reference].each do |framework|
  build_file = embed_frameworks_phase.add_file_reference(framework)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
end

[rhythm_target, audio_target, app_target, tests_target].each do |target|
  target.build_configurations.each do |config|
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    config.build_settings['DEVELOPMENT_TEAM'] = ''
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  end
end

rhythm_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.seanashe.metronome.rhythmmodel'
end

audio_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.seanashe.metronome.audioengine'
end

app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.seanashe.metronome'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
end

tests_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.seanashe.metronome.rhythmmodeltests'
  config.build_settings['TEST_HOST'] = ''
end

project.predictabilize_uuids
project.sort
project.save

metronome_scheme = Xcodeproj::XCScheme.new
metronome_scheme.configure_with_targets(app_target, tests_target)
metronome_scheme.add_build_target(rhythm_target)
metronome_scheme.add_build_target(audio_target)
metronome_scheme.save_as(PROJECT_PATH, 'Metronome', true)

rhythm_scheme = Xcodeproj::XCScheme.new
rhythm_scheme.configure_with_targets(rhythm_target, tests_target)
rhythm_scheme.save_as(PROJECT_PATH, 'RhythmModel', true)
