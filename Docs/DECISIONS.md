# Decisions

## D001: V1 Is Local-First And Account-Free

The research repeatedly flags trust, lost libraries, ads, subscriptions, and nag prompts as market pain. V1 will not include accounts, ads, tracking, subscriptions, or cloud-only workflows.

## D002: SwiftUI First, iOS 17+ Baseline

The app should feel native by using system structures: SwiftUI, semantic colors, Dynamic Type, VoiceOver, safe areas, scene-aware layout, and first-party testing. UIKit remains a fallback only for clear platform gaps.

## D003: Audio Claims Require Measurement

The repository will not claim precise or stage-safe audio timing until AVFoundation scheduling is implemented and measured on physical devices.

## D004: Synthesized Clicks Only Unless Rights Are Explicit

DAW/system sounds are treated as references. V1 sound assets must be synthesized at runtime or generated from source-controlled DSP parameters with provenance. Current preset parameters are documented in `SoundLibrary/PROVENANCE.md`.

## D005: Multi-Lane Rhythm Is The Long-Term Model

The safe v1 layer starts with patterns and beats, but the architecture should not block independent lanes for pulse, subdivision, clave, count, trainer, haptics, visuals, and cues.
