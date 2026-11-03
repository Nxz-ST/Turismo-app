import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_app/core/errors/friendly_error.dart';
import 'package:turismo_app/core/network/backend_api_client.dart';

void main() {
  test('oculta los detalles técnicos de errores de red', () {
    final message = friendlyErrorMessage(
      const SocketException(
        'Connection failed (OS Error: Network is unreachable, errno = 101)',
      ),
    );

    expect(message, 'No tienes conexión a internet en este momento.');
    expect(message, isNot(contains('SocketException')));
    expect(message, isNot(contains('errno')));
  });

  test('usa el mensaje seguro producido por el cliente del backend', () {
    const error = BackendApiException(
      'Tu sesión expiró. Inicia sesión nuevamente.',
      statusCode: 401,
    );

    expect(friendlyErrorMessage(error), error.message);
  });

  test('oculta errores internos aunque lleguen como mensaje del backend', () {
    const error = BackendApiException(
      'Supabase respondio 400: {"code":"23514","details":"Failing row"}',
      statusCode: 400,
    );

    final message = friendlyErrorMessage(error);

    expect(message, isNot(contains('Supabase')));
    expect(message, isNot(contains('23514')));
  });

  test('oculta detalles técnicos guardados como motivo de decisión', () {
    final message = friendlyDecisionReason(
      'Supabase respondió 400 para bd92fdfb-7699-4fb4-b20a-2811327df448',
    );

    expect(message, contains('aporte está seguro'));
    expect(message, isNot(contains('Supabase')));
  });

  test('un error desconocido usa un texto neutral', () {
    final message = friendlyErrorMessage(Exception('detalle interno sensible'));

    expect(message, 'No pudimos completar la acción. Inténtalo nuevamente.');
    expect(message, isNot(contains('detalle interno')));
  });

  test('traduce errores frecuentes de cuenta y permisos', () {
    expect(
      friendlyErrorMessage(Exception('User already registered')),
      'Ya existe una cuenta con ese correo electrónico.',
    );
    expect(
      friendlyErrorMessage(Exception('Permisos bloqueados')),
      'Habilita el permiso de ubicación desde los ajustes del teléfono.',
    );
  });
}
