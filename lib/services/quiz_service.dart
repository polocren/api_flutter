import '../models/question.dart';
import '../models/quiz.dart';
import '../models/quiz_theme.dart';
import '../models/user.dart';
import 'api_client.dart';

class QuizService {
  QuizService({required this.apiClient});

  final ApiClient apiClient;

  Future<List<QuizTheme>> themes() async {
    final data = await apiClient.get('/quiz/themes');
    return _list(data).map(QuizTheme.fromJson).toList();
  }

  Future<List<Question>> questions({int? themeId}) async {
    final path = themeId == null
        ? '/quiz/questions'
        : '/quiz/questions?theme_id=$themeId';
    final data = await apiClient.get(path);
    return _list(data).map(Question.fromJson).toList();
  }

  Future<Quiz> startQuiz({int? themeId, required int questionLimit}) async {
    final data = await apiClient.post(
      '/quiz/quizzes/start',
      authenticated: true,
      body: {'theme_id': themeId, 'question_limit': questionLimit},
    );
    return _quiz(data);
  }

  Future<Quiz> submitQuiz({
    required int quizId,
    required Map<int, String> selectedAnswers,
  }) async {
    final data = await apiClient.post(
      '/quiz/quizzes/$quizId/submit',
      authenticated: true,
      body: {
        'answers': selectedAnswers.entries
            .map(
              (entry) => {'question_id': entry.key, 'user_answer': entry.value},
            )
            .toList(),
      },
    );
    return _quiz(data);
  }

  Future<List<Quiz>> history() async {
    final data = await apiClient.get('/quiz/quizzes', authenticated: true);
    return _list(data).map(Quiz.fromJson).toList();
  }

  Future<List<User>> leaderboard() async {
    final data = await apiClient.get('/users/leaderboard');
    return _list(data).map(User.fromJson).toList();
  }

  Quiz _quiz(Object? data) {
    if (data is Map<String, dynamic>) {
      return Quiz.fromJson(data);
    }
    throw StateError('Format quiz invalide.');
  }

  List<Map<String, dynamic>> _list(Object? data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}
