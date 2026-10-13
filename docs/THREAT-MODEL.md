# Threat model — personal discovery data

**Status:** Engineering baseline for local-first discovery apps, including 360 Unfold.  
**Scope:** Data the user types or confirms inside a discovery session.

## Assets

- Topic text, answers, ratings, rankings, and short notes
- Experience journal entries
- Profile memories, evidence, confidence, context, and history
- Local metrics (completion, confirmation, meaningful-discovery rate)
- Proactive-prompt settings

## Non-assets

The engine has no fields for name, face, voice, precise location, contacts, or advertising identifiers. It must not gain those fields in order to infer identity.

## Trust boundary

The default boundary is the device. `privacyDisclosure` is the user-facing claim this library is allowed to make: nothing in this package opens a network socket or calls a model API.

An app may add an external model only under a new ADR that names the fields that leave the device and the control that disables that path. Until that ADR exists, apps must not describe processing as “entirely on device” if they add their own network call.

## Threats and controls

| Threat | Control |
|---|---|
| Sensitive identity inferred from a topic string | `topicAllowed` refuses known sensitive categories. Short text is stored as the user's words and is not classified into identity. |
| A flattering or scientific-looking score | Confidence is hypothesis, emerging, or supported. Ratings are preference strength, and the evidence line says they are not certainty. |
| Profile feels like surveillance | Every memory has evidence, history, and delete. `deleteAll` clears experiences, prompts, and metrics intent. |
| Context treated as hypocrisy | Different contexts are `contextDifference`. Change copy does not use moral language. |
| Notification pressure | Prompts require a reason, default to one a day, and can be turned off. Milestones exclude streaks, missed days, and leaderboards. |
| Analytics export | Metrics stay in `DiscoveryDocument` on device. Do not forward them to `airo_analytics` vendor upload. |
| Backup or sync leaks the profile | Out of scope for this library. An app that adds sync must treat the document as sensitive personal data and disclose it. |

## Residual risk

Keyword blocking is not a complete safety classifier. A user can still write sensitive material in a short-text answer. The control there is local storage, visibility, and deletion, not secret inference.

On-device generative models are not part of this version. No “all AI stays on device” claim is made, because this version does not call a model at all.
