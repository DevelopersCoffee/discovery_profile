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

/// Lowest and highest weight an answer can place on a spectrum.
const spectrumMin = 0;
const spectrumMax = 100;

/// Rounded mean of the chosen answer weights, in integers so it matches
/// `dc_discovery_engine` exactly. Skipped questions are left out. `null`
/// means nothing was answered. The position describes the person's own
/// answers and is never compared with other people.
int? spectrumPosition(List<int> weights) {
  if (weights.isEmpty) return null;
  final count = weights.length;
  var sum = 0;
  for (final weight in weights) {
    sum += weight.clamp(spectrumMin, spectrumMax);
  }
  return (2 * sum + count) ~/ (2 * count);
}

/// Index of the first band whose inclusive upper bound contains [position].
int? spectrumBand(int position, List<int> upperBounds) {
  for (var index = 0; index < upperBounds.length; index++) {
    if (position <= upperBounds[index]) return index;
  }
  return null;
}

/// Three answered questions make a spectrum read emerging. A later session
/// that lands in the same band makes it supported.
Confidence spectrumConfidence({
  required int answered,
  required int confirmingSessions,
}) {
  if (answered >= 3 && confirmingSessions >= 1) return Confidence.supported;
  if (answered >= 3) return Confidence.emerging;
  return Confidence.hypothesis;
}

/// A spectrum topic, including one a person or a model writes, must pass the
/// sensitive-topic refusal on its label and on both ends of the scale.
bool spectrumAllowed({
  required String label,
  required String lowLabel,
  required String highLabel,
}) {
  return topicAllowed(label) &&
      topicAllowed(lowLabel) &&
      topicAllowed(highLabel);
}
