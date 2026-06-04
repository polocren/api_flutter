class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  final int statusCode;
  final String message;
  final Object? errors;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
