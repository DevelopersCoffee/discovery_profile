import 'rules.dart';
import 'spectrum.dart';

class DiscoveryOption {
  const DiscoveryOption({
    required this.label,
    required this.value,
    this.signals = const [],
  });

  final String label;
  final String value;
  final List<String> signals;
}

class DiscoveryQuestion {
  const DiscoveryQuestion({
    required this.id,
    required this.text,
    required this.format,
    this.options = const [],
    this.dimension = 'preference',
    this.whenQuestion,
    this.whenValue,
    this.scenario,
    this.scaleSignal,
  });

  final String id;
  final String text;
  final QuestionFormat format;
  final List<DiscoveryOption> options;
  final String dimension;
  final String? whenQuestion;
  final String? whenValue;
  final String? scenario;
  final String? scaleSignal;

  bool available(Map<String, DiscoveryResponse> answers) {
    if (whenQuestion == null) return true;
    final previous = answers[whenQuestion];
    if (previous == null || previous.skipped) return false;
    return previous.values.contains(whenValue);
  }
}

class DiscoveryTopic {
  const DiscoveryTopic({
    required this.id,
    required this.label,
    required this.blurb,
    required this.questions,
    this.dimensions = const [],
  });

  final String id;
  final String label;
  final String blurb;
  final List<DiscoveryQuestion> questions;
  final List<String> dimensions;
}

class DiscoveryResponse {
  const DiscoveryResponse({
    required this.questionId,
    required this.prompt,
    required this.format,
    required this.values,
    this.skipped = false,
    this.signals = const [],
  });

  final String questionId;
  final String prompt;
  final QuestionFormat format;
  final List<String> values;
  final bool skipped;
  final List<String> signals;

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'prompt': prompt,
    'format': format.name,
    'values': values,
    'skipped': skipped,
    'signals': signals,
  };

  static DiscoveryResponse fromJson(Map<String, Object?> json) {
    return DiscoveryResponse(
      questionId: json['questionId']! as String,
      prompt: json['prompt']! as String,
      format: QuestionFormat.values.byName(json['format']! as String),
      values: (json['values']! as List).cast<String>(),
      skipped: json['skipped']! as bool,
      signals: (json['signals'] as List? ?? const []).cast<String>(),
    );
  }
}

class EvidenceRef {
  const EvidenceRef({
    required this.summary,
    required this.source,
    this.experienceId,
  });

  final String summary;
  final String source;
  final String? experienceId;

  Map<String, Object?> toJson() => {
    'summary': summary,
    'source': source,
    'experienceId': experienceId,
  };

  static EvidenceRef fromJson(Map<String, Object?> json) {
    return EvidenceRef(
      summary: json['summary']! as String,
      source: json['source']! as String,
      experienceId: json['experienceId'] as String?,
    );
  }
}

class MemoryRevision {
  const MemoryRevision({required this.at, required this.change, this.note});

  final DateTime at;
  final String change;
  final String? note;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'change': change,
    'note': note,
  };

  static MemoryRevision fromJson(Map<String, Object?> json) {
    return MemoryRevision(
      at: DateTime.parse(json['at']! as String),
      change: json['change']! as String,
      note: json['note'] as String?,
    );
  }
}

class Memory {
  Memory({
    required this.id,
    required this.topicId,
    required this.topicLabel,
    required this.dimension,
    required this.observation,
    required this.evidence,
    required this.signals,
    required this.confidence,
    required this.contextLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.temporary = false,
    this.contextSpecific = false,
    this.crossTopic = false,
    this.preferenceChanged = false,
    this.experienceId,
    List<MemoryRevision>? history,
  }) : history = history ?? [];

  final String id;
  final String topicId;
  final String topicLabel;
  final String dimension;
  String observation;
  final List<EvidenceRef> evidence;
  final List<String> signals;
  Confidence confidence;
  String contextLabel;
  ConfirmationStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  bool temporary;
  bool contextSpecific;
  final bool crossTopic;
  bool preferenceChanged;
  final String? experienceId;
  final List<MemoryRevision> history;
  bool? meaningful;

  Map<String, Object?> toJson() => {
    'id': id,
    'topicId': topicId,
    'topicLabel': topicLabel,
    'dimension': dimension,
    'observation': observation,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'signals': signals,
    'confidence': confidence.name,
    'contextLabel': contextLabel,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'temporary': temporary,
    'contextSpecific': contextSpecific,
    'crossTopic': crossTopic,
    'preferenceChanged': preferenceChanged,
    'experienceId': experienceId,
    'history': history.map((item) => item.toJson()).toList(),
    'meaningful': meaningful,
  };

  static Memory fromJson(Map<String, Object?> json) {
    return Memory(
      id: json['id']! as String,
      topicId: json['topicId']! as String,
      topicLabel: json['topicLabel']! as String,
      dimension: json['dimension']! as String,
      observation: json['observation']! as String,
      evidence: (json['evidence']! as List)
          .map(
            (item) =>
                EvidenceRef.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
      signals: (json['signals']! as List).cast<String>(),
      confidence: Confidence.values.byName(json['confidence']! as String),
      contextLabel: json['contextLabel']! as String,
      status: ConfirmationStatus.values.byName(json['status']! as String),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      temporary: json['temporary']! as bool,
      contextSpecific: json['contextSpecific']! as bool,
      crossTopic: json['crossTopic']! as bool,
      preferenceChanged: json['preferenceChanged']! as bool,
      experienceId: json['experienceId'] as String?,
      history: (json['history']! as List)
          .map(
            (item) =>
                MemoryRevision.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
    )..meaningful = json['meaningful'] as bool?;
  }
}

class ExperienceNote {
  ExperienceNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.reflection,
    this.memoryIds = const [],
  });

  final String id;
  final String text;
  final DateTime createdAt;
  String? reflection;
  List<String> memoryIds;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'reflection': reflection,
    'memoryIds': memoryIds,
  };

  static ExperienceNote fromJson(Map<String, Object?> json) {
    return ExperienceNote(
      id: json['id']! as String,
      text: json['text']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      reflection: json['reflection'] as String?,
      memoryIds: (json['memoryIds'] as List? ?? const []).cast<String>(),
    );
  }
}

class ExplorationStat {
  ExplorationStat({
    required this.id,
    required this.topicId,
    required this.completed,
    required this.at,
    this.meaningful,
  });

  final String id;
  final String topicId;
  bool completed;
  final DateTime at;
  bool? meaningful;

  Map<String, Object?> toJson() => {
    'id': id,
    'topicId': topicId,
    'completed': completed,
    'at': at.toIso8601String(),
    'meaningful': meaningful,
  };

  static ExplorationStat fromJson(Map<String, Object?> json) {
    return ExplorationStat(
      id: json['id']! as String,
      topicId: json['topicId']! as String,
      completed: json['completed']! as bool,
      at: DateTime.parse(json['at']! as String),
      meaningful: json['meaningful'] as bool?,
    );
  }
}

class PromptEvent {
  const PromptEvent({required this.id, required this.reason, required this.at});

  final String id;
  final String reason;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'id': id,
    'reason': reason,
    'at': at.toIso8601String(),
  };

  static PromptEvent fromJson(Map<String, Object?> json) {
    return PromptEvent(
      id: json['id']! as String,
      reason: json['reason']! as String,
      at: DateTime.parse(json['at']! as String),
    );
  }
}

class DiscoverySettings {
  DiscoverySettings({
    this.proactiveEnabled = true,
    this.gamificationEnabled = true,
    this.maxPromptsPerDay = 1,
    this.questionDepth,
  });

  bool proactiveEnabled;
  bool gamificationEnabled;
  int maxPromptsPerDay;

  /// Maximum questions in one exploration. Null means ask every useful follow-up.
  int? questionDepth;

  Map<String, Object?> toJson() => {
    'proactiveEnabled': proactiveEnabled,
    'gamificationEnabled': gamificationEnabled,
    'maxPromptsPerDay': maxPromptsPerDay,
    'questionDepth': questionDepth,
  };

  static DiscoverySettings fromJson(Map<String, Object?> json) {
    return DiscoverySettings(
      proactiveEnabled: json['proactiveEnabled']! as bool,
      gamificationEnabled: json['gamificationEnabled']! as bool,
      maxPromptsPerDay: json['maxPromptsPerDay']! as int,
      questionDepth: json['questionDepth'] as int?,
    );
  }
}

class DiscoveryMetrics {
  const DiscoveryMetrics({
    required this.started,
    required this.completed,
    required this.meaningful,
    required this.confirmed,
    required this.corrected,
    required this.dismissed,
    required this.repeatExplorations,
    required this.experiences,
    required this.crossTopicOpened,
    required this.returnedByDay7,
    required this.returnedByDay30,
  });

  final int started;
  final int completed;
  final int meaningful;
  final int confirmed;
  final int corrected;
  final int dismissed;
  final int repeatExplorations;
  final int experiences;
  final int crossTopicOpened;
  final bool returnedByDay7;
  final bool returnedByDay30;

  double? get meaningfulRate => completed == 0 ? null : meaningful / completed;

  double? get completionRate => started == 0 ? null : completed / started;

  double? get confirmationRate {
    final resolved = confirmed + corrected + dismissed;
    if (resolved == 0) return null;
    return confirmed / resolved;
  }
}

class AppliedDraft {
  const AppliedDraft({
    required this.memory,
    required this.relation,
    required this.created,
  });

  final Memory memory;
  final PreferenceRelation relation;
  final bool created;
}

class TopicFraming {
  const TopicFraming({
    required this.label,
    required this.dimensions,
    required this.needsClarification,
    this.clarification,
  });

  final String label;
  final List<String> dimensions;
  final bool needsClarification;
  final String? clarification;
}

class InsightDraft {
  const InsightDraft({
    required this.topicId,
    required this.topicLabel,
    required this.dimension,
    required this.observation,
    required this.evidence,
    required this.signals,
    required this.confidence,
    required this.crossTopic,
    this.contextLabel = 'general',
    this.experienceId,
  });

  final String topicId;
  final String topicLabel;
  final String dimension;
  final String observation;
  final List<EvidenceRef> evidence;
  final List<String> signals;
  final Confidence confidence;
  final bool crossTopic;
  final String contextLabel;
  final String? experienceId;
}

class ProactiveSuggestion {
  const ProactiveSuggestion({
    required this.id,
    required this.title,
    required this.reason,
    required this.memoryId,
  });

  final String id;
  final String title;
  final String reason;
  final String memoryId;
}

class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    required this.detail,
  });

  final String id;
  final String title;
  final String detail;
}

class DiscoveryDocument {
  DiscoveryDocument({
    List<Memory>? memories,
    List<ExperienceNote>? experiences,
    List<ExplorationStat>? explorations,
    List<PromptEvent>? prompts,
    DiscoverySettings? settings,
    Set<String>? milestonesSeen,
    this.payIntent,
    this.crossTopicOpens = 0,
    DateTime? firstSeen,
    List<SpectrumTopic>? spectrumTopics,
    List<SpectrumReading>? spectra,
  }) : memories = memories ?? [],
       spectrumTopics = spectrumTopics ?? [],
       spectra = spectra ?? [],
       experiences = experiences ?? [],
       explorations = explorations ?? [],
       prompts = prompts ?? [],
       settings = settings ?? DiscoverySettings(),
       milestonesSeen = milestonesSeen ?? {},
       firstSeen = firstSeen ?? DateTime.now();

  final List<Memory> memories;
  final List<ExperienceNote> experiences;
  final List<ExplorationStat> explorations;
  final List<PromptEvent> prompts;
  final DiscoverySettings settings;
  final Set<String> milestonesSeen;
  bool? payIntent;
  int crossTopicOpens;
  final DateTime firstSeen;

  /// Spectrum topics the person wrote or accepted. Built-in ones live in
  /// `starterSpectra` and are not stored.
  final List<SpectrumTopic> spectrumTopics;

  /// One spectrum reading per topic.
  final List<SpectrumReading> spectra;

  Map<String, Object?> toJson() => {
    'memories': memories.map((item) => item.toJson()).toList(),
    'experiences': experiences.map((item) => item.toJson()).toList(),
    'explorations': explorations.map((item) => item.toJson()).toList(),
    'prompts': prompts.map((item) => item.toJson()).toList(),
    'settings': settings.toJson(),
    'milestonesSeen': milestonesSeen.toList(),
    'payIntent': payIntent,
    'crossTopicOpens': crossTopicOpens,
    'firstSeen': firstSeen.toIso8601String(),
    'spectrumTopics': spectrumTopics.map((item) => item.toJson()).toList(),
    'spectra': spectra.map((item) => item.toJson()).toList(),
  };

  static DiscoveryDocument fromJson(Map<String, Object?> json) {
    return DiscoveryDocument(
      memories: (json['memories']! as List)
          .map((item) => Memory.fromJson((item as Map).cast<String, Object?>()))
          .toList(),
      experiences: (json['experiences']! as List)
          .map(
            (item) =>
                ExperienceNote.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
      explorations: (json['explorations']! as List)
          .map(
            (item) =>
                ExplorationStat.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
      prompts: (json['prompts']! as List)
          .map(
            (item) =>
                PromptEvent.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
      settings: DiscoverySettings.fromJson(
        (json['settings']! as Map).cast<String, Object?>(),
      ),
      milestonesSeen: (json['milestonesSeen']! as List).cast<String>().toSet(),
      crossTopicOpens: json['crossTopicOpens'] as int? ?? 0,
      firstSeen: DateTime.parse(json['firstSeen']! as String),
      spectrumTopics: (json['spectrumTopics'] as List? ?? const [])
          .map(
            (item) =>
                SpectrumTopic.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
      spectra: (json['spectra'] as List? ?? const [])
          .map(
            (item) =>
                SpectrumReading.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(),
    )..payIntent = json['payIntent'] as bool?;
  }
}
