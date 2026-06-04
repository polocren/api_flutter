import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/user.dart';
import '../widgets/error_banner.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Future<List<User>>? _leaderboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _leaderboardFuture ??= AppScope.of(context).quizService.leaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: SafeArea(
        child: FutureBuilder<List<User>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorBanner(message: snapshot.error.toString()),
              );
            }

            final users = snapshot.data ?? const <User>[];
            if (users.isEmpty) {
              return const Center(child: Text('Classement vide.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      user.fullName.isEmpty ? user.email : user.fullName,
                    ),
                    subtitle: Text(user.email),
                    trailing: Text(
                      '${user.score ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
