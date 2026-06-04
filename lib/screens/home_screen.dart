import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import '../widgets/error_banner.dart';
import '../widgets/session_guard.dart';
import 'login_screen.dart';
import 'theme_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onStartQuiz});

  final VoidCallback? onStartQuiz;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SessionGuard {
  Future<User>? _userFuture;
  Future<List<User>>? _leaderboardFuture;
  Future<List<Quiz>>? _historyFuture;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load() {
    if (_userFuture != null &&
        _leaderboardFuture != null &&
        _historyFuture != null) {
      return;
    }

    final scope = AppScope.of(context);
    _userFuture = scope.authService.me();
    _leaderboardFuture = scope.quizService.leaderboard();
    _historyFuture = scope.quizService.history();
  }

  Future<void> _logout() async {
    await AppScope.of(context).authService.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    final scope = AppScope.of(context);
    setState(() {
      _error = null;
      _userFuture = scope.authService.me();
      _leaderboardFuture = scope.quizService.leaderboard();
      _historyFuture = scope.quizService.history();
    });

    await Future.wait<void>([
      _userFuture!.then((_) {}).catchError((_) {}),
      _leaderboardFuture!.then((_) {}).catchError((_) {}),
      _historyFuture!.then((_) {}).catchError((_) {}),
    ]);
  }

  void _startQuiz() {
    if (widget.onStartQuiz != null) {
      widget.onStartQuiz!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ThemeSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              FutureBuilder<User>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        handleError(snapshot.error!, (message) {
                          setState(() => _error = message);
                        });
                      }
                    });
                  }

                  final user = snapshot.data;
                  return _HeroPanel(
                    user: user,
                    loading: snapshot.connectionState != ConnectionState.done,
                    onStartQuiz: _startQuiz,
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Quiz>>(
                future: _historyFuture,
                builder: (context, snapshot) {
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
                  final bestScore = quizzes.fold<int>(0, (best, quiz) {
                    final score = quiz.computedScore ?? quiz.finalScore ?? 0;
                    return score > best ? score : best;
                  });
                  final averageScore = quizzes.isEmpty
                      ? 0
                      : (quizzes
                                    .map(
                                      (quiz) =>
                                          quiz.computedScore ??
                                          quiz.finalScore ??
                                          0,
                                    )
                                    .reduce((a, b) => a + b) /
                                quizzes.length)
                            .round();

                  return Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.emoji_events_outlined,
                          label: 'Meilleur',
                          value: '$bestScore pts',
                          color: colorScheme.secondary,
                          loading:
                              snapshot.connectionState != ConnectionState.done,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.timeline,
                          label: 'Moyenne',
                          value: '$averageScore pts',
                          color: colorScheme.tertiary,
                          loading:
                              snapshot.connectionState != ConnectionState.done,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Classement',
                icon: Icons.leaderboard_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<User>>(
                future: _leaderboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _LoadingList();
                  }
                  if (snapshot.hasError) {
                    return ErrorBanner(message: snapshot.error.toString());
                  }

                  final users = snapshot.data ?? const <User>[];
                  if (users.isEmpty) {
                    return const _EmptyPanel(
                      icon: Icons.leaderboard_outlined,
                      text: 'Classement vide.',
                    );
                  }

                  return Column(
                    children: users.take(5).indexed.map((entry) {
                      final rank = entry.$1 + 1;
                      final user = entry.$2;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RankTile(rank: rank, user: user),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.user,
    required this.loading,
    required this.onStartQuiz,
  });

  final User? user;
  final bool loading;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user == null
        ? 'Joueur'
        : user!.fullName.isEmpty
        ? user!.email
        : user!.fullName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF12332F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                child: Text(
                  displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loading ? 'Chargement...' : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFBFE8DE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Score total',
                  value: '${user?.score ?? 0} pts',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStartQuiz,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Nouveau quiz'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

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
          Text(label, style: const TextStyle(color: Color(0xFFBFE8DE))),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    loading ? '...' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.user});

  final int rank;
  final User user;

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.isEmpty ? user.email : user.fullName;
    final color = switch (rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF64748B),
      3 => const Color(0xFFB45309),
      _ => Theme.of(context).colorScheme.primary,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Text('$rank'),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${user.score ?? 0} pts',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [LinearProgressIndicator(), SizedBox(height: 8)],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
