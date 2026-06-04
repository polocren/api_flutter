import '../models/user.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';

class AuthService {
  AuthService({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<void> register({
    required String email,
    required String firstname,
    required String lastname,
    required String role,
    required String password,
    required String passwordConfirmation,
  }) async {
    await apiClient.post(
      '/auth/register',
      body: {
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'role': role,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<void> login({required String email, required String password}) async {
    final data = await apiClient.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    final token = _extractToken(data);
    if (token == null || token.isEmpty) {
      throw StateError('Token absent dans la réponse de connexion.');
    }

    await tokenStorage.saveToken(token);
  }

  Future<User> me() async {
    final data = await apiClient.get('/users/me', authenticated: true);
    if (data is Map<String, dynamic>) {
      return User.fromJson(data);
    }
    throw StateError('Format utilisateur invalide.');
  }

  Future<void> logout() => tokenStorage.clearToken();

  String? _extractToken(Object? data) {
    if (data is Map<String, dynamic>) {
      return data['access_token']?.toString();
    }
    return null;
  }
}
