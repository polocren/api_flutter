class Question {
  const Question({
    required this.id,
    required this.label,
    required this.options,
    this.themeId,
    this.themeLabel,
    this.answer,
    this.userAnswer,
    this.isCorrect,
  });

  final int id;
  final int? themeId;
  final String? themeLabel;
  final String label;
  final List<String> options;
  final String? answer;
  final String? userAnswer;
  final bool? isCorrect;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: _asInt(json['id']),
      themeId: json['theme_id'] == null ? null : _asInt(json['theme_id']),
      themeLabel: _themeLabel(json['theme']),
      label: (json['label'] ?? json['question'] ?? json['title'] ?? '')
          .toString(),
      options: _parseOptions(json),
      answer: _answer(json),
      userAnswer: json['user_answer']?.toString(),
      isCorrect: _asBool(json['is_correct']),
    );
  }

  static List<String> _parseOptions(Map<String, dynamic> json) {
    final value =
        json['proposals'] ??
        json['options'] ??
        json['choices'] ??
        json['answers'];
    if (value is List) {
      return value.map((option) => option.toString()).toList();
    }

    final fallback = <String>[];
    for (final key in ['choice_a', 'choice_b', 'choice_c', 'choice_d']) {
      final option = json[key];
      if (option != null) {
        fallback.add(option.toString());
      }
    }
    return fallback;
  }

  static String? _themeLabel(Object? theme) {
    if (theme is Map && theme['label'] != null) {
      return theme['label'].toString();
    }
    return null;
  }

  static String? _answer(Map<String, dynamic> json) {
    final directAnswer = json['answer'] ?? json['correct_answer'];
    if (directAnswer != null) {
      return directAnswer.toString();
    }

    for (final key in ['pivot', 'quiz_question']) {
      final nested = json[key];
      if (nested is Map && nested['answer'] != null) {
        return nested['answer'].toString();
      }
    }

    return null;
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value == null) {
      return null;
    }
    return value.toString() == 'true' || value.toString() == '1';
  }
}
