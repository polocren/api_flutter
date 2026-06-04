import 'package:flutter/material.dart';

import '../models/question.dart';
import '../models/quiz.dart';
import 'main_shell_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.quiz});

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final score = quiz.computedScore ?? quiz.finalScore ?? 0;
    final total = quiz.maxScore;
    final correctAnswers = quiz.questions
        .where((question) => question.isCorrect == true)
        .length;
    final percent = total == 0 ? 0 : ((score / total) * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF12332F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score : $score / $total',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultStat(
                          icon: Icons.check_circle_outline,
                          label: 'Bonnes réponses',
                          value: '$correctAnswers/${quiz.questions.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ResultStat(
                          icon: quiz.isRandom ? Icons.shuffle : Icons.category,
                          label: 'Barème',
                          value: '${quiz.pointsPerCorrectAnswer} pt',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Correction',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...quiz.questions.map(_ResultQuestionCard.new),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const MainShellScreen(initialIndex: 2),
                ),
                (route) => false,
              ),
              icon: const Icon(Icons.history),
              label: const Text('Voir anciens quiz'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const MainShellScreen(),
                ),
                (route) => false,
              ),
              icon: const Icon(Icons.home),
              label: const Text('Retour à l’accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFBFE8DE)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Color(0xFFBFE8DE))),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultQuestionCard extends StatelessWidget {
  const _ResultQuestionCard(this.question);

  final Question question;

  @override
  Widget build(BuildContext context) {
    final correct = question.isCorrect == true;
    final color = correct ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(correct ? Icons.check : Icons.close),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Votre réponse : ${question.userAnswer ?? '-'}'),
                  const SizedBox(height: 2),
                  Text('Bonne réponse : ${question.answer ?? '-'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
