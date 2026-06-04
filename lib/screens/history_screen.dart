import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quiz.dart';
import '../widgets/error_banner.dart';
import '../widgets/session_guard.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SessionGuard {
  Future<List<Quiz>>? _historyFuture;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyFuture ??= AppScope.of(context).quizService.history();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _historyFuture = AppScope.of(context).quizService.history();
    });
    await _historyFuture!.catchError((_) => <Quiz>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anciens quiz')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Quiz>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    handleError(snapshot.error!, (message) {
                      setState(() => _error = message);
                    });
                  }
                });
              }

              final quizzes = snapshot.data ?? const <Quiz>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_error != null) ...[
                    ErrorBanner(message: _error!),
                    const SizedBox(height: 12),
                  ],
                  if (quizzes.isEmpty && _error == null)
                    const _EmptyHistory()
                  else
                    ...quizzes.map(_HistoryTile.new),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile(this.quiz);

  final Quiz quiz;

  @override
  Widget build(BuildContext context) {
    final score = quiz.computedScore ?? quiz.finalScore ?? 0;
    final total = quiz.maxScore;
    final color = quiz.isRandom
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(quiz.isRandom ? Icons.shuffle : Icons.category),
          ),
          title: Text(
            'Score : $score / $total',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${quiz.isRandom ? 'Aléatoire' : 'Thématique'}'
            ' • ${quiz.questions.length} questions'
            '${quiz.createdAt == null ? '' : ' • ${_formatDate(quiz.createdAt!)}'}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: quiz.questions.isEmpty
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResultScreen(quiz: quiz),
                  ),
                ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.history_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('Aucun quiz terminé.')),
          ],
        ),
      ),
    );
  }
}
