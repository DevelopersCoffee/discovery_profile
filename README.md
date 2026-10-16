# discovery_profile

Local-first personal discovery for DevelopersCoffee apps. The Dart library is the profile, question, and insight engine. `rust/dc_discovery_engine` is the canonical rule set the Dart code mirrors.

360 Unfold consumes this package. Other products can reuse the same document, evidence rules, and memory controls.

## Install

```yaml
dependencies:
  discovery_profile: ^0.2.0
```

## Requirement map

| Requirement | API |
|---|---|
| User-defined topics | `DiscoveryEngine.proposeFraming`, `editFraming` |
| Adaptive questions, every format | `nextQuestion`, `QuestionFormat` |
| Experience journal | `saveExperience`, `deleteExperience` |
| Profile fields and history | `Memory` |
| Evidence and confidence | `draftFromResponses`, `confidenceLabel` |
| Context versus contradiction | `relatePreferences` |
| Change without judgment | `changeCopy`, `resolve(changeNote:)` |
| Cross-topic links | `crossTopicWarranted` |
| Proactive prompts | `nextProactive`, `promptAllowed` |
| Memory controls | `markTemporary`, `editContext`, `deleteMemory`, `deleteAll` |
| Optional milestones | `freshMilestones`, `milestoneAllowed` |
| Meaningful-discovery metrics | `DiscoveryEngine.metrics` |
| Sensitive-topic refusal | `topicAllowed` |
| Spectrum topics ("how vegetarian am I?") | `starterSpectra`, `scoreSpectrum`, `spectrumExplanation` |
| Own spectrum topics and model drafts | `validateSpectrumTopic`, `saveSpectrumTopic`, `spectrumTopicFromSuggestion` |
| Spectrum term corrections | `correctSpectrumTerm`, `confirmSpectrum`, `deleteSpectrumReading` |

The package does not diagnose health, infer sensitive identity, rank people, require an account, or charge money.

## Rules shared with Rust

`confidence_for`, `cross_topic_warranted`, `relate_preferences`, `prompt_allowed`, `milestone_allowed`, `topic_allowed`, `spectrum_position`, `spectrum_band`, `spectrum_confidence`, and `spectrum_allowed` match `dc_discovery_engine`.

## Spectrum scoring

A spectrum topic places a person between two ends from their own answers. Each answer carries a visible weight from 0 to 100, and the position is the rounded integer mean of the answered weights, so the same answers always give the same position on every platform. Skipped questions are left out. Bands can name the position ("flexitarian") as a suggestion the person can replace with their own word. A model may draft a topic's questions and weights through `spectrumTopicFromSuggestion`, but the draft must pass `validateSpectrumTopic` (including the sensitive-topic refusal on the label, both ends, questions, and band names) and the person's review before it is saved. A model never computes a position.

```bash
dart test
cargo test --manifest-path rust/dc_discovery_engine/Cargo.toml
```
