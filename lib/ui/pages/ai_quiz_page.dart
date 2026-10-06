import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_events.dart';
import '../../bloc/app_states.dart';
import '../common_ui_components/input_surface.dart';

class AiQuizHomePage extends StatefulWidget {
  const AiQuizHomePage({super.key});

  @override
  State<AiQuizHomePage> createState() => _AiQuizHomePageState();
}

class _AiQuizHomePageState extends State<AiQuizHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  final _topicController = TextEditingController();

  @override
  void dispose() {
    _courseController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AppBloc>().add(AiQuizGenerateRequested(
          courseName: _courseController.text,
          topicName: _topicController.text,
        ));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.generateAiQuiz &&
            current.actionStatus != previous.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).push<void>(MaterialPageRoute<void>(
              builder: (_) => const AiQuizTakePage(),
            ));
          } else if (state.actionStatus == AppActionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.errorMessage ?? 'Could not generate the quiz.'),
              duration: const Duration(seconds: 5),
            ));
          }
        },
        buildWhen: (previous, current) =>
            current.action == AppAction.generateAiQuiz &&
            previous.actionStatus != current.actionStatus,
        builder: (context, state) {
          final generating = state.action == AppAction.generateAiQuiz &&
              state.actionStatus == AppActionStatus.pending;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Back to dashboard',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text('AI Quiz'),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 32),
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 38,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Create a practice quiz',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a course and topic. CampusMate will prepare 10 questions for a quick self-test.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 28),
                        InputSurface(
                          child: TextFormField(
                            controller: _courseController,
                            enabled: !generating,
                            maxLength: 120,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Course name',
                              hintText: 'For example, DSA',
                              prefixIcon: Icon(Icons.menu_book_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter the course name.'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputSurface(
                          child: TextFormField(
                            controller: _topicController,
                            enabled: !generating,
                            maxLength: 160,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Topic name',
                              hintText: 'What should the quiz cover?',
                              prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter the quiz topic.'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: generating ? null : _generate,
                            icon: generating
                                ? const SizedBox.square(
                                    dimension: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome_rounded),
                            label: Text(
                                generating ? 'Generating quiz…' : 'Generate Quiz'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class AiQuizTakePage extends StatefulWidget {
  const AiQuizTakePage({super.key});

  @override
  State<AiQuizTakePage> createState() => _AiQuizTakePageState();
}

class _AiQuizTakePageState extends State<AiQuizTakePage> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(AppState state) {
    if (state.quizQuestions.isEmpty ||
        state.quizAnswers.length != state.quizQuestions.length ||
        state.quizAnswers[_currentIndex] == null) {
      return;
    }
    if (_currentIndex == state.quizQuestions.length - 1) {
      var score = 0;
      for (var index = 0; index < state.quizQuestions.length; index++) {
        if (state.quizAnswers[index] ==
            state.quizQuestions[index]['correctIndex']) {
          score++;
        }
      }
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => AiQuizResultsPage(
            score: score,
            total: state.quizQuestions.length,
          ),
        ),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        buildWhen: (previous, current) =>
            previous.quizQuestions != current.quizQuestions ||
            previous.quizAnswers != current.quizAnswers ||
            previous.quizCourseName != current.quizCourseName ||
            previous.quizTopicName != current.quizTopicName,
        builder: (context, state) {
          final questions = state.quizQuestions;
          if (questions.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('AI Quiz')),
              body: Center(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to quiz setup'),
                ),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('AI Quiz'),
              leading: IconButton(
                tooltip: 'Back to quiz setup',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.quizTopicName ?? 'Quiz topic',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.quizCourseName ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(questions.length, (index) {
                              final active = index == _currentIndex;
                              final answered = state.quizAnswers[index] != null;
                              final canRevisit = index < _currentIndex && answered;
                              final colors = Theme.of(context).colorScheme;
                              return Semantics(
                                button: canRevisit,
                                enabled: canRevisit,
                                label: 'Question ${index + 1}${active ? ', current' : canRevisit ? ', answered' : ', upcoming'}',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: canRevisit
                                      ? () => _pageController.animateToPage(
                                            index,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOutCubic,
                                          )
                                      : null,
                                  child: Container(
                                    width: 37,
                                    height: 38,
                                    margin: EdgeInsets.only(
                                      right: index == questions.length - 1
                                          ? 0
                                          : 8,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? colors.primary
                                          : colors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: active
                                            ? colors.primary
                                            : canRevisit
                                                ? colors.primary
                                                : colors.outlineVariant,
                                      ),
                                      boxShadow: active
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: colors.shadow
                                                    .withValues(alpha: .12),
                                                blurRadius: 3,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: active
                                                ? colors.onPrimary
                                                : canRevisit
                                                    ? colors.primary
                                                    : colors.onSurfaceVariant,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 11),
                        LinearProgressIndicator(
                          value: (_currentIndex + 1) / questions.length,
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 5,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final options = question['options'] as List<dynamic>;
                        final selected = state.quizAnswers[index];
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QUESTION ${index + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .8,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                question['question'] as String,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 24),
                              ...List.generate(options.length, (optionIndex) {
                                final isSelected = selected == optionIndex;
                                final colors = Theme.of(context).colorScheme;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    color: isSelected
                                        ? colors.primaryContainer
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(17),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(17),
                                      onTap: () => context.read<AppBloc>().add(
                                        AiQuizAnswerSelected(
                                          questionIndex: index,
                                          optionIndex: optionIndex,
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(17),
                                          border: Border.all(
                                            color: isSelected
                                                ? colors.primary
                                                : colors.outlineVariant,
                                            width: isSelected ? 1.6 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 26,
                                              height: 26,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? colors.primary
                                                    : colors
                                                        .surfaceContainerHighest,
                                              ),
                                              child: Text(
                                                String.fromCharCode(65 + optionIndex),
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? colors.onPrimary
                                                      : colors.onSurfaceVariant,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                options[optionIndex] as String,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      color: isSelected
                                                          ? colors
                                                              .onPrimaryContainer
                                                          : colors.onSurface,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(Icons.check_circle_rounded,
                                                  color: colors.primary),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: state.quizAnswers[_currentIndex] == null
                            ? null
                            : () => _next(state),
                        icon: Icon(_currentIndex == questions.length - 1
                            ? Icons.flag_rounded
                            : Icons.arrow_forward_rounded),
                        label: Text(_currentIndex == questions.length - 1
                            ? 'Finish Quiz'
                            : 'Next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class AiQuizResultsPage extends StatelessWidget {
  const AiQuizResultsPage({super.key, required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (score * 100 / total).round();
    final Color resultColor;
    final String resultLabel;
    if (percentage >= 80) {
      resultColor = const Color(0xFF2E8B57);
      resultLabel = percentage >= 90 ? 'Excellent!' : 'Great work!';
    } else if (percentage >= 50) {
      resultColor = const Color(0xFFE18417);
      resultLabel = percentage >= 65 ? 'Average' : 'Needs Improvement';
    } else {
      resultColor = const Color(0xFFC62828);
      resultLabel = 'Very Bad Performance';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz results')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your score',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 224,
                  height: 224,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: resultColor, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: resultColor.withValues(alpha: .18),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score / $total',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: resultColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: resultColor.withValues(alpha: .88),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  resultLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'You answered $score of $total questions correctly.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () {
                      context.read<AppBloc>().add(AiQuizSessionCleared());
                      Navigator.of(context).pop();
                    },
                    child: const Text('Finish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
