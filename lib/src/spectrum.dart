import 'engine.dart';
import 'models.dart';
import 'rules.dart';

/// Where a spectrum topic came from. Model suggestions are drafts the person
/// accepts or edits; they never score anything themselves.
enum SpectrumSource { builtIn, user, model }

class SpectrumOption {
  const SpectrumOption({required this.label, required this.weight});

  final String label;

  /// Position this answer points to, from [spectrumMin] (the low end) to
  /// [spectrumMax] (the high end).
  final int weight;

  Map<String, Object?> toJson() => {'label': label, 'weight': weight};

  static SpectrumOption fromJson(Map<String, Object?> json) => SpectrumOption(
    label: json['label']! as String,
    weight: json['weight']! as int,
  );
}

class SpectrumQuestion {
  const SpectrumQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final String id;
  final String text;
  final List<SpectrumOption> options;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'options': options.map((item) => item.toJson()).toList(),
  };

  static SpectrumQuestion fromJson(Map<String, Object?> json) =>
      SpectrumQuestion(
        id: json['id']! as String,
        text: json['text']! as String,
        options: (json['options']! as List)
            .map(
              (item) => SpectrumOption.fromJson(
                (item as Map).cast<String, Object?>(),
              ),
            )
            .toList(),
      );
}

/// A named stretch of the spectrum, such as "flexitarian". [upper] is the
/// inclusive upper bound of the band.
class SpectrumBand {
  const SpectrumBand({required this.upper, required this.term});

  final int upper;
  final String term;

  Map<String, Object?> toJson() => {'upper': upper, 'term': term};

  static SpectrumBand fromJson(Map<String, Object?> json) =>
      SpectrumBand(upper: json['upper']! as int, term: json['term']! as String);
}

class SpectrumTopic {
  const SpectrumTopic({
    required this.id,
    required this.label,
    required this.lowLabel,
    required this.highLabel,
    required this.questions,
    this.bands = const [],
    this.source = SpectrumSource.user,
  });

  final String id;
  final String label;
  final String lowLabel;
  final String highLabel;
  final List<SpectrumQuestion> questions;
  final List<SpectrumBand> bands;
  final SpectrumSource source;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'lowLabel': lowLabel,
    'highLabel': highLabel,
    'questions': questions.map((item) => item.toJson()).toList(),
    'bands': bands.map((item) => item.toJson()).toList(),
    'source': source.name,
  };

  static SpectrumTopic fromJson(Map<String, Object?> json) => SpectrumTopic(
    id: json['id']! as String,
    label: json['label']! as String,
    lowLabel: json['lowLabel']! as String,
    highLabel: json['highLabel']! as String,
    questions: (json['questions']! as List)
        .map(
          (item) =>
              SpectrumQuestion.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList(),
    bands: (json['bands'] as List? ?? const [])
        .map(
          (item) =>
              SpectrumBand.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList(),
    source: SpectrumSource.values.byName(json['source'] as String? ?? 'user'),
  );
}

/// One spectrum result for one topic. A new session on the same topic
/// replaces the position and keeps the earlier ones in [history].
class SpectrumReading {
  SpectrumReading({
    required this.topicId,
    required this.topicLabel,
    required this.position,
    required this.answered,
    required this.skipped,
    required this.evidence,
    required this.confidence,
    required this.updatedAt,
    this.term,
    this.userTerm,
    this.confirmingSessions = 0,
    this.status = ConfirmationStatus.proposed,
    List<SpectrumHistory>? history,
  }) : history = history ?? [];

  final String topicId;
  final String topicLabel;
  int position;
  int answered;
  int skipped;
  List<EvidenceRef> evidence;
  Confidence confidence;
  DateTime updatedAt;

  /// The engine's suggested term for this band, if the topic names one.
  String? term;

  /// The person's own word for where they sit, if they corrected [term].
  String? userTerm;
  int confirmingSessions;
  ConfirmationStatus status;
  final List<SpectrumHistory> history;

  String? get shownTerm => userTerm ?? term;

  Map<String, Object?> toJson() => {
    'topicId': topicId,
    'topicLabel': topicLabel,
    'position': position,
    'answered': answered,
    'skipped': skipped,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'confidence': confidence.name,
    'updatedAt': updatedAt.toIso8601String(),
    'term': term,
    'userTerm': userTerm,
    'confirmingSessions': confirmingSessions,
    'status': status.name,
    'history': history.map((item) => item.toJson()).toList(),
  };

  static SpectrumReading fromJson(Map<String, Object?> json) => SpectrumReading(
    topicId: json['topicId']! as String,
    topicLabel: json['topicLabel']! as String,
    position: json['position']! as int,
    answered: json['answered']! as int,
    skipped: json['skipped']! as int,
    evidence: (json['evidence']! as List)
        .map(
          (item) => EvidenceRef.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList(),
    confidence: Confidence.values.byName(json['confidence']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
    term: json['term'] as String?,
    userTerm: json['userTerm'] as String?,
    confirmingSessions: json['confirmingSessions'] as int? ?? 0,
    status: ConfirmationStatus.values.byName(
      json['status'] as String? ?? 'proposed',
    ),
    history: (json['history'] as List? ?? const [])
        .map(
          (item) =>
              SpectrumHistory.fromJson((item as Map).cast<String, Object?>()),
        )
        .toList(),
  );
}

class SpectrumHistory {
  const SpectrumHistory({required this.at, required this.position});

  final DateTime at;
  final int position;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'position': position,
  };

  static SpectrumHistory fromJson(Map<String, Object?> json) => SpectrumHistory(
    at: DateTime.parse(json['at']! as String),
    position: json['position']! as int,
  );
}

/// Spectrum topics: "how vegetarian am I?" answered as a position between
/// two ends, with transparent weights and an optional term for the band.
extension SpectrumScoring on DiscoveryEngine {
  /// Problems that keep a topic from being saved or scored. Empty means valid.
  /// Model suggestions go through the same check as hand-written topics.
  List<String> validateSpectrumTopic(SpectrumTopic topic) {
    final problems = <String>[];
    if (topic.label.trim().length < 3) {
      problems.add('Give the topic a name.');
    }
    if (topic.lowLabel.trim().isEmpty || topic.highLabel.trim().isEmpty) {
      problems.add('Name both ends of the spectrum.');
    }
    if (!spectrumAllowed(
      label: topic.label,
      lowLabel: topic.lowLabel,
      highLabel: topic.highLabel,
    )) {
      problems.add(
        'Unfold does not place people on spectrums of sensitive identity or health.',
      );
    }
    if (topic.questions.isEmpty) problems.add('Add at least one question.');
    final ids = <String>{};
    for (final question in topic.questions) {
      if (!ids.add(question.id)) {
        problems.add('Question ids must be unique.');
      }
      if (!topicAllowed(question.text)) {
        problems.add('A question asks about sensitive identity or health.');
      }
      if (question.options.length < 2) {
        problems.add('“${question.text}” needs at least two answers.');
      }
      for (final option in question.options) {
        if (option.weight < spectrumMin || option.weight > spectrumMax) {
          problems.add('Answer weights must be between 0 and 100.');
        }
      }
    }
    var previous = -1;
    for (final band in topic.bands) {
      if (band.upper <= previous || band.upper > spectrumMax) {
        problems.add('Bands must go up in order and end at 100.');
      }
      if (!topicAllowed(band.term)) {
        problems.add('A band name refers to sensitive identity or health.');
      }
      previous = band.upper;
    }
    if (topic.bands.isNotEmpty && topic.bands.last.upper != spectrumMax) {
      problems.add('Bands must go up in order and end at 100.');
    }
    return problems.toSet().toList();
  }

  /// Saves a topic the person wrote or accepted. Returns the problems instead
  /// when it is not valid.
  List<String> saveSpectrumTopic(
    DiscoveryDocument document,
    SpectrumTopic topic,
  ) {
    final problems = validateSpectrumTopic(topic);
    if (problems.isNotEmpty) return problems;
    document.spectrumTopics
      ..removeWhere((item) => item.id == topic.id)
      ..add(topic);
    return const [];
  }

  void deleteSpectrumTopic(DiscoveryDocument document, String topicId) {
    document.spectrumTopics.removeWhere((item) => item.id == topicId);
    document.spectra.removeWhere((item) => item.topicId == topicId);
  }

  /// Scores one session. [choices] maps a question id to the chosen option
  /// index, or to `null` when the person skipped it. Returns `null` when
  /// nothing was answered: there is no evidence to place anyone.
  SpectrumReading? scoreSpectrum(
    DiscoveryDocument document,
    SpectrumTopic topic,
    Map<String, int?> choices, {
    DateTime? at,
  }) {
    if (validateSpectrumTopic(topic).isNotEmpty) return null;
    final now = at ?? DateTime.now();
    final weights = <int>[];
    final evidence = <EvidenceRef>[];
    var skipped = 0;
    for (final question in topic.questions) {
      if (!choices.containsKey(question.id)) continue;
      final index = choices[question.id];
      if (index == null || index < 0 || index >= question.options.length) {
        skipped++;
        continue;
      }
      final option = question.options[index];
      weights.add(option.weight);
      evidence.add(
        EvidenceRef(
          summary:
              'You answered “${option.label}” to “${question.text}” '
              '(${option.weight} of $spectrumMax toward ${topic.highLabel})',
          source: 'spectrum',
        ),
      );
    }
    final position = spectrumPosition(weights);
    if (position == null || !insightAllowed(evidence.length)) return null;
    final bandIndex = spectrumBand(position, [
      for (final band in topic.bands) band.upper,
    ]);
    final term = bandIndex == null ? null : topic.bands[bandIndex].term;

    final existing = spectrumFor(document, topic.id);
    if (existing == null) {
      final reading = SpectrumReading(
        topicId: topic.id,
        topicLabel: topic.label,
        position: position,
        answered: weights.length,
        skipped: skipped,
        evidence: evidence,
        confidence: spectrumConfidence(
          answered: weights.length,
          confirmingSessions: 0,
        ),
        updatedAt: now,
        term: term,
      );
      document.spectra.add(reading);
      return reading;
    }

    final upperBounds = topic.bands.map((band) => band.upper).toList();
    final sameBand = upperBounds.isEmpty
        ? (existing.position - position).abs() <= 10
        : spectrumBand(existing.position, upperBounds) == bandIndex;
    existing.history.add(
      SpectrumHistory(at: existing.updatedAt, position: existing.position),
    );
    existing
      ..position = position
      ..answered = weights.length
      ..skipped = skipped
      ..evidence = evidence
      ..term = term
      ..updatedAt = now
      ..confirmingSessions = sameBand ? existing.confirmingSessions + 1 : 0
      ..status = ConfirmationStatus.proposed;
    if (!sameBand) existing.userTerm = null;
    existing.confidence = spectrumConfidence(
      answered: existing.answered,
      confirmingSessions: existing.confirmingSessions,
    );
    return existing;
  }

  SpectrumReading? spectrumFor(DiscoveryDocument document, String topicId) {
    for (final reading in document.spectra) {
      if (reading.topicId == topicId) return reading;
    }
    return null;
  }

  /// Plain-language result built only from the reading. A model may reword
  /// this text, but the numbers and term always come from here.
  String spectrumExplanation(SpectrumTopic topic, SpectrumReading reading) {
    final where = reading.position <= 33
        ? 'closer to ${topic.lowLabel}'
        : reading.position >= 67
        ? 'closer to ${topic.highLabel}'
        : 'between ${topic.lowLabel} and ${topic.highLabel}';
    final term = reading.shownTerm;
    final named = term == null
        ? ''
        : reading.userTerm != null
        ? ' You call this “$term”.'
        : ' People often call this “$term”. It is a word, not a box: '
              'change it if it does not fit.';
    return 'Your ${reading.answered} answer(s) place you at '
        '${reading.position} of $spectrumMax, $where.$named';
  }

  void confirmSpectrum(SpectrumReading reading) {
    reading.status = ConfirmationStatus.confirmed;
  }

  /// The person's own word replaces the suggested term. An empty word clears
  /// the correction.
  void correctSpectrumTerm(SpectrumReading reading, String word) {
    final trimmed = word.trim();
    reading
      ..userTerm = trimmed.isEmpty ? null : trimmed
      ..status = trimmed.isEmpty
          ? ConfirmationStatus.proposed
          : ConfirmationStatus.corrected;
  }

  void deleteSpectrumReading(DiscoveryDocument document, String topicId) {
    document.spectra.removeWhere((item) => item.topicId == topicId);
  }

  /// Turns a model's JSON suggestion into a draft topic. Weights are clamped,
  /// ids are assigned here, and the draft still has to pass
  /// [validateSpectrumTopic] and the person's review before it is saved.
  /// Returns `null` when the suggestion is not usable.
  SpectrumTopic? spectrumTopicFromSuggestion(
    Map<String, Object?> json, {
    required String id,
  }) {
    try {
      final rawQuestions = json['questions'];
      if (rawQuestions is! List) return null;
      final questions = <SpectrumQuestion>[];
      for (final (index, raw) in rawQuestions.indexed) {
        if (raw is! Map) continue;
        final options = <SpectrumOption>[];
        for (final option in (raw['options'] as List? ?? const [])) {
          if (option is! Map) continue;
          final label = option['label'];
          final weight = option['weight'];
          if (label is! String || weight is! num) continue;
          options.add(
            SpectrumOption(
              label: label.trim(),
              weight: weight.round().clamp(spectrumMin, spectrumMax),
            ),
          );
        }
        final text = raw['text'];
        if (text is! String || options.length < 2) continue;
        questions.add(
          SpectrumQuestion(
            id: '$id-q$index',
            text: text.trim(),
            options: options,
          ),
        );
      }
      final bands = <SpectrumBand>[];
      for (final raw in (json['bands'] as List? ?? const [])) {
        if (raw is! Map) continue;
        final upper = raw['upper'];
        final term = raw['term'];
        if (upper is! num || term is! String) continue;
        bands.add(
          SpectrumBand(
            upper: upper.round().clamp(spectrumMin, spectrumMax),
            term: term.trim(),
          ),
        );
      }
      bands.sort((a, b) => a.upper.compareTo(b.upper));
      final draft = SpectrumTopic(
        id: id,
        label: (json['label'] as String? ?? '').trim(),
        lowLabel: (json['lowLabel'] as String? ?? '').trim(),
        highLabel: (json['highLabel'] as String? ?? '').trim(),
        questions: questions,
        bands: bands,
        source: SpectrumSource.model,
      );
      return validateSpectrumTopic(draft).isEmpty ? draft : null;
    } on Object {
      return null;
    }
  }
}
