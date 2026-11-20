import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_environment.dart';
import '../services/account_suspension.dart';

class BackendApiException implements Exception {
  final int? statusCode;
  final String message;
  final bool isNetworkFailure;

  const BackendApiException(
    this.message, {
    this.statusCode,
    this.isNetworkFailure = false,
  });

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
    return _guard(() async {
      final response = await _httpClient
          .get(uri(path, query), headers: _jsonHeaders)
          .timeout(const Duration(seconds: 45));
      return _decode(response);
    });
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _guard(() async {
      final response = await _httpClient
          .post(
            uri(path),
            headers: _jsonHeaders,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 45));
      return _decode(response);
    });
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    return _guard(() async {
      final response = await _httpClient
          .patch(
            uri(path),
            headers: _jsonHeaders,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 45));
      return _decode(response);
    });
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    return _guard(() async {
      final response = await _httpClient
          .put(
            uri(path),
            headers: _jsonHeaders,
            body: jsonEncode(body ?? const <String, dynamic>{}),
          )
          .timeout(const Duration(seconds: 45));
      return _decode(response);
    });
  }

  Future<void> uploadFile({
    required String uploadUrl,
    required File file,
    required Map<String, String> headers,
  }) async {
    await _guard(() async {
      final response = await _httpClient
          .put(
            Uri.parse(uploadUrl),
            headers: headers,
            body: await file.readAsBytes(),
          )
          .timeout(const Duration(minutes: 2));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BackendApiException(
          'No pudimos subir la fotografía. Inténtalo nuevamente.',
          statusCode: response.statusCode,
          isNetworkFailure: response.statusCode >= 500,
        );
      }
    });
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on BackendApiException {
      rethrow;
    } on TimeoutException {
      throw const BackendApiException(
        'La conexión está tardando demasiado. Revisa tu internet e inténtalo nuevamente.',
        isNetworkFailure: true,
      );
    } on SocketException {
      throw const BackendApiException(
        'No tienes conexión a internet en este momento.',
        isNetworkFailure: true,
      );
    } on http.ClientException {
      throw const BackendApiException(
        'No pudimos conectarnos. Revisa tu internet e inténtalo nuevamente.',
        isNetworkFailure: true,
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
      final suspension = response.statusCode == 403
          ? AccountSuspensionInfo.fromDetail(detail)
          : null;
      if (suspension != null) {
        AccountSuspension.report(suspension);
        throw const BackendApiException(
          'Tu cuenta está bloqueada por incumplir los Términos y condiciones.',
          statusCode: 403,
        );
      }
      final message = switch (response.statusCode) {
        401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
        403 => 'No tienes permiso para realizar esta acción.',
        404 => 'No encontramos la información solicitada.',
        >= 500 =>
          'El servicio no está disponible por el momento. Inténtalo más tarde.',
        _ => _safeServerMessage(detail),
      };
      throw BackendApiException(
        message,
        statusCode: response.statusCode,
        isNetworkFailure: response.statusCode >= 500,
      );
    }
    return payload;
  }

  static String _safeServerMessage(dynamic detail) {
    final message = detail?.toString().trim() ?? '';
    if (message.isEmpty ||
        message.length > 220 ||
        RegExp(
          r'(exception|traceback|socket|http://|https://|errno|stack|port\s*=)',
          caseSensitive: false,
        ).hasMatch(message)) {
      return 'No pudimos completar la solicitud. Revisa los datos e inténtalo nuevamente.';
    }
    return message;
  }
}
