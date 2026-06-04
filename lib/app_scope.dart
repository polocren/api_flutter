import 'package:flutter/widgets.dart';

import 'services/auth_service.dart';
import 'services/quiz_service.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.authService,
    required this.quizService,
    required super.child,
  });

  final AuthService authService;
  final QuizService quizService;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope absent du contexte.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return authService != oldWidget.authService ||
        quizService != oldWidget.quizService;
  }
}
