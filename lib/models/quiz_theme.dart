class QuizTheme {
  const QuizTheme({
    required this.id,
    required this.label,
    required this.questionsCount,
  });

  final int id;
  final String label;
  final int questionsCount;

  factory QuizTheme.fromJson(Map<String, dynamic> json) {
    return QuizTheme(
      id: _asInt(json['id']),
      label: json['label']?.toString() ?? '',
      questionsCount: _asInt(json['questions_count']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
