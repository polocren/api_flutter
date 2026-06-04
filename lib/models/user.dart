class User {
  const User({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.role,
    this.username,
    this.score,
  });

  final int id;
  final String email;
  final String firstname;
  final String lastname;
  final String role;
  final String? username;
  final int? score;

  String get fullName {
    final name = '$firstname $lastname'.trim();
    return name.isNotEmpty ? name : username ?? '';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['id']),
      email: json['email']?.toString() ?? '',
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      username: json['username']?.toString(),
      score: json['score'] == null ? null : _asInt(json['score']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
