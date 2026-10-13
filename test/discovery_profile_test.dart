import 'package:discovery_profile/discovery_profile.dart';
import 'package:test/test.dart';

void main() {
  const engine = DiscoveryEngine();
  DiscoveryTopic topic(String id) =>
      starterTopics.firstWhere((item) => item.id == id);

  test('FR-1 plain language framing can be narrowed, edited, and rejected', () {
    final broad = engine.proposeFraming('life');
    expect(broad.needsClarification, isTrue);

    final movies = engine.proposeFraming(
      'what kind of movies do I actually enjoy',
    );
    expect(movies.needsClarification, isFalse);
    expect(movies.dimensions, contains('story'));

    final edited = engine.editFraming(
      movies,
      label: 'Weeknight films',
      rejectedDimensions: ['company'],
    );
    expect(edited.label, 'Weeknight films');
    expect(edited.dimensions, isNot(contains('company')));
  });

  test('FR-1 and privacy refuse sensitive identity topics', () {
    final framing = engine.proposeFraming('my political ideology');
    expect(framing.needsClarification, isTrue);
    expect(topicAllowed('Marathi theatre'), isTrue);
    expect(topicAllowed('race and ethnicity'), isFalse);
  });

  test('FR-2 supports every question format and skips repeats', () {
    final movies = topic('movies');
    final formats = movies.questions.map((question) => question.format).toSet();
    expect(formats, {
      QuestionFormat.choice,
      QuestionFormat.eitherOr,
      QuestionFormat.rating,
      QuestionFormat.ranking,
      QuestionFormat.scenario,
      QuestionFormat.shortText,
    });

    final answers = <String, DiscoveryResponse>{};
    final first = engine.nextQuestion(
      topic: movies,
      answers: answers,
      document: DiscoveryDocument(),
    );
    expect(first?.id, 'pull');
    answers['pull'] = engine.answerQuestion(first!, ['new']);
    expect(
      engine
          .nextQuestion(
            topic: movies,
            answers: answers,
            document: DiscoveryDocument(),
          )
          ?.format,
      QuestionFormat.eitherOr,
    );

    final document = DiscoveryDocument();
    final draft = engine.draftFromResponses(
      topic: movies,
      topicLabel: 'Movies',
      answers: {
        'pull': engine.answerQuestion(movies.questions.first, ['story']),
      },
    )!;
    final memory = engine.addDraft(document, draft, id: 'm1')!;
    engine.resolve(
      document,
      memory,
      status: ConfirmationStatus.confirmed,
      meaningful: true,
    );
    expect(
      engine
          .nextQuestion(topic: movies, answers: {}, document: document)
          ?.dimension,
      isNot('pull'),
    );
  });

  test('FR-2 skip produces no evidence and catalog copy is not moralizing', () {
    final question = topic('movies').questions.first;
    final skipped = engine.skipQuestion(question);
    final draft = engine.draftFromResponses(
      topic: topic('movies'),
      topicLabel: 'Movies',
      answers: {'pull': skipped},
    );
    expect(draft, isNull);
    final copy = starterTopics
        .expand((item) => item.questions)
        .map((question) => question.text)
        .join(' ');
    expect(copy.toLowerCase(), isNot(contains('hypocrite')));
    expect(copy.toLowerCase(), isNot(contains('better person')));
  });

  test(
    'FR-3 experience can be saved, linked, and deleted with related memory',
    () {
      final document = DiscoveryDocument();
      final note = engine.saveExperience(
        document,
        'I watched a Marathi play in Pune and loved it.',
        id: 'exp-1',
      );
      expect(note.reflection, isNull);
      final draft = engine.draftFromExperience(
        experienceId: note.id,
        text: note.text,
        reflectionValue: 'live',
      )!;
      final memory = engine.addDraft(document, draft, id: 'mem-1')!;
      engine.linkExperience(note, memory);
      expect(engine.memoriesForExperience(document, note.id), hasLength(1));
      engine.deleteExperience(document, note.id, removeRelated: true);
      expect(document.experiences, isEmpty);
      expect(document.memories.where((item) => item.id == 'mem-1'), isEmpty);
    },
  );

  test('FR-4 and FR-5 keep evidence, history, and non-numeric confidence', () {
    final document = DiscoveryDocument();
    final movies = topic('movies');
    final draft = engine.draftFromResponses(
      topic: movies,
      topicLabel: 'Movies',
      answers: {
        'pull': engine.answerQuestion(movies.questions[0], ['new']),
        'surprise': engine.answerQuestion(movies.questions[1], ['controlled']),
      },
    )!;
    expect(draft.confidence, Confidence.hypothesis);
    expect(draft.evidence, isNotEmpty);
    expect(draft.observation, isNot(contains('%')));
    final memory = engine.addDraft(document, draft, id: 'm')!;
    expect(memory.history.single.change, 'proposed');
    engine.resolve(
      document,
      memory,
      status: ConfirmationStatus.corrected,
      meaningful: false,
      correction: 'I like new films only on weekends.',
    );
    expect(memory.confidence, Confidence.emerging);
    expect(memory.history.map((item) => item.change), contains('corrected'));
    expect(confidenceLabel(memory.confidence), isNot(contains('%')));
  });

  test(
    'FR-6 and FR-7 treat context and change differently, without judgment',
    () {
      expect(
        relatePreferences(
          previousSignal: 'quiet_focus',
          previousContext: 'work',
          nextSignal: 'social_context',
          nextContext: 'friends',
        ),
        PreferenceRelation.contextDifference,
      );
      expect(
        relatePreferences(
          previousSignal: 'quiet_focus',
          previousContext: 'home',
          nextSignal: 'social_context',
          nextContext: 'home',
        ),
        PreferenceRelation.changed,
      );
      expect(changeCopy.toLowerCase(), isNot(contains('hypocrite')));
      expect(changeCopy.toLowerCase(), isNot(contains('dishonest')));

      final document = DiscoveryDocument();
      final memory = engine.addDraft(
        document,
        engine.draftFromResponses(
          topic: topic('communication'),
          topicLabel: 'Communication',
          answers: {
            'channel': engine.answerQuestion(
              topic('communication').questions.first,
              ['text'],
            ),
          },
          contextLabel: 'work',
        )!,
        id: 'c1',
      )!;
      engine.resolve(
        document,
        memory,
        status: ConfirmationStatus.confirmed,
        meaningful: true,
        changeNote: 'Work needs a record. Friends do not.',
        contextLabel: 'friends',
      );
      expect(memory.preferenceChanged, isTrue);
      expect(memory.contextLabel, 'friends');
      expect(memory.contextSpecific, isTrue);
    },
  );

  test('FR-8 creates a cross-topic read only with enough evidence', () {
    final document = DiscoveryDocument();
    final movies = topic('movies');
    final travel = topic('travel');
    engine.addDraft(
      document,
      engine.draftFromResponses(
        topic: movies,
        topicLabel: 'Movies',
        answers: {
          'pull': engine.answerQuestion(movies.questions[0], ['new']),
          'surprise': engine.answerQuestion(movies.questions[1], [
            'controlled',
          ]),
        },
      )!,
      id: 'movies',
    );
    expect(document.memories.where((memory) => memory.crossTopic), isEmpty);
    engine.addDraft(
      document,
      engine.draftFromResponses(
        topic: travel,
        topicLabel: 'Travel',
        answers: {
          'right': engine.answerQuestion(travel.questions[0], ['plan']),
          'lock': engine.answerQuestion(travel.questions[1], ['locked']),
        },
      )!,
      id: 'travel',
    );
    final cross = document.memories.where((memory) => memory.crossTopic).single;
    expect(cross.topicLabel, contains('Movies'));
    expect(cross.topicLabel, contains('Travel'));
    expect(cross.evidence.length, greaterThanOrEqualTo(2));
    expect(cross.confidence, isNot(Confidence.supported));
    engine.resolve(
      document,
      cross,
      status: ConfirmationStatus.dismissed,
      meaningful: false,
    );
    expect(
      document.memories.where((memory) => memory.id == cross.id).single.status,
      ConfirmationStatus.dismissed,
    );
  });

  test('FR-9 caps proactive prompts and explains them', () {
    final document = DiscoveryDocument();
    expect(engine.nextProactive(document), isNull);
    final movies = topic('movies');
    final memory = engine.addDraft(
      document,
      engine.draftFromResponses(
        topic: movies,
        topicLabel: 'Movies',
        answers: {
          'pull': engine.answerQuestion(movies.questions.first, ['mood']),
        },
      )!,
      id: 'mood',
    )!;
    final suggestion = engine.nextProactive(
      document,
      now: DateTime(2026, 10, 13),
    )!;
    expect(suggestion.reason.toLowerCase(), isNot(contains('streak')));
    expect(suggestion.reason.toLowerCase(), isNot(contains('urgent!')));
    engine.recordPrompt(document, suggestion, at: DateTime(2026, 10, 13, 9));
    expect(
      engine.nextProactive(document, now: DateTime(2026, 10, 13, 18)),
      isNull,
    );
    document.settings.proactiveEnabled = false;
    document.prompts.clear();
    expect(engine.nextProactive(document), isNull);
    expect(memory.status, ConfirmationStatus.proposed);
  });

  test(
    'FR-10 memory controls affect later questions and can erase the profile',
    () {
      final document = DiscoveryDocument();
      final memory = engine.addDraft(
        document,
        engine.draftFromResponses(
          topic: topic('learning'),
          topicLabel: 'Learning',
          answers: {
            'how': engine.answerQuestion(topic('learning').questions.first, [
              'path',
            ]),
          },
        )!,
        id: 'learn',
      )!;
      engine.resolve(
        document,
        memory,
        status: ConfirmationStatus.confirmed,
        meaningful: true,
      );
      engine.markTemporary(memory, true);
      expect(
        engine
            .nextQuestion(
              topic: topic('learning'),
              answers: {},
              document: document,
            )
            ?.dimension,
        'method',
      );
      engine.deleteAll(document);
      expect(document.memories, isEmpty);
      expect(document.experiences, isEmpty);
    },
  );

  test('FR-11 milestones can be muted in spirit and never reward a streak', () {
    final document = DiscoveryDocument();
    document.settings.gamificationEnabled = false;
    engine.recordExploration(document, topicId: 'movies', meaningful: true);
    final milestones = engine.freshMilestones(document);
    expect(milestones.map((item) => item.id), contains('first_exploration'));
    expect(milestones.map((item) => item.id), isNot(contains('streak')));
    expect(milestoneAllowed('missed_day'), isFalse);
    expect(milestoneAllowed('leaderboard'), isFalse);
  });

  test('metrics record the meaningful discovery rate and retention flags', () {
    final document = DiscoveryDocument(firstSeen: DateTime(2026, 1, 1));
    engine.recordExploration(
      document,
      topicId: 'movies',
      meaningful: true,
      at: DateTime(2026, 1, 1),
    );
    engine.recordExploration(
      document,
      topicId: 'food',
      meaningful: false,
      at: DateTime(2026, 1, 10),
    );
    final metrics = engine.metrics(document, now: DateTime(2026, 2, 15));
    expect(metrics.meaningfulRate, 0.5);
    expect(metrics.returnedByDay7, isTrue);
    expect(metrics.repeatExplorations, greaterThan(0));
  });

  test('rules match the Rust engine', () {
    expect(
      confidenceFor(confirmingSessions: 0, distinctTopics: 1),
      Confidence.hypothesis,
    );
    expect(
      confidenceFor(confirmingSessions: 1, distinctTopics: 1),
      Confidence.emerging,
    );
    expect(
      confidenceFor(confirmingSessions: 0, distinctTopics: 3),
      Confidence.supported,
    );
    expect(crossTopicWarranted(topicCount: 2, evidenceCount: 2), isFalse);
    expect(crossTopicWarranted(topicCount: 2, evidenceCount: 3), isTrue);
    expect(promptAllowed(enabled: true, promptsToday: 0, maxPerDay: 1), isTrue);
  });

  test('off-main payload scores a movie exploration', () {
    final pull = topic('movies').questions.first;
    final result = scoreExplorationPayload({
      'topicId': 'movies',
      'topicLabel': 'Movies',
      'contextLabel': 'home',
      'answers': {
        'pull': engine.answerQuestion(pull, ['new']).toJson(),
      },
    });
    final insight = result['insight']! as Map<String, Object?>;
    expect(insight['confidence'], 'hypothesis');
    expect(insight['observation'], contains('Movies'));
  });

  test('document json round-trips', () {
    final document = DiscoveryDocument();
    engine.saveExperience(document, 'A play in Pune', id: 'e');
    final restored = DiscoveryDocument.fromJson(document.toJson());
    expect(restored.experiences.single.text, 'A play in Pune');
  });
}
