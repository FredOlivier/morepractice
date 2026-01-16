# Morepractice — Founder Context

## What we are building
Morepractice is an iOS app focused on deep learning via single-topic feeds,
high-quality quizzes, media, and social presence (WebRTC links).

## Architecture
- Xcode project: Morepractice
- MediaLab: dev-only iOS target for media rendering truth
- MediaKit: Swift Package (Library + XCTest)
- Firebase backend
- WebRTC submodule

## Dev system
- Parallel work via git worktrees
- One stream per surface area
- Agents follow AGENTS.md
- Gates: xcodebuild + swift test

## Current streams
(keep updated)
- Media formatting: mp-media-lab
- Caching: mp-caching
- Feeds: mp-feeds
- WebRTC: mp-webrtc
- …

## Ground rules
- Never trust previews outside Xcode
- Media decisions validated in MediaLab
- Merge only green gates

