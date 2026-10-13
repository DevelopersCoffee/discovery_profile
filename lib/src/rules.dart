/// Mirrors `rust/dc_discovery_engine`.
library;

enum Confidence { hypothesis, emerging, supported }

enum PreferenceRelation { compatible, contextDifference, changed }

enum QuestionFormat { choice, eitherOr, rating, ranking, scenario, shortText }

enum ConfirmationStatus { proposed, confirmed, corrected, dismissed }

const privacyDisclosure =
    'Your answers, experiences, and profile stay on this device. '
    'This build does not send them to a server, a cloud model, or an advertising network. '
    'Personal discoveries are not sold.';

const changeCopy =
    'This looks different from something you confirmed earlier. '
    'Preferences can change, and a different situation is not a contradiction. '
    'What should we remember?';

const blockedNeedles = <String>[
  'sexuality',
  'sexual orientation',
  'gender identity',
  'transgender',
  'religion',
  'religious',
  'politic',
  'ethnicity',
  'ethnic',
  'diagnosis',
  'mental health',
  'depression',
  'anxiety disorder',
  'personality disorder',
];

const signalPatterns = <String, String>{
  'novelty_with_control':
      'you often prefer something new when the important details stay in your control',
  'immersive': 'you gravitate toward experiences you can step inside',
  'social_context': 'who you are with changes what you enjoy',
  'ritual': 'the ritual and setting matter as much as the thing itself',
  'quiet_focus': 'you prefer quieter, more focused versions of things',
  'story': 'a clear story or idea is what stays with you',
};

bool topicAllowed(String topic) {
  final normalized = topic.toLowerCase();
  if (blockedNeedles.any(normalized.contains)) return false;
  final words = normalized
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty);
  return words.every((word) => word != 'race');
}

Confidence confidenceFor({
  required int confirmingSessions,
  required int distinctTopics,
}) {
  if (distinctTopics >= 3 || (confirmingSessions >= 2 && distinctTopics >= 2)) {
    return Confidence.supported;
  }
  if (confirmingSessions >= 1 || distinctTopics >= 2) {
    return Confidence.emerging;
  }
  return Confidence.hypothesis;
}

bool insightAllowed(int evidenceCount) => evidenceCount > 0;

bool crossTopicWarranted({
  required int topicCount,
  required int evidenceCount,
}) {
  return topicCount >= 2 && evidenceCount >= 3;
}

bool contextsDiffer(String? previous, String? next) {
  if (previous == null || next == null) return false;
  if (previous == 'general' || next == 'general') return false;
  return previous != next;
}

PreferenceRelation relatePreferences({
  required String? previousSignal,
  required String? previousContext,
  required String? nextSignal,
  required String? nextContext,
}) {
  if (previousSignal == null ||
      nextSignal == null ||
      previousSignal == nextSignal) {
    return PreferenceRelation.compatible;
  }
  if (contextsDiffer(previousContext, nextContext)) {
    return PreferenceRelation.contextDifference;
  }
  return PreferenceRelation.changed;
}

bool promptAllowed({
  required bool enabled,
  required int promptsToday,
  required int maxPerDay,
}) {
  return enabled && maxPerDay > 0 && promptsToday < maxPerDay;
}

bool milestoneAllowed(String kind) {
  return kind != 'missed_day' &&
      kind != 'streak' &&
      kind != 'leaderboard' &&
      kind != 'public_rank';
}

String confidenceLabel(Confidence confidence) {
  return switch (confidence) {
    Confidence.hypothesis => 'Hypothesis — an early read',
    Confidence.emerging => 'Emerging pattern',
    Confidence.supported => 'Supported by repeated evidence',
  };
}

String? dominantSignal(List<String> signals) {
  if (signals.isEmpty) return null;
  final counts = <String, int>{};
  for (final signal in signals) {
    counts[signal] = (counts[signal] ?? 0) + 1;
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return ranked.first.key;
}
