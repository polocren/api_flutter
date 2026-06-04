import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/quiz_theme.dart';
import '../widgets/error_banner.dart';
import '../widgets/session_guard.dart';
import 'quiz_screen.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen>
    with SessionGuard {
  Future<List<QuizTheme>>? _themesFuture;
  bool _starting = false;
  String? _error;
  int _questionLimit = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themesFuture ??= AppScope.of(context).quizService.themes();
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _themesFuture = AppScope.of(context).quizService.themes();
    });
    await _themesFuture!.catchError((_) => <QuizTheme>[]);
  }

  Future<void> _start({int? themeId}) async {
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final quiz = await AppScope.of(
        context,
      ).quizService.startQuiz(themeId: themeId, questionLimit: _questionLimit);

      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => QuizScreen(quiz: quiz)));
    } catch (error) {
      if (mounted) {
        handleError(error, (message) => setState(() => _error = message));
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<QuizTheme>>(
            future: _themesFuture,
            builder: (context, snapshot) {
              final themes = snapshot.data ?? const <QuizTheme>[];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_error != null) ...[
                    ErrorBanner(message: _error!),
                    const SizedBox(height: 12),
                  ],
                  Container(
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
                              child: const Icon(Icons.tune),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Configuration',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [5, 10, 15, 20].map((value) {
                            return ChoiceChip(
                              label: Text('$value questions'),
                              selected: _questionLimit == value,
                              onSelected: _starting
                                  ? null
                                  : (_) {
                                      setState(() => _questionLimit = value);
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _starting ? null : () => _start(),
                          icon: const Icon(Icons.shuffle),
                          label: Text(
                            _starting ? 'Démarrage...' : 'Quiz aléatoire',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Thèmes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    ErrorBanner(message: snapshot.error.toString())
                  else if (themes.isEmpty)
                    const _EmptyThemes()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 720;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: themes.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: wide ? 2 : 1,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: wide ? 3.0 : 2.7,
                              ),
                          itemBuilder: (context, index) {
                            final theme = themes[index];
                            return _ThemeCard(
                              theme: theme,
                              enabled: !_starting,
                              onTap: () => _start(themeId: theme.id),
                            );
                          },
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.enabled,
    required this.onTap,
  });

  final QuizTheme theme;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _themeVisual(theme.label);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: visual.color.withValues(alpha: 0.12),
                ),
                clipBehavior: Clip.antiAlias,
                child: visual.assetPath == null
                    ? Icon(visual.icon, color: visual.color, size: 34)
                    : Image.asset(
                        visual.assetPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            visual.icon,
                            color: visual.color,
                            size: 34,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${theme.questionsCount} questions'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: visual.color),
            ],
          ),
        ),
      ),
    );
  }

  _ThemeVisual _themeVisual(String label) {
    final normalized = label
        .toLowerCase()
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ùûü]'), 'u')
        .replaceAll('ç', 'c');

    if (normalized.contains('auto') ||
        normalized.contains('voiture') ||
        normalized.contains('moto')) {
      return const _ThemeVisual(
        Icons.directions_car_outlined,
        Color(0xFF0F766E),
        'assets/themes/automobile.jpg',
      );
    }
    if (normalized.contains('culture') || normalized.contains('general')) {
      return const _ThemeVisual(
        Icons.psychology_outlined,
        Color(0xFF475569),
        'assets/themes/culture-generale.jpg',
      );
    }
    if (normalized.contains('informatique') ||
        normalized.contains('code') ||
        normalized.contains('tech') ||
        normalized.contains('ordinateur')) {
      return const _ThemeVisual(
        Icons.computer_outlined,
        Color(0xFF2563EB),
        'assets/themes/informatique.jpg',
      );
    }
    if (normalized.contains('litterature') ||
        normalized.contains('livre') ||
        normalized.contains('roman')) {
      return const _ThemeVisual(
        Icons.menu_book_outlined,
        Color(0xFF7C3AED),
        'assets/themes/litterature.webp',
      );
    }
    if (normalized.contains('sport') ||
        normalized.contains('football') ||
        normalized.contains('basket')) {
      return const _ThemeVisual(Icons.sports_soccer, Color(0xFF16A34A));
    }
    if (normalized.contains('cinema') ||
        normalized.contains('film') ||
        normalized.contains('movie')) {
      return const _ThemeVisual(
        Icons.movie_creation_outlined,
        Color(0xFFDC2626),
        'assets/themes/film.jpeg',
      );
    }
    if (normalized.contains('musique') ||
        normalized.contains('music') ||
        normalized.contains('chanson')) {
      return const _ThemeVisual(Icons.music_note, Color(0xFF7C3AED));
    }
    if (normalized.contains('histoire') || normalized.contains('history')) {
      return const _ThemeVisual(
        Icons.account_balance,
        Color(0xFFB45309),
        'assets/themes/histoire.jpg',
      );
    }
    if (normalized.contains('science') ||
        normalized.contains('physique') ||
        normalized.contains('chimie')) {
      return const _ThemeVisual(Icons.science_outlined, Color(0xFF0891B2));
    }
    if (normalized.contains('jeu') ||
        normalized.contains('gaming') ||
        normalized.contains('video')) {
      return const _ThemeVisual(
        Icons.sports_esports_outlined,
        Color(0xFF2563EB),
      );
    }
    if (normalized.contains('geo') || normalized.contains('monde')) {
      return const _ThemeVisual(Icons.public, Color(0xFF0F766E));
    }
    if (normalized.contains('manga') ||
        normalized.contains('anime') ||
        normalized.contains('dragon')) {
      return const _ThemeVisual(
        Icons.auto_stories_outlined,
        Color(0xFFE11D48),
        'assets/themes/manga.jpg',
      );
    }

    return const _ThemeVisual(Icons.category_outlined, Color(0xFF475569));
  }
}

class _ThemeVisual {
  const _ThemeVisual(this.icon, this.color, [this.assetPath]);

  final IconData icon;
  final Color color;
  final String? assetPath;
}

class _EmptyThemes extends StatelessWidget {
  const _EmptyThemes();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.category_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('Aucun thème disponible.')),
          ],
        ),
      ),
    );
  }
}
