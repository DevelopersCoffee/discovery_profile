## 0.2.0

- Spectrum topics: deterministic position from visible answer weights, optional band terms the person can correct, confidence from answered questions and repeat sessions, and history across sessions.
- Own spectrum topics and model-drafted topics go through the same validation, including the sensitive-topic refusal.
- `DiscoveryDocument` stores spectrum topics and readings. Older documents without them still load. `deleteAll` clears them.
- `dc_discovery_engine` 0.2.0 adds `spectrum_position`, `spectrum_band`, `spectrum_confidence`, and `spectrum_allowed`.

## 0.1.2

- New evidence updates the same memory. A different situation stays context, and a same-situation difference is recorded as a change.
- Explorations can be started and left unfinished, so completion rate is separate from the meaningful-discovery rate.
- Question depth can limit how many prompts one exploration asks.

## 0.1.1

- Cross-topic engagement is counted when someone opens a connection, not merely because one exists.

## 0.1.0

- Local personal-discovery document: topics, adaptive questions, experiences, evidence, confidence, context, and history.
- Sensitive-identity topics are refused. Insights require evidence and never use a numeric certainty score.
- Cross-topic links require two topics and at least three pieces of evidence.
- Proactive prompts are optional, explained, and capped. Gamification has no streaks, missed-day shame, or leaderboards.
