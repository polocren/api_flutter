import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required this.tokenStorage,
    http.Client? httpClient,
    required this.baseUrl,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final http.Client _httpClient;

  Future<Object?> get(String path, {bool authenticated = false}) {
    return _send('GET', path, authenticated: authenticated);
  }

  Future<Object?> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'Session expirée. Connectez-vous à nouveau.',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final response = switch (method) {
      'GET' => await _httpClient.get(uri, headers: headers),
      'POST' => await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
      _ => throw ArgumentError('Méthode HTTP non supportée: $method'),
    };

    // L'API renvoie toujours une enveloppe { success, data, message, errors }.
    final envelope = _decodeEnvelope(response.body);
    final success = envelope['success'] == true;

    if (response.statusCode >= 200 && response.statusCode < 300 && success) {
      return envelope['data'];
    }

    if (response.statusCode == 401) {
      await tokenStorage.clearToken();
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _errorMessage(response.statusCode, envelope),
      errors: envelope['errors'],
    );
  }

  Map<String, dynamic> _decodeEnvelope(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  String _errorMessage(int statusCode, Map<String, dynamic> envelope) {
    final validationMessage = _firstValidationError(envelope['errors']);
    if (validationMessage != null) {
      return validationMessage;
    }

    final message = envelope['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return switch (statusCode) {
      401 => 'Session expirée. Connectez-vous à nouveau.',
      404 => 'Ressource introuvable.',
      422 => 'Les données envoyées sont invalides.',
      500 => 'Erreur serveur. Réessayez plus tard.',
      _ => 'Une erreur est survenue.',
    };
  }

  String? _firstValidationError(Object? errors) {
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    if (errors is String && errors.isNotEmpty) {
      return errors;
    }
    return null;
  }
}
