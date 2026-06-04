import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _loading = true;
  bool _authenticated = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _loadSession();
    }
  }

  Future<void> _loadSession() async {
    // Au lancement, on évite un appel /me si aucun token n'est stocké.
    final token = await AppScope.of(
      context,
    ).authService.tokenStorage.readToken();
    if (!mounted) {
      return;
    }
    setState(() {
      _authenticated = token?.isNotEmpty ?? false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _authenticated ? const MainShellScreen() : const LoginScreen();
  }
}
