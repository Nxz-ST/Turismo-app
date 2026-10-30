import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../network/backend_api_client.dart';

String friendlyErrorMessage(
  Object? error, {
  String fallback = 'No pudimos completar la acción. Inténtalo nuevamente.',
}) {
  if (error is BackendApiException) return error.message;
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return 'No tienes conexión a internet en este momento.';
  }

  final text = error?.toString().toLowerCase() ?? '';
  if (text.contains('network is unreachable') ||
      text.contains('failed host lookup') ||
      text.contains('socketexception') ||
      text.contains('connection failed') ||
      text.contains('connection refused') ||
      text.contains('clientexception') ||
      text.contains('timed out') ||
      text.contains('timeout')) {
    return 'No tienes conexión a internet en este momento.';
  }
  if (text.contains('invalid login credentials')) {
    return 'El correo o la contraseña no son correctos.';
  }
  if (text.contains('email not confirmed')) {
    return 'Confirma tu correo electrónico antes de iniciar sesión.';
  }
  if (text.contains('user already registered') ||
      text.contains('already been registered') ||
      text.contains('email already')) {
    return 'Ya existe una cuenta con ese correo electrónico.';
  }
  if (text.contains('password should be') || text.contains('weak password')) {
    return 'La contraseña es muy corta o poco segura.';
  }
  if (text.contains('invalid email') ||
      text.contains('email address is invalid')) {
    return 'Escribe un correo electrónico válido.';
  }
  if (text.contains('rate limit') || text.contains('too many requests')) {
    return 'Realizaste varios intentos. Espera un momento y vuelve a probar.';
  }
  if (text.contains('gps desactivado') ||
      text.contains('location services are disabled')) {
    return 'Activa la ubicación del teléfono para continuar.';
  }
  if (text.contains('permiso denegado') || text.contains('permission denied')) {
    return 'Necesitamos permiso de ubicación para continuar.';
  }
  if (text.contains('permisos bloqueados') || text.contains('deniedforever')) {
    return 'Habilita el permiso de ubicación desde los ajustes del teléfono.';
  }
  if (text.contains('jwt') || text.contains('session')) {
    return 'Tu sesión expiró. Inicia sesión nuevamente.';
  }
  return fallback;
}
