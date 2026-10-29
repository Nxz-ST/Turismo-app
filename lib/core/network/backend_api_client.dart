import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';

class BackendApiException implements Exception {
  final int? statusCode;
  final String message;

  const BackendApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BackendApiClient {
  BackendApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  String get _accessToken {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw const BackendApiException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return token;
  }

  Map<String, String> get authenticatedImageHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, String> get _jsonHeaders => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = AppEnvironment.apiBaseUrl.replaceAll(
      RegExp(r'/+$'),
      '',
    );
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse('$normalizedBase$normalizedPath');
    if (query == null) return baseUri;
    return baseUri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _httpClient
        .get(uri(path, query), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 45));
    return _decode(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _httpClient
        .post(
          uri(path),
          headers: _jsonHeaders,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 45));
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await _httpClient
        .patch(
          uri(path),
          headers: _jsonHeaders,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 45));
    return _decode(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await _httpClient
        .put(
          uri(path),
          headers: _jsonHeaders,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 45));
    return _decode(response);
  }

  Future<void> uploadFile({
    required String uploadUrl,
    required File file,
    required Map<String, String> headers,
  }) async {
    final response = await _httpClient
        .put(
          Uri.parse(uploadUrl),
          headers: headers,
          body: await file.readAsBytes(),
        )
        .timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        'No se pudo subir la fotografía.',
        statusCode: response.statusCode,
      );
    }
  }

  dynamic _decode(http.Response response) {
    dynamic payload;
    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = response.body;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload is Map ? payload['detail'] : null;
      throw BackendApiException(
        detail?.toString() ?? 'Error de comunicación con el servidor.',
        statusCode: response.statusCode,
      );
    }
    return payload;
  }
}
