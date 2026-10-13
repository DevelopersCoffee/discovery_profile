//! Canonical personal-discovery rules.
//!
//! The Dart package `discovery_profile` mirrors these functions.
//! Keep the two implementations aligned.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Confidence {
    Hypothesis,
    Emerging,
    Supported,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PreferenceRelation {
    Compatible,
    ContextDifference,
    Changed,
}

pub fn confidence_for(confirming_sessions: u32, distinct_topics: u32) -> Confidence {
    if distinct_topics >= 3 || (confirming_sessions >= 2 && distinct_topics >= 2) {
        Confidence::Supported
    } else if confirming_sessions >= 1 || distinct_topics >= 2 {
        Confidence::Emerging
    } else {
        Confidence::Hypothesis
    }
}

pub fn insight_allowed(evidence_count: u32) -> bool {
    evidence_count > 0
}

/// A cross-topic link needs enough evidence that it is not created only to
/// provoke another session.
pub fn cross_topic_warranted(topic_count: u32, evidence_count: u32) -> bool {
    topic_count >= 2 && evidence_count >= 3
}

pub fn relate_preferences(
    previous_signal: Option<&str>,
    previous_context: Option<&str>,
    next_signal: Option<&str>,
    next_context: Option<&str>,
) -> PreferenceRelation {
    match (previous_signal, next_signal) {
        (Some(previous), Some(next)) if previous != next => {
            if contexts_differ(previous_context, next_context) {
                PreferenceRelation::ContextDifference
            } else {
                PreferenceRelation::Changed
            }
        }
        _ => PreferenceRelation::Compatible,
    }
}

fn contexts_differ(previous: Option<&str>, next: Option<&str>) -> bool {
    match (previous, next) {
        (Some(left), Some(right)) => left != right && left != "general" && right != "general",
        _ => false,
    }
}

pub fn prompt_allowed(enabled: bool, prompts_today: u32, max_per_day: u32) -> bool {
    enabled && max_per_day > 0 && prompts_today < max_per_day
}

/// Milestones reward exploration. Streaks, missed days, and leaderboards do not.
pub fn milestone_allowed(kind: &str) -> bool {
    !matches!(kind, "missed_day" | "streak" | "leaderboard" | "public_rank")
}

pub fn topic_allowed(topic: &str) -> bool {
    let normalized = topic.to_lowercase();
    let blocked = [
        "sexuality",
        "sexual orientation",
        "gender identity",
        "transgender",
        "religion",
        "religious",
        "politic",
        "ethnicity",
        "ethnic",
        "diagnosis",
        "mental health",
        "depression",
        "anxiety disorder",
        "personality disorder",
    ];
    if blocked.iter().any(|needle| normalized.contains(needle)) {
        return false;
    }
    normalized
        .split(|ch: char| !ch.is_alphanumeric())
        .all(|word| word != "race")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn confidence_matches_the_dart_package() {
        assert_eq!(confidence_for(0, 1), Confidence::Hypothesis);
        assert_eq!(confidence_for(1, 1), Confidence::Emerging);
        assert_eq!(confidence_for(0, 2), Confidence::Emerging);
        assert_eq!(confidence_for(0, 3), Confidence::Supported);
        assert_eq!(confidence_for(2, 2), Confidence::Supported);
    }

    #[test]
    fn refuses_empty_and_weak_cross_topic_links() {
        assert!(!insight_allowed(0));
        assert!(insight_allowed(1));
        assert!(!cross_topic_warranted(2, 2));
        assert!(cross_topic_warranted(2, 3));
        assert!(!cross_topic_warranted(1, 5));
    }

    #[test]
    fn context_is_not_a_contradiction() {
        assert_eq!(
            relate_preferences(Some("quiet_focus"), Some("work"), Some("social_context"), Some("friends")),
            PreferenceRelation::ContextDifference
        );
        assert_eq!(
            relate_preferences(Some("quiet_focus"), Some("home"), Some("social_context"), Some("home")),
            PreferenceRelation::Changed
        );
    }

    #[test]
    fn prompts_and_milestones_stay_optional() {
        assert!(!prompt_allowed(false, 0, 1));
        assert!(!prompt_allowed(true, 1, 1));
        assert!(prompt_allowed(true, 0, 1));
        assert!(!milestone_allowed("streak"));
        assert!(!milestone_allowed("missed_day"));
        assert!(milestone_allowed("first_exploration"));
    }

    #[test]
    fn blocks_sensitive_classification() {
        assert!(!topic_allowed("my political ideology"));
        assert!(!topic_allowed("race and ethnicity"));
        assert!(topic_allowed("Marathi theatre"));
    }
}
