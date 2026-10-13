import 'models.dart';
import 'rules.dart';

DiscoveryOption opt(String label, String value, List<String> signals) {
  return DiscoveryOption(label: label, value: value, signals: signals);
}

const experienceReflection = DiscoveryQuestion(
  id: 'stood_out',
  text: 'What stood out most? You can skip this.',
  format: QuestionFormat.choice,
  dimension: 'experience',
  options: [
    DiscoveryOption(
      label: 'The live, in-the-room feeling',
      value: 'live',
      signals: ['immersive'],
    ),
    DiscoveryOption(label: 'The story', value: 'story', signals: ['story']),
    DiscoveryOption(
      label: 'Trying something new',
      value: 'new',
      signals: ['novelty_with_control'],
    ),
    DiscoveryOption(
      label: 'Going with someone',
      value: 'someone',
      signals: ['social_context'],
    ),
    DiscoveryOption(
      label: 'The place and the ritual',
      value: 'place',
      signals: ['ritual'],
    ),
    DiscoveryOption(
      label: 'Quiet focus',
      value: 'quiet',
      signals: ['quiet_focus'],
    ),
  ],
);

const starterTopics = <DiscoveryTopic>[
  DiscoveryTopic(
    id: 'movies',
    label: 'Movies',
    blurb: 'What kind of watcher you are when you actually choose.',
    dimensions: ['story', 'mood', 'company', 'novelty'],
    questions: [
      DiscoveryQuestion(
        id: 'pull',
        text: 'When you pick something to watch, what pulls you in first?',
        format: QuestionFormat.choice,
        dimension: 'pull',
        options: [
          DiscoveryOption(
            label: 'A story I can follow',
            value: 'story',
            signals: ['story'],
          ),
          DiscoveryOption(
            label: 'A mood I can sit inside',
            value: 'mood',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'Who I am watching with',
            value: 'company',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'Trying something I have not seen',
            value: 'new',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'surprise',
        text: 'How much surprise do you want?',
        format: QuestionFormat.eitherOr,
        dimension: 'novelty',
        whenQuestion: 'pull',
        whenValue: 'new',
        options: [
          DiscoveryOption(
            label: 'Something new, if I know what I am walking into',
            value: 'controlled',
            signals: ['novelty_with_control'],
          ),
          DiscoveryOption(
            label: 'Surprise me completely',
            value: 'open',
            signals: ['immersive'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'strength',
        text:
            'How strongly does that pull you, from a light preference to a strong one?',
        format: QuestionFormat.rating,
        dimension: 'strength',
        scaleSignal: 'immersive',
      ),
      DiscoveryQuestion(
        id: 'stays',
        text: 'Rank what stays with you. First means it stays longest.',
        format: QuestionFormat.ranking,
        dimension: 'aftertaste',
        options: [
          DiscoveryOption(
            label: 'An idea or a line',
            value: 'idea',
            signals: ['story'],
          ),
          DiscoveryOption(
            label: 'A feeling',
            value: 'feeling',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'The world it built',
            value: 'world',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'The person I watched it with',
            value: 'person',
            signals: ['social_context'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'friend_scenario',
        text: 'What do you do?',
        format: QuestionFormat.scenario,
        dimension: 'company',
        scenario:
            'A friend wants something familiar. You want something you have not seen. Neither choice is better.',
        options: [
          DiscoveryOption(
            label: 'Pick the familiar one together',
            value: 'familiar',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'Try the new one if we can leave it',
            value: 'new_exit',
            signals: ['novelty_with_control'],
          ),
          DiscoveryOption(
            label: 'Watch alone later',
            value: 'alone',
            signals: ['quiet_focus'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'example',
        text: 'Name a film or show that felt like you, if one comes to mind.',
        format: QuestionFormat.shortText,
        dimension: 'example',
      ),
    ],
  ),
  DiscoveryTopic(
    id: 'music',
    label: 'Music',
    blurb: 'What you reach for, not a genre label.',
    dimensions: ['lyrics', 'atmosphere', 'setting'],
    questions: [
      DiscoveryQuestion(
        id: 'reach',
        text: 'What do you reach for first?',
        format: QuestionFormat.choice,
        dimension: 'reach',
        options: [
          DiscoveryOption(
            label: 'Lyrics or a story',
            value: 'lyrics',
            signals: ['story'],
          ),
          DiscoveryOption(
            label: 'An atmosphere',
            value: 'atmosphere',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'A familiar ritual',
            value: 'ritual',
            signals: ['ritual'],
          ),
          DiscoveryOption(
            label: 'Something I have not heard',
            value: 'new',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'setting',
        text: 'Where does that music belong?',
        format: QuestionFormat.eitherOr,
        dimension: 'setting',
        options: [
          DiscoveryOption(
            label: 'Alone, so I can focus',
            value: 'alone',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'With other people',
            value: 'people',
            signals: ['social_context'],
          ),
        ],
      ),
    ],
  ),
  DiscoveryTopic(
    id: 'food',
    label: 'Food and drinks',
    blurb: 'Coffee, chai, or something that depends on the moment.',
    dimensions: ['drink', 'ritual', 'context'],
    questions: [
      DiscoveryQuestion(
        id: 'drink',
        text: 'Coffee, chai, or does it depend?',
        format: QuestionFormat.choice,
        dimension: 'drink',
        options: [
          DiscoveryOption(
            label: 'Coffee',
            value: 'coffee',
            signals: ['ritual'],
          ),
          DiscoveryOption(label: 'Chai', value: 'chai', signals: ['ritual']),
          DiscoveryOption(
            label: 'It depends',
            value: 'depends',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'Neither — something else',
            value: 'other',
            signals: ['quiet_focus'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'decides',
        text: 'What decides it?',
        format: QuestionFormat.choice,
        dimension: 'context',
        whenQuestion: 'drink',
        whenValue: 'depends',
        options: [
          DiscoveryOption(
            label: 'Time of day',
            value: 'time',
            signals: ['ritual'],
          ),
          DiscoveryOption(
            label: 'Who I am with',
            value: 'company',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'What I feel like tasting',
            value: 'taste',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'order',
        text: 'Familiar order, or something new when the basics are right?',
        format: QuestionFormat.eitherOr,
        dimension: 'novelty',
        options: [
          DiscoveryOption(
            label: 'Familiar',
            value: 'familiar',
            signals: ['ritual'],
          ),
          DiscoveryOption(
            label: 'New, if I trust the place',
            value: 'trusted_new',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
    ],
  ),
  DiscoveryTopic(
    id: 'travel',
    label: 'Travel',
    blurb: 'How a trip feels right once you are in it.',
    dimensions: ['plan', 'company', 'novelty'],
    questions: [
      DiscoveryQuestion(
        id: 'right',
        text: 'What makes a trip feel right?',
        format: QuestionFormat.choice,
        dimension: 'right',
        options: [
          DiscoveryOption(
            label: 'A plan for the important parts',
            value: 'plan',
            signals: ['novelty_with_control'],
          ),
          DiscoveryOption(
            label: 'Room to wander',
            value: 'wander',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'The people I am with',
            value: 'people',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'A place I have never been',
            value: 'new',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'lock',
        text:
            'Once the important parts are set, how much uncertainty do you want?',
        format: QuestionFormat.eitherOr,
        dimension: 'control',
        options: [
          DiscoveryOption(
            label: 'Keep the essentials locked',
            value: 'locked',
            signals: ['novelty_with_control'],
          ),
          DiscoveryOption(
            label: 'Figure the rest out there',
            value: 'open',
            signals: ['immersive'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'pull_strength',
        text:
            'How much does being somewhere new matter, when you can still shape the day?',
        format: QuestionFormat.rating,
        dimension: 'novelty',
        scaleSignal: 'novelty_with_control',
      ),
    ],
  ),
  DiscoveryTopic(
    id: 'hobbies',
    label: 'Hobbies',
    blurb: 'What you return to when the time is yours.',
    dimensions: ['activity', 'depth'],
    questions: [
      DiscoveryQuestion(
        id: 'return',
        text: 'What kind of activity do you return to?',
        format: QuestionFormat.choice,
        dimension: 'activity',
        options: [
          DiscoveryOption(
            label: 'Making something',
            value: 'making',
            signals: ['ritual'],
          ),
          DiscoveryOption(
            label: 'Moving',
            value: 'moving',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'Learning a skill',
            value: 'skill',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'Being with people',
            value: 'people',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'Sampling something new',
            value: 'sampling',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'depth',
        text: 'Rank how you like to spend that time.',
        format: QuestionFormat.ranking,
        dimension: 'depth',
        options: [
          DiscoveryOption(
            label: 'Go deeper on one thing',
            value: 'deeper',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'Sample, with a way out',
            value: 'sample',
            signals: ['novelty_with_control'],
          ),
          DiscoveryOption(
            label: 'Do it with someone',
            value: 'together',
            signals: ['social_context'],
          ),
        ],
      ),
    ],
  ),
  DiscoveryTopic(
    id: 'communication',
    label: 'Communication',
    blurb: 'How you want a conversation that matters to happen.',
    dimensions: ['channel', 'context', 'pace'],
    questions: [
      DiscoveryQuestion(
        id: 'channel',
        text: 'For something that matters, what do you reach for?',
        format: QuestionFormat.choice,
        dimension: 'channel',
        options: [
          DiscoveryOption(
            label: 'Text',
            value: 'text',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'A call',
            value: 'call',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'Video',
            value: 'video',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'In person',
            value: 'person',
            signals: ['social_context'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'context',
        text: 'Does that stay the same for friends and for work?',
        format: QuestionFormat.eitherOr,
        dimension: 'context',
        options: [
          DiscoveryOption(
            label: 'Mostly the same',
            value: 'same',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'It depends on the relationship',
            value: 'depends',
            signals: ['social_context'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'want',
        text: 'What do you want from the conversation? A phrase is enough.',
        format: QuestionFormat.shortText,
        dimension: 'want',
      ),
    ],
  ),
  DiscoveryTopic(
    id: 'learning',
    label: 'Learning',
    blurb: 'How you like to understand something new.',
    dimensions: ['method', 'proof'],
    questions: [
      DiscoveryQuestion(
        id: 'how',
        text: 'How do you like to learn something new?',
        format: QuestionFormat.choice,
        dimension: 'method',
        options: [
          DiscoveryOption(
            label: 'A clear path I can follow alone',
            value: 'path',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'Trying it myself',
            value: 'try',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'Someone I trust explaining it',
            value: 'person',
            signals: ['social_context'],
          ),
          DiscoveryOption(
            label: 'A new subject, if I can set the pace',
            value: 'pace',
            signals: ['novelty_with_control'],
          ),
        ],
      ),
      DiscoveryQuestion(
        id: 'stuck',
        text: 'You are stuck on a new idea. What do you do first?',
        format: QuestionFormat.scenario,
        dimension: 'method',
        scenario:
            'There is no wrong move here. This only says what you reach for.',
        options: [
          DiscoveryOption(
            label: 'Sit with it quietly',
            value: 'quiet',
            signals: ['quiet_focus'],
          ),
          DiscoveryOption(
            label: 'Try a small version',
            value: 'try',
            signals: ['immersive'],
          ),
          DiscoveryOption(
            label: 'Ask someone I trust',
            value: 'ask',
            signals: ['social_context'],
          ),
        ],
      ),
    ],
  ),
];

const customTopic = DiscoveryTopic(
  id: 'custom',
  label: 'Your topic',
  blurb: 'Start from your own words.',
  dimensions: ['what matters', 'whether it depends'],
  questions: [
    DiscoveryQuestion(
      id: 'matters',
      text: 'When this shows up in your life, what matters more?',
      format: QuestionFormat.choice,
      dimension: 'matters',
      options: [
        DiscoveryOption(
          label: 'Familiarity',
          value: 'familiar',
          signals: ['ritual'],
        ),
        DiscoveryOption(
          label: 'Something new, with a way out',
          value: 'new',
          signals: ['novelty_with_control'],
        ),
        DiscoveryOption(
          label: 'The people around it',
          value: 'people',
          signals: ['social_context'],
        ),
        DiscoveryOption(
          label: 'The feeling of it',
          value: 'feeling',
          signals: ['immersive'],
        ),
        DiscoveryOption(
          label: 'Being able to focus',
          value: 'focus',
          signals: ['quiet_focus'],
        ),
      ],
    ),
    DiscoveryQuestion(
      id: 'stable',
      text: 'Does this stay the same, or does it depend on the situation?',
      format: QuestionFormat.eitherOr,
      dimension: 'context',
      options: [
        DiscoveryOption(
          label: 'It mostly stays the same',
          value: 'same',
          signals: ['quiet_focus'],
        ),
        DiscoveryOption(
          label: 'It depends on the situation',
          value: 'depends',
          signals: ['social_context'],
        ),
      ],
    ),
    DiscoveryQuestion(
      id: 'words',
      text: 'Is there a word you already use for this? Leave it blank if not.',
      format: QuestionFormat.shortText,
      dimension: 'words',
    ),
  ],
);

const contextChoices = <String>[
  'general',
  'home',
  'work',
  'friends',
  'travel',
  'alone',
];
