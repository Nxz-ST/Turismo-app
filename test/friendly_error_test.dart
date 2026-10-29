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

  test('un error desconocido usa un texto neutral', () {
    final message = friendlyErrorMessage(Exception('detalle interno sensible'));

    expect(message, 'No pudimos completar la acción. Inténtalo nuevamente.');
    expect(message, isNot(contains('detalle interno')));
  });
}
