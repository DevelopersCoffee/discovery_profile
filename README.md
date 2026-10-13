# discovery_profile

Local-first personal discovery for DevelopersCoffee apps. The Dart library is the profile, question, and insight engine. `rust/dc_discovery_engine` is the canonical rule set the Dart code mirrors.

360 Unfold consumes this package. Other products can reuse the same document, evidence rules, and memory controls.

## Install

```yaml
dependencies:
  discovery_profile: ^0.1.1
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

The package does not diagnose health, infer sensitive identity, rank people, require an account, or charge money.

## Rules shared with Rust

`confidence_for`, `cross_topic_warranted`, `relate_preferences`, `prompt_allowed`, `milestone_allowed`, and `topic_allowed` match `dc_discovery_engine`.

```bash
dart test
cargo test --manifest-path rust/dc_discovery_engine/Cargo.toml
```
