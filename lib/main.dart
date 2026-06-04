import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_scope.dart';
import 'screens/start_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/quiz_service.dart';
import 'storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(MyApp(apiBaseUrl: dotenv.env['API_BASE_URL'] ?? ''));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required String apiBaseUrl}) {
    _apiClient = ApiClient(
      tokenStorage: _tokenStorage,
      baseUrl: _normalizeApiBaseUrl(apiBaseUrl),
    );
  }

  final TokenStorage _tokenStorage = TokenStorage();
  late final ApiClient _apiClient;

  static String _normalizeApiBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(
      apiClient: _apiClient,
      tokenStorage: _tokenStorage,
    );

    return AppScope(
      authService: authService,
      quizService: QuizService(apiClient: _apiClient),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quiz Laravel',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            primary: const Color(0xFF0F766E),
            secondary: const Color(0xFFF97316),
            tertiary: const Color(0xFF2563EB),
          ),
          scaffoldBackgroundColor: const Color(0xFFF6F8FB),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Color(0xFFF6F8FB),
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE1E7EF)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        home: const StartScreen(),
      ),
    );
  }
}
