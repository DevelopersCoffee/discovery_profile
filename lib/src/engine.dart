import 'catalog.dart';
import 'models.dart';
import 'rules.dart';

class DiscoveryEngine {
  const DiscoveryEngine();

  TopicFraming proposeFraming(String raw) {
    final label = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (label.length < 3) {
      return const TopicFraming(
        label: '',
        dimensions: [],
        needsClarification: true,
        clarification: 'Say a little more about what you want to understand.',
      );
    }
    if (!topicAllowed(label)) {
      return const TopicFraming(
        label: '',
        dimensions: [],
        needsClarification: true,
        clarification:
            'Unfold does not classify sensitive identity or health. Try a preference such as movies, food, travel, or how you like to spend time.',
      );
    }
    const broad = {
      'life',
      'me',
      'myself',
      'everything',
      'stuff',
      'things',
      'all',
      'person',
      'personality',
    };
    if (broad.contains(label.toLowerCase())) {
      return TopicFraming(
        label: label,
        dimensions: const [],
        needsClarification: true,
        clarification:
            'That is a wide question. Which part do you want to look at?',
      );
    }
    final lower = label.toLowerCase();
    final dimensions = <String>[];
    const keywords = {
      'movie': ['story', 'mood', 'company'],
      'film': ['story', 'mood', 'company'],
      'coffee': ['ritual', 'context', 'taste'],
      'chai': ['ritual', 'context', 'taste'],
      'tea': ['ritual', 'context', 'taste'],
      'travel': ['planning', 'company', 'novelty'],
      'trip': ['planning', 'company', 'novelty'],
      'talk': ['channel', 'context', 'pace'],
      'text': ['channel', 'context', 'pace'],
      'hobby': ['activity', 'depth', 'company'],
      'learn': ['method', 'pace', 'company'],
      'music': ['lyrics', 'atmosphere', 'setting'],
      'night': ['energy', 'context', 'ritual'],
      'morning': ['energy', 'context', 'ritual'],
    };
    for (final entry in keywords.entries) {
      if (lower.contains(entry.key)) dimensions.addAll(entry.value);
    }
    if (dimensions.isEmpty) {
      dimensions.addAll([
        'what you reach for',
        'when it depends',
        'what stays with you',
      ]);
    }
    return TopicFraming(
      label: label,
      dimensions: dimensions.toSet().toList(),
      needsClarification: false,
    );
  }

  TopicFraming editFraming(
    TopicFraming framing, {
    String? label,
    List<String>? rejectedDimensions,
  }) {
    final nextLabel = label?.trim().isNotEmpty == true
        ? label!.trim()
        : framing.label;
    final rejected = rejectedDimensions?.toSet() ?? {};
    return TopicFraming(
      label: nextLabel,
      dimensions: framing.dimensions
          .where((item) => !rejected.contains(item))
          .toList(),
      needsClarification: framing.needsClarification,
      clarification: framing.clarification,
    );
  }

  DiscoveryQuestion? nextQuestion({
    required DiscoveryTopic topic,
    required Map<String, DiscoveryResponse> answers,
    required DiscoveryDocument document,
  }) {
    for (final question in topic.questions) {
      if (answers.containsKey(question.id)) continue;
      if (!question.available(answers)) continue;
      if (_alreadyKnown(document, topic.id, question.dimension)) continue;
      return question;
    }
    return null;
  }

  bool _alreadyKnown(
    DiscoveryDocument document,
    String topicId,
    String dimension,
  ) {
    return document.memories.any(
      (memory) =>
          memory.topicId == topicId &&
          memory.dimension == dimension &&
          !memory.temporary &&
          !memory.crossTopic &&
          (memory.status == ConfirmationStatus.confirmed ||
              memory.status == ConfirmationStatus.corrected),
    );
  }

  DiscoveryResponse answerQuestion(
    DiscoveryQuestion question,
    List<String> values,
  ) {
    final signals = <String>[];
    if (question.format == QuestionFormat.rating) {
      final score = int.tryParse(values.isEmpty ? '' : values.first) ?? 0;
      final signal = question.scaleSignal;
      if (signal != null && score >= 4) signals.add(signal);
    } else if (question.format == QuestionFormat.ranking) {
      if (values.isNotEmpty) {
        final first = question.options
            .where((option) => option.value == values.first)
            .firstOrNull;
        if (first != null) signals.addAll(first.signals);
      }
    } else if (question.format != QuestionFormat.shortText) {
      for (final value in values) {
        final option = question.options
            .where((item) => item.value == value)
            .firstOrNull;
        if (option != null) signals.addAll(option.signals);
      }
    }
    return DiscoveryResponse(
      questionId: question.id,
      prompt: question.text,
      format: question.format,
      values: values,
      signals: signals,
    );
  }

  DiscoveryResponse skipQuestion(DiscoveryQuestion question) {
    return DiscoveryResponse(
      questionId: question.id,
      prompt: question.text,
      format: question.format,
      values: const [],
      skipped: true,
    );
  }

  InsightDraft? draftFromResponses({
    required DiscoveryTopic topic,
    required String topicLabel,
    required Map<String, DiscoveryResponse> answers,
    String contextLabel = 'general',
  }) {
    final evidence = <EvidenceRef>[];
    final signals = <String>[];
    for (final question in topic.questions) {
      final response = answers[question.id];
      if (response == null || response.skipped) continue;
      final summary = _evidenceSummary(question, response);
      if (summary == null) continue;
      evidence.add(EvidenceRef(summary: summary, source: 'answer'));
      signals.addAll(response.signals);
    }
    return _draft(
      topicId: topic.id,
      topicLabel: topicLabel,
      dimension: _primaryDimension(topic, answers),
      evidence: evidence,
      signals: signals,
      confirmingSessions: 0,
      distinctTopics: 1,
      contextLabel: contextLabel,
    );
  }

  InsightDraft? draftFromExperience({
    required String experienceId,
    required String text,
    String? reflectionValue,
  }) {
    final excerpt = text.trim();
    final shown = excerpt.length > 140
        ? '${excerpt.substring(0, 137)}...'
        : excerpt;
    final evidence = [
      EvidenceRef(
        summary: 'You wrote “$shown”',
        source: 'experience',
        experienceId: experienceId,
      ),
    ];
    final signals = <String>[];
    if (reflectionValue != null) {
      final choice = experienceReflection.options
          .where((item) => item.value == reflectionValue)
          .firstOrNull;
      if (choice != null) {
        evidence.add(
          EvidenceRef(
            summary: 'You said what stood out was “${choice.label}”',
            source: 'experience',
            experienceId: experienceId,
          ),
        );
        signals.addAll(choice.signals);
      }
    }
    if (signals.isEmpty) return null;
    return _draft(
      topicId: 'experience',
      topicLabel: 'A recent experience',
      dimension: 'experience',
      evidence: evidence,
      signals: signals,
      confirmingSessions: 0,
      distinctTopics: 1,
      contextLabel: 'general',
      experienceId: experienceId,
    );
  }

  Memory? addDraft(
    DiscoveryDocument document,
    InsightDraft draft, {
    DateTime? at,
    String? id,
  }) {
    if (!insightAllowed(draft.evidence.length)) return null;
    final now = at ?? DateTime.now();
    final memory = Memory(
      id: id ?? now.microsecondsSinceEpoch.toString(),
      topicId: draft.topicId,
      topicLabel: draft.topicLabel,
      dimension: draft.dimension,
      observation: draft.observation,
      evidence: draft.evidence,
      signals: draft.signals,
      confidence: draft.confidence,
      contextLabel: draft.contextLabel,
      status: ConfirmationStatus.proposed,
      createdAt: now,
      updatedAt: now,
      crossTopic: draft.crossTopic,
      contextSpecific: draft.contextLabel != 'general',
      experienceId: draft.experienceId,
      history: [MemoryRevision(at: now, change: 'proposed')],
    );
    document.memories.insert(0, memory);
    _refreshCrossTopic(document, now);
    return memory;
  }

  PreferenceRelation previewRelation(
    DiscoveryDocument document,
    InsightDraft draft, {
    String contextLabel = 'general',
  }) {
    final previous = document.memories.where((memory) {
      return memory.topicId == draft.topicId &&
          memory.dimension == draft.dimension &&
          !memory.crossTopic &&
          memory.status != ConfirmationStatus.dismissed;
    }).firstOrNull;
    if (previous == null) return PreferenceRelation.compatible;
    return relatePreferences(
      previousSignal: dominantSignal(previous.signals),
      previousContext: previous.contextLabel,
      nextSignal: dominantSignal(draft.signals),
      nextContext: contextLabel,
    );
  }

  void resolve(
    DiscoveryDocument document,
    Memory memory, {
    required ConfirmationStatus status,
    required bool meaningful,
    String? correction,
    String? changeNote,
    String? contextLabel,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    if (contextLabel != null && contextLabel != memory.contextLabel) {
      memory.contextLabel = contextLabel;
      memory.contextSpecific = contextLabel != 'general';
      memory.history.add(
        MemoryRevision(at: now, change: 'context', note: contextLabel),
      );
    }
    if (correction != null && correction.trim().isNotEmpty) {
      memory.history.add(
        MemoryRevision(at: now, change: 'corrected', note: memory.observation),
      );
      memory.observation = correction.trim();
    }
    if (changeNote != null && changeNote.trim().isNotEmpty) {
      memory.preferenceChanged = true;
      memory.history.add(
        MemoryRevision(
          at: now,
          change: 'preference changed',
          note: changeNote.trim(),
        ),
      );
    }
    memory.status = status;
    memory.meaningful = meaningful;
    memory.updatedAt = now;
    if (status == ConfirmationStatus.confirmed ||
        status == ConfirmationStatus.corrected) {
      memory.confidence = confidenceFor(
        confirmingSessions: 1,
        distinctTopics: memory.crossTopic ? 2 : 1,
      );
      memory.history.add(MemoryRevision(at: now, change: status.name));
    }
    if (status == ConfirmationStatus.dismissed) {
      memory.history.add(MemoryRevision(at: now, change: 'dismissed'));
    }
    _refreshCrossTopic(document, now);
  }

  void recordExploration(
    DiscoveryDocument document, {
    required String topicId,
    required bool meaningful,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    document.explorations.add(
      ExplorationStat(
        id: 'explore-${document.explorations.length}-${now.microsecondsSinceEpoch}',
        topicId: topicId,
        completed: true,
        at: now,
        meaningful: meaningful,
      ),
    );
  }

  void markTemporary(Memory memory, bool temporary, {DateTime? at}) {
    memory.temporary = temporary;
    memory.updatedAt = at ?? DateTime.now();
    memory.history.add(
      MemoryRevision(
        at: memory.updatedAt,
        change: temporary ? 'marked temporary' : 'kept',
      ),
    );
  }

  void editContext(Memory memory, String contextLabel, {DateTime? at}) {
    memory.contextLabel = contextLabel;
    memory.contextSpecific = contextLabel != 'general';
    memory.updatedAt = at ?? DateTime.now();
    memory.history.add(
      MemoryRevision(
        at: memory.updatedAt,
        change: 'context',
        note: contextLabel,
      ),
    );
  }

  ExperienceNote saveExperience(
    DiscoveryDocument document,
    String text, {
    String? reflection,
    DateTime? at,
    String? id,
  }) {
    final now = at ?? DateTime.now();
    final note = ExperienceNote(
      id: id ?? 'exp-${now.microsecondsSinceEpoch}',
      text: text.trim(),
      createdAt: now,
      reflection: reflection,
    );
    document.experiences.insert(0, note);
    return note;
  }

  void linkExperience(ExperienceNote note, Memory memory) {
    note.memoryIds = [...note.memoryIds, memory.id];
  }

  List<Memory> memoriesForExperience(
    DiscoveryDocument document,
    String experienceId,
  ) {
    final note = document.experiences
        .where((item) => item.id == experienceId)
        .firstOrNull;
    final ids = note?.memoryIds.toSet() ?? {};
    return document.memories
        .where(
          (memory) =>
              memory.experienceId == experienceId || ids.contains(memory.id),
        )
        .toList();
  }

  void deleteExperience(
    DiscoveryDocument document,
    String experienceId, {
    bool removeRelated = false,
  }) {
    final related = memoriesForExperience(document, experienceId);
    document.experiences.removeWhere((item) => item.id == experienceId);
    if (removeRelated) {
      final ids = related.map((item) => item.id).toSet();
      document.memories.removeWhere((memory) => ids.contains(memory.id));
      _refreshCrossTopic(document, DateTime.now());
    }
  }

  void deleteMemory(DiscoveryDocument document, String memoryId) {
    document.memories.removeWhere((memory) => memory.id == memoryId);
    for (final note in document.experiences) {
      note.memoryIds = note.memoryIds.where((id) => id != memoryId).toList();
    }
    _refreshCrossTopic(document, DateTime.now());
  }

  void deleteAll(DiscoveryDocument document) {
    document.memories.clear();
    document.experiences.clear();
    document.explorations.clear();
    document.prompts.clear();
    document.milestonesSeen.clear();
    document.payIntent = null;
  }

  ProactiveSuggestion? nextProactive(
    DiscoveryDocument document, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = document.prompts
        .where((prompt) => _sameDay(prompt.at, clock))
        .length;
    if (!promptAllowed(
      enabled: document.settings.proactiveEnabled,
      promptsToday: today,
      maxPerDay: document.settings.maxPromptsPerDay,
    )) {
      return null;
    }
    final candidate = document.memories.where((memory) {
      return memory.status == ConfirmationStatus.proposed &&
          memory.evidence.length >= (memory.crossTopic ? 3 : 1);
    }).firstOrNull;
    if (candidate == null) return null;
    final reason = candidate.crossTopic
        ? 'This connects ${candidate.topicLabel} because the same pattern showed up more than once. It can wait.'
        : 'This is still an early read about ${candidate.topicLabel}. Nothing urgent — only if you want to look.';
    return ProactiveSuggestion(
      id: 'prompt-${candidate.id}',
      title: 'A possible discovery',
      reason: reason,
      memoryId: candidate.id,
    );
  }

  void recordPrompt(
    DiscoveryDocument document,
    ProactiveSuggestion suggestion, {
    DateTime? at,
  }) {
    document.prompts.add(
      PromptEvent(
        id: suggestion.id,
        reason: suggestion.reason,
        at: at ?? DateTime.now(),
      ),
    );
  }

  List<Milestone> freshMilestones(DiscoveryDocument document) {
    final earned = <Milestone>[];
    final completedTopics = document.explorations
        .where((item) => item.completed)
        .map((item) => item.topicId)
        .toSet();
    if (document.explorations.any((item) => item.completed)) {
      earned.add(
        const Milestone(
          id: 'first_exploration',
          title: 'First look',
          detail: 'You finished an exploration. There is no daily target.',
        ),
      );
    }
    if (completedTopics.length >= 3) {
      earned.add(
        const Milestone(
          id: 'three_topics',
          title: 'Three angles',
          detail:
              'You have looked at three topics. The map can connect them when the evidence is there.',
        ),
      );
    }
    if (document.experiences.isNotEmpty) {
      earned.add(
        const Milestone(
          id: 'first_experience',
          title: 'A lived note',
          detail: 'You logged something that happened, not only an answer.',
        ),
      );
    }
    if (document.memories.any(
      (memory) => memory.status == ConfirmationStatus.corrected,
    )) {
      earned.add(
        const Milestone(
          id: 'first_correction',
          title: 'You edited the record',
          detail: 'A correction is part of the profile. It is not a miss.',
        ),
      );
    }
    return earned
        .where(
          (item) =>
              milestoneAllowed(item.id) &&
              !document.milestonesSeen.contains(item.id),
        )
        .toList();
  }

  void recordCrossTopicOpen(DiscoveryDocument document) {
    document.crossTopicOpens += 1;
  }

  void seeMilestone(DiscoveryDocument document, String id) {
    if (milestoneAllowed(id)) document.milestonesSeen.add(id);
  }

  DiscoveryMetrics metrics(DiscoveryDocument document, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final completed = document.explorations
        .where((item) => item.completed)
        .toList();
    final activeTopics = completed.map((item) => item.topicId).toSet();
    bool returnedAfter(int days) {
      if (completed.isEmpty) return false;
      return completed.any(
        (item) =>
            !item.at.isAfter(clock) &&
            item.at.difference(document.firstSeen).inDays >= days,
      );
    }

    return DiscoveryMetrics(
      started: document.explorations.length,
      completed: completed.length,
      meaningful: completed.where((item) => item.meaningful == true).length,
      confirmed: document.memories
          .where((item) => item.status == ConfirmationStatus.confirmed)
          .length,
      corrected: document.memories
          .where((item) => item.status == ConfirmationStatus.corrected)
          .length,
      dismissed: document.memories
          .where((item) => item.status == ConfirmationStatus.dismissed)
          .length,
      repeatExplorations: completed.length > activeTopics.length
          ? completed.length - activeTopics.length
          : (activeTopics.length > 1 ? activeTopics.length - 1 : 0),
      experiences: document.experiences.length,
      crossTopicOpened: document.crossTopicOpens,
      returnedByDay7: returnedAfter(7),
      returnedByDay30: returnedAfter(30),
    );
  }

  void _refreshCrossTopic(DiscoveryDocument document, DateTime now) {
    final previous = document.memories
        .where((memory) => memory.crossTopic)
        .toList();
    final active = document.memories.where(
      (memory) =>
          !memory.crossTopic && memory.status != ConfirmationStatus.dismissed,
    );
    final bySignal = <String, List<Memory>>{};
    for (final memory in active) {
      final signal = dominantSignal(memory.signals);
      if (signal == null) continue;
      bySignal.putIfAbsent(signal, () => []).add(memory);
    }
    String? bestSignal;
    var bestTopics = <String>{};
    var bestEvidence = 0;
    for (final entry in bySignal.entries) {
      final topics = entry.value.map((memory) => memory.topicId).toSet();
      final evidence = entry.value.fold<int>(
        0,
        (sum, memory) => sum + memory.evidence.length,
      );
      if (topics.length > bestTopics.length) {
        bestSignal = entry.key;
        bestTopics = topics;
        bestEvidence = evidence;
      }
    }
    document.memories.removeWhere((memory) => memory.crossTopic);
    if (bestSignal == null ||
        !crossTopicWarranted(
          topicCount: bestTopics.length,
          evidenceCount: bestEvidence,
        )) {
      return;
    }
    final related = bySignal[bestSignal]!;
    final labels = related.map((memory) => memory.topicLabel).toSet().toList();
    final confirmed = related
        .where(
          (memory) =>
              memory.status == ConfirmationStatus.confirmed ||
              memory.status == ConfirmationStatus.corrected,
        )
        .length;
    final id = 'cross-$bestSignal';
    final prior = previous.where((memory) => memory.id == id).firstOrNull;
    if (prior != null && prior.status != ConfirmationStatus.proposed) {
      document.memories.insert(0, prior);
      return;
    }
    final pattern = signalPatterns[bestSignal]!;
    document.memories.insert(
      0,
      Memory(
        id: id,
        topicId: 'cross:$bestSignal',
        topicLabel: labels.join(', '),
        dimension: bestSignal,
        observation: 'Across ${labels.join(', ')}, $pattern.',
        evidence: related.expand((memory) => memory.evidence.take(1)).toList(),
        signals: [bestSignal],
        confidence: confidenceFor(
          confirmingSessions: confirmed,
          distinctTopics: bestTopics.length,
        ),
        contextLabel: 'general',
        status: ConfirmationStatus.proposed,
        createdAt: prior?.createdAt ?? now,
        updatedAt: now,
        crossTopic: true,
        history: [MemoryRevision(at: now, change: 'cross-topic')],
      ),
    );
  }

  InsightDraft? _draft({
    required String topicId,
    required String topicLabel,
    required String dimension,
    required List<EvidenceRef> evidence,
    required List<String> signals,
    required int confirmingSessions,
    required int distinctTopics,
    required String contextLabel,
    String? experienceId,
  }) {
    if (!insightAllowed(evidence.length)) return null;
    final signal = dominantSignal(signals);
    if (signal == null) return null;
    final pattern = signalPatterns[signal]!;
    final contextNote = contextLabel == 'general'
        ? ''
        : ' In the context of $contextLabel,';
    return InsightDraft(
      topicId: topicId,
      topicLabel: topicLabel,
      dimension: dimension,
      observation: contextLabel == 'general'
          ? 'With $topicLabel, $pattern.'
          : 'With $topicLabel,$contextNote $pattern.',
      evidence: evidence,
      signals: signals,
      confidence: confidenceFor(
        confirmingSessions: confirmingSessions,
        distinctTopics: distinctTopics,
      ),
      crossTopic: false,
      contextLabel: contextLabel,
      experienceId: experienceId,
    );
  }

  String _primaryDimension(
    DiscoveryTopic topic,
    Map<String, DiscoveryResponse> answers,
  ) {
    for (final question in topic.questions) {
      final response = answers[question.id];
      if (response != null &&
          !response.skipped &&
          response.signals.isNotEmpty) {
        return question.dimension;
      }
    }
    return topic.dimensions.isEmpty ? 'preference' : topic.dimensions.first;
  }

  String? _evidenceSummary(
    DiscoveryQuestion question,
    DiscoveryResponse response,
  ) {
    if (response.values.isEmpty &&
        question.format != QuestionFormat.shortText) {
      return null;
    }
    return switch (question.format) {
      QuestionFormat.shortText =>
        response.values.isEmpty || response.values.first.trim().isEmpty
            ? null
            : 'You wrote “${response.values.first.trim()}” for “${question.text}”',
      QuestionFormat.rating =>
        'You rated “${question.text}” ${response.values.first} out of 5. The number is a preference strength, not a certainty score.',
      QuestionFormat.ranking =>
        'You ranked “${_label(question, response.values.first)}” first for “${question.text}”',
      _ =>
        'You chose “${response.values.map((value) => _label(question, value)).join(', ')}” for “${question.text}”',
    };
  }

  String _label(DiscoveryQuestion question, String value) {
    return question.options
            .where((option) => option.value == value)
            .firstOrNull
            ?.label ??
        value;
  }

  bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

/// JSON entry point for `run_off_main`. The payload and result are sendable maps.
Map<String, Object?> scoreExplorationPayload(Map<String, Object?> payload) {
  final topicId = payload['topicId']! as String;
  final topicLabel = payload['topicLabel']! as String;
  final contextLabel = payload['contextLabel'] as String? ?? 'general';
  final topic = topicId == 'custom'
      ? customTopic
      : starterTopics.where((item) => item.id == topicId).first;
  final rawAnswers = (payload['answers']! as Map).cast<String, Object?>();
  final answers = rawAnswers.map(
    (key, value) => MapEntry(
      key,
      DiscoveryResponse.fromJson((value as Map).cast<String, Object?>()),
    ),
  );
  final draft = const DiscoveryEngine().draftFromResponses(
    topic: topic,
    topicLabel: topicLabel,
    answers: answers,
    contextLabel: contextLabel,
  );
  if (draft == null) return {'insight': null};
  return {
    'insight': {
      'topicId': draft.topicId,
      'topicLabel': draft.topicLabel,
      'dimension': draft.dimension,
      'observation': draft.observation,
      'signals': draft.signals,
      'confidence': draft.confidence.name,
      'evidence': draft.evidence.map((item) => item.toJson()).toList(),
    },
  };
}
