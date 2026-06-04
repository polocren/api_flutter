import 'question.dart';

class Quiz {
  const Quiz({
    required this.id,
    required this.questions,
    this.themeId,
    this.finalScore,
    this.createdAt,
  });

  final int id;
  final int? themeId;
  final int? finalScore;
  final DateTime? createdAt;
  final List<Question> questions;

  bool get isRandom => themeId == null;

  int get pointsPerCorrectAnswer => isRandom ? 2 : 1;

  int? get computedScore {
    // le back peut déjà renvoyer le score final.
    if (questions.any((question) => question.isCorrect == null)) {
      return finalScore;
    }
    final correctAnswers = questions
        .where((question) => question.isCorrect == true)
        .length;
    return correctAnswers * pointsPerCorrectAnswer;
  }

  int get maxScore => questions.length * pointsPerCorrectAnswer;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'];

    return Quiz(
      id: _asInt(json['id']),
      themeId: json['theme_id'] == null ? null : _asInt(json['theme_id']),
      finalScore: json['final_score'] == null
          ? null
          : _asInt(json['final_score']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      questions: questionsJson is List
          ? questionsJson
                .whereType<Map>()
                .map(
                  (item) => Question.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
