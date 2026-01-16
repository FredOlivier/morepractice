# Morepractice — Codex Operating Manual (MVP)

## Ground rules (non-negotiable)
- Make the smallest safe change. Small diffs.
- Touch only files needed for the task.
- No sweeping refactors. No new dependencies unless explicitly requested.
- Never invent APIs. If unsure, search the repo and STOP at a checkpoint.
- After each change: run the gate commands. If they fail: fix -> rerun until green.
- STOP at checkpoints: PLAN -> IMPLEMENTED -> GATE -> PR READY.

## Checkpoints (stop points)
1) PLAN: summarize approach + list files to touch
2) IMPLEMENTED: describe what changed
3) GATE: run commands + summarize results
4) PR READY: summary, manual test steps, risks, rollout notes

## Repo facts
- Xcode project
- Scheme: Morepractice
- Uses Swift Packages: YES
- Firebase: YES
- WebRTC: YES

## Gate commands (do not skip)
- List schemes if needed: xcodebuild -list
- iOS build gate:
  xcodebuild -scheme "Morepractice" -destination 'platform=iOS Simulator,name=iPhone 15' build
- If working in Swift packages:
  swift test -c debug

## Streams (do not cross streams unless told)
A) Media formatting & caching (+ MediaLab side app)
B) WebRTC video links reliability
C) Single-topic feed (facts + questions + scoring)
D) Quiz generation/tuning harness
E) Scraping + ingestion pipeline

## “Ask me” triggers (stop instead of guessing)
- anything touching Firebase schema/migrations
- WebRTC signaling protocol changes
- adding new third-party libraries
- major UI navigation rewrites

