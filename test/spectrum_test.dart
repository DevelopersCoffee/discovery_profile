import 'dart:convert';

import 'package:discovery_profile/discovery_profile.dart';
import 'package:test/test.dart';

void main() {
  const engine = DiscoveryEngine();
  final diet = starterSpectra.firstWhere((item) => item.id == 'diet');

  Map<String, int?> pick(List<int?> indexes) => {
    for (final (i, question) in diet.questions.indexed) question.id: indexes[i],
  };

  test('position matches dc_discovery_engine integer rounding', () {
    expect(spectrumPosition([]), isNull);
    expect(spectrumPosition([0, 100]), 50);
    expect(spectrumPosition([0, 0, 1]), 0);
    expect(spectrumPosition([0, 1]), 1);
    expect(spectrumPosition([10, 20, 25]), 18);
    expect(spectrumPosition([250]), 100);
    expect(spectrumBand(0, [9, 29, 49, 100]), 0);
    expect(spectrumBand(30, [9, 29, 49, 100]), 2);
    expect(spectrumBand(100, [9, 29]), isNull);
    expect(
      spectrumConfidence(answered: 2, confirmingSessions: 3),
      Confidence.hypothesis,
    );
    expect(
      spectrumConfidence(answered: 3, confirmingSessions: 0),
      Confidence.emerging,
    );
    expect(
      spectrumConfidence(answered: 4, confirmingSessions: 1),
      Confidence.supported,
    );
  });

  test('the diet spectrum names common eating patterns', () {
    expect(engine.validateSpectrumTopic(diet), isEmpty);
    String? termFor(List<int?> answers) =>
        engine.scoreSpectrum(DiscoveryDocument(), diet, pick(answers))?.term;

    expect(termFor([0, 0, 0, 0, 0]), 'vegan');
    expect(termFor([0, 0, 0, 2, 0]), 'vegetarian');
    expect(termFor([0, 0, 2, 2, 0]), 'vegetarian');
    expect(termFor([1, 1, 1, 2, 1]), 'flexitarian');
    expect(termFor([3, 2, 2, 2, 2]), 'omnivore');
  });

  test('same answers always give the same reading, with evidence', () {
    final first = engine.scoreSpectrum(
      DiscoveryDocument(),
      diet,
      pick([1, 1, 1, 2, 1]),
    )!;
    final second = engine.scoreSpectrum(
      DiscoveryDocument(),
      diet,
      pick([1, 1, 1, 2, 1]),
    )!;
    expect(first.position, second.position);
    expect(first.position, 37);
    expect(first.evidence, hasLength(5));
    expect(first.evidence.first.summary, contains('A few times a month'));
    expect(first.confidence, Confidence.emerging);
    expect(engine.spectrumExplanation(diet, first), contains('flexitarian'));
  });

  test('skipped questions are left out and nothing answered places no one', () {
    final document = DiscoveryDocument();
    expect(
      engine.scoreSpectrum(
        document,
        diet,
        pick([null, null, null, null, null]),
      ),
      isNull,
    );
    final reading = engine.scoreSpectrum(
      document,
      diet,
      pick([0, null, null, null, 0]),
    )!;
    expect(reading.answered, 2);
    expect(reading.skipped, 3);
    expect(reading.confidence, Confidence.hypothesis);
  });

  test('a later session in the same band supports the reading', () {
    final document = DiscoveryDocument();
    engine.scoreSpectrum(
      document,
      diet,
      pick([0, 0, 1, 2, 0]),
      at: DateTime(2026, 10, 1),
    );
    final again = engine.scoreSpectrum(
      document,
      diet,
      pick([0, 0, 2, 2, 0]),
      at: DateTime(2026, 10, 8),
    )!;
    expect(document.spectra, hasLength(1));
    expect(again.confirmingSessions, 1);
    expect(again.confidence, Confidence.supported);
    expect(again.history.single.position, 12);

    final changed = engine.scoreSpectrum(
      document,
      diet,
      pick([3, 2, 2, 2, 2]),
    )!;
    expect(changed.term, 'omnivore');
    expect(changed.confirmingSessions, 0);
    expect(changed.confidence, Confidence.emerging);
  });

  test('the person can correct the term, confirm, and delete', () {
    final document = DiscoveryDocument();
    final reading = engine.scoreSpectrum(
      document,
      diet,
      pick([0, 0, 1, 2, 0]),
    )!;
    engine.correctSpectrumTerm(reading, 'eggetarian');
    expect(reading.shownTerm, 'eggetarian');
    expect(reading.status, ConfirmationStatus.corrected);
    expect(
      engine.spectrumExplanation(diet, reading),
      contains('You call this'),
    );
    engine.correctSpectrumTerm(reading, ' ');
    expect(reading.shownTerm, 'vegetarian');
    engine.confirmSpectrum(reading);
    expect(reading.status, ConfirmationStatus.confirmed);
    engine.deleteSpectrumReading(document, 'diet');
    expect(document.spectra, isEmpty);
  });

  test('sensitive identity spectrums are refused, whoever wrote them', () {
    const ethnic = SpectrumTopic(
      id: 'x',
      label: 'How ethnic am I?',
      lowLabel: 'Not at all',
      highLabel: 'Very',
      questions: [
        SpectrumQuestion(
          id: 'q',
          text: 'Pick one',
          options: [
            SpectrumOption(label: 'A', weight: 0),
            SpectrumOption(label: 'B', weight: 100),
          ],
        ),
      ],
    );
    expect(engine.validateSpectrumTopic(ethnic), isNotEmpty);
    final document = DiscoveryDocument();
    expect(engine.saveSpectrumTopic(document, ethnic), isNotEmpty);
    expect(document.spectrumTopics, isEmpty);
    expect(engine.scoreSpectrum(document, ethnic, {'q': 1}), isNull);
    expect(
      engine.spectrumTopicFromSuggestion({
        'label': 'Coffee habits',
        'lowLabel': 'Secular',
        'highLabel': 'Religious',
        'questions': [
          {
            'text': 'How often?',
            'options': [
              {'label': 'Never', 'weight': 0},
              {'label': 'Daily', 'weight': 100},
            ],
          },
        ],
      }, id: 'm1'),
      isNull,
    );
  });

  test('model suggestions are sanitised drafts that still need validation', () {
    final draft = engine.spectrumTopicFromSuggestion({
      'label': 'How much of a coffee nerd am I?',
      'lowLabel': 'Any coffee is fine',
      'highLabel': 'Full coffee nerd',
      'questions': [
        {
          'text': 'How do you usually brew?',
          'options': [
            {'label': 'Instant', 'weight': -20},
            {'label': 'Pour-over by weight', 'weight': 140.6},
          ],
        },
        {'text': 'Broken question', 'options': []},
        'not a question',
      ],
      'bands': [
        {'upper': 100, 'term': 'coffee nerd'},
        {'upper': 40, 'term': 'casual drinker'},
      ],
    }, id: 'coffee')!;
    expect(draft.source, SpectrumSource.model);
    expect(draft.questions, hasLength(1));
    expect(draft.questions.single.id, 'coffee-q0');
    expect(draft.questions.single.options.map((o) => o.weight), [0, 100]);
    expect(draft.bands.map((b) => b.term), ['casual drinker', 'coffee nerd']);
    expect(
      engine.spectrumTopicFromSuggestion({'questions': 'x'}, id: 'y'),
      isNull,
    );
  });

  test('own topics and readings survive storage and delete-all', () {
    final document = DiscoveryDocument();
    const own = SpectrumTopic(
      id: 'own',
      label: 'Morning person',
      lowLabel: 'Night owl',
      highLabel: 'Early bird',
      questions: [
        SpectrumQuestion(
          id: 'wake',
          text: 'When do you wake up?',
          options: [
            SpectrumOption(label: 'After 9', weight: 10),
            SpectrumOption(label: 'Before 6', weight: 90),
          ],
        ),
      ],
    );
    expect(engine.saveSpectrumTopic(document, own), isEmpty);
    engine.scoreSpectrum(document, own, {'wake': 1});
    final restored = DiscoveryDocument.fromJson(
      (jsonDecode(jsonEncode(document.toJson())) as Map)
          .cast<String, Object?>(),
    );
    expect(restored.spectrumTopics.single.label, 'Morning person');
    expect(restored.spectra.single.position, 90);

    final legacy = document.toJson()
      ..remove('spectrumTopics')
      ..remove('spectra');
    expect(DiscoveryDocument.fromJson(legacy).spectra, isEmpty);

    engine.deleteAll(restored);
    expect(restored.spectrumTopics, isEmpty);
    expect(restored.spectra, isEmpty);
  });
}
