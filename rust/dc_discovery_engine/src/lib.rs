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

/// Lowest and highest weight an answer can place on a spectrum.
pub const SPECTRUM_MIN: u32 = 0;
pub const SPECTRUM_MAX: u32 = 100;

/// Where someone sits on a spectrum topic, from the weights of the answers
/// they chose. It is the rounded mean, computed in integers so every platform
/// gets the same number. Skipped questions are not passed in. `None` means
/// nothing was answered yet. The position describes the person's own answers;
/// it is never compared with other people.
pub fn spectrum_position(weights: &[u32]) -> Option<u32> {
    if weights.is_empty() {
        return None;
    }
    let count = weights.len() as u64;
    let sum: u64 = weights
        .iter()
        .map(|weight| u64::from((*weight).min(SPECTRUM_MAX)))
        .sum();
    // Round half up: (2 * sum + count) / (2 * count).
    Some(((2 * sum + count) / (2 * count)) as u32)
}

/// The term for a position. `bands` holds the inclusive upper bound of each
/// band in ascending order; the last band should end at `SPECTRUM_MAX`.
/// Returns the index of the first band that contains the position.
pub fn spectrum_band(position: u32, upper_bounds: &[u32]) -> Option<usize> {
    upper_bounds.iter().position(|upper| position <= *upper)
}

/// A spectrum read starts as a hypothesis. Three answered questions make it
/// emerging, and a later session that lands in the same band makes it
/// supported.
pub fn spectrum_confidence(answered: u32, confirming_sessions: u32) -> Confidence {
    if answered >= 3 && confirming_sessions >= 1 {
        Confidence::Supported
    } else if answered >= 3 {
        Confidence::Emerging
    } else {
        Confidence::Hypothesis
    }
}

/// A spectrum topic, including one a person or a model writes, must pass the
/// sensitive-topic refusal on its label and on both ends of the scale.
pub fn spectrum_allowed(label: &str, low_label: &str, high_label: &str) -> bool {
    topic_allowed(label) && topic_allowed(low_label) && topic_allowed(high_label)
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

    #[test]
    fn spectrum_scoring_is_deterministic() {
        assert_eq!(spectrum_position(&[]), None);
        assert_eq!(spectrum_position(&[0, 100]), Some(50));
        assert_eq!(spectrum_position(&[0, 0, 1]), Some(0));
        assert_eq!(spectrum_position(&[0, 1]), Some(1));
        assert_eq!(spectrum_position(&[10, 20, 25]), Some(18));
        assert_eq!(spectrum_position(&[250]), Some(100));
        assert_eq!(spectrum_band(0, &[9, 29, 49, 100]), Some(0));
        assert_eq!(spectrum_band(30, &[9, 29, 49, 100]), Some(2));
        assert_eq!(spectrum_band(100, &[9, 29, 49, 100]), Some(3));
        assert_eq!(spectrum_band(100, &[9, 29]), None);
    }

    #[test]
    fn spectrum_confidence_needs_answers_then_a_return() {
        assert_eq!(spectrum_confidence(2, 3), Confidence::Hypothesis);
        assert_eq!(spectrum_confidence(3, 0), Confidence::Emerging);
        assert_eq!(spectrum_confidence(4, 1), Confidence::Supported);
    }

    #[test]
    fn spectrum_refuses_sensitive_scales() {
        assert!(spectrum_allowed("How vegetarian am I?", "Plant-based", "Meat-heavy"));
        assert!(!spectrum_allowed("How ethnic am I?", "Not at all", "Very"));
        assert!(!spectrum_allowed("Food", "Religious", "Secular"));
    }
}
