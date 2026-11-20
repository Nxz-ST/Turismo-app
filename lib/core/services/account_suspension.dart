import 'package:flutter/foundation.dart';

/// Datos del bloqueo que envía el backend en un 403 `account_suspended`.
class AccountSuspensionInfo {
  const AccountSuspensionInfo({this.reason, this.suspendedUntil});

  final String? reason;

  /// Nulo = bloqueo definitivo.
  final DateTime? suspendedUntil;

  static const code = 'account_suspended';

  static AccountSuspensionInfo? fromDetail(dynamic detail) {
    if (detail is! Map || detail['code'] != code) return null;
    final until = detail['suspended_until'];
    return AccountSuspensionInfo(
      reason: (detail['reason'] as String?)?.trim(),
      suspendedUntil: until is String
          ? DateTime.tryParse(until)?.toLocal()
          : null,
    );
  }
}

/// Avisa a toda la app cuando el backend responde que la cuenta está
/// bloqueada; `RutaAmigaApp` muestra entonces la pantalla de bloqueo.
class AccountSuspension {
  AccountSuspension._();

  static final notifier = ValueNotifier<AccountSuspensionInfo?>(null);

  /// Solo el primer aviso cuenta: otras peticiones fallidas no reinician la
  /// pantalla de bloqueo mientras el usuario la está leyendo.
  static void report(AccountSuspensionInfo info) {
    notifier.value ??= info;
  }

  static void clear() => notifier.value = null;
}
