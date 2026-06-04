import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/question.dart';
import '../models/quiz.dart';
import '../widgets/error_banner.dart';
import '../widgets/session_guard.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.quiz});

  final Quiz quiz;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SessionGuard {
  final Map<int, String> selectedAnswers = <int, String>{};

  bool _submitting = false;
  String? _error;

  bool get _canSubmit {
    return widget.quiz.questions.isNotEmpty &&
        selectedAnswers.length == widget.quiz.questions.length;
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await AppScope.of(context).quizService.submitQuiz(
        quizId: widget.quiz.id,
        selectedAnswers: selectedAnswers,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ResultScreen(quiz: result)),
      );
    } catch (error) {
      if (mounted) {
        handleError(error, (message) => setState(() => _error = message));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quiz.questions;
    final progress = questions.isEmpty
        ? 0.0
        : selectedAnswers.length / questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz en cours')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: questions.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressPanel(
                    quiz: widget.quiz,
                    answered: selectedAnswers.length,
                    progress: progress,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    ErrorBanner(message: _error!),
                  ],
                  if (questions.isEmpty) ...[
                    const SizedBox(height: 12),
                    const ErrorBanner(message: 'Aucune question disponible.'),
                  ],
                  const SizedBox(height: 14),
                ],
              );
            }

            if (index == questions.length + 1) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.icon(
                  onPressed: _submitting || !_canSubmit ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _submitting ? 'Validation...' : 'Valider mes réponses',
                  ),
                ),
              );
            }

            final question = questions[index - 1];
            return _QuestionCard(
              index: index,
              total: questions.length,
              question: question,
              selectedAnswer: selectedAnswers[question.id],
              onChanged: _submitting
                  ? null
                  : (answer) {
                      setState(() {
                        if (answer == null || answer.isEmpty) {
                          selectedAnswers.remove(question.id);
                        } else {
                          selectedAnswers[question.id] = answer;
                        }
                      });
                    },
            );
          },
        ),
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.quiz,
    required this.answered,
    required this.progress,
  });

  final Quiz quiz;
  final int answered;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Icon(quiz.isRandom ? Icons.shuffle : Icons.category),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.isRandom ? 'Quiz aléatoire' : 'Quiz thématique',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${quiz.pointsPerCorrectAnswer} pt par bonne réponse'),
                  ],
                ),
              ),
              Text(
                '$answered/${quiz.questions.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFE8EEF6),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.selectedAnswer,
    required this.onChanged,
  });

  final int index;
  final int total;
  final Question question;
  final String? selectedAnswer;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final options = question.options;
    final answer = question.answer;
    final hasSelection = selectedAnswer != null && selectedAnswer!.isNotEmpty;
    final answerKnown = answer != null && answer.isNotEmpty;
    final selectedIsCorrect =
        hasSelection && answerKnown && _sameAnswer(selectedAnswer!, answer);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Question $index/$total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (question.themeLabel != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      question.themeLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              question.label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (options.isEmpty)
              TextFormField(
                enabled: onChanged != null,
                initialValue: selectedAnswer,
                decoration: const InputDecoration(
                  labelText: 'Réponse',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                onChanged: onChanged == null
                    ? null
                    : (value) {
                        final trimmed = value.trim();
                        onChanged!(trimmed.isEmpty ? null : trimmed);
                      },
              )
            else
              RadioGroup<String>(
                groupValue: selectedAnswer,
                onChanged: (value) => onChanged?.call(value),
                child: Column(
                  children: options
                      .map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            value: option,
                            enabled: onChanged != null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: _optionBorderColor(context, option),
                              ),
                            ),
                            tileColor: _optionColor(context, option),
                            title: Text(option),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (hasSelection && answerKnown) ...[
              const SizedBox(height: 4),
              _AnswerFeedback(correct: selectedIsCorrect, answer: answer),
            ],
          ],
        ),
      ),
    );
  }

  Color _optionBorderColor(BuildContext context, String option) {
    if (selectedAnswer == null) {
      return const Color(0xFFE1E7EF);
    }

    if (question.answer == null || question.answer!.isEmpty) {
      return selectedAnswer == option
          ? Theme.of(context).colorScheme.primary
          : const Color(0xFFE1E7EF);
    }

    if (_sameAnswer(option, question.answer!)) {
      return const Color(0xFF16A34A);
    }

    if (selectedAnswer == option) {
      return const Color(0xFFDC2626);
    }

    return const Color(0xFFE1E7EF);
  }

  Color _optionColor(BuildContext context, String option) {
    if (selectedAnswer == null) {
      return Colors.white;
    }

    if (question.answer == null || question.answer!.isEmpty) {
      return selectedAnswer == option
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.white;
    }

    if (_sameAnswer(option, question.answer!)) {
      return const Color(0xFFEAF7EF);
    }

    if (selectedAnswer == option) {
      return const Color(0xFFFDECEC);
    }

    return Colors.white;
  }

  bool _sameAnswer(String first, String second) {
    return first.trim().toLowerCase() == second.trim().toLowerCase();
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({required this.correct, required this.answer});

  final bool correct;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              correct ? 'Bonne réponse.' : 'Bonne réponse : $answer',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
