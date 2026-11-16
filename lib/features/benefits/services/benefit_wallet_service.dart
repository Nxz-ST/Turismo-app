import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tourism_benefit.dart';
import 'benefit_api_service.dart';

class BenefitWalletService {
  const BenefitWalletService._();

  static const instance = BenefitWalletService._();
  static final BenefitApiService _remote = BenefitApiService();

  String _storageKey(String placeKey, String benefitId) =>
      'demo_benefit_${_safe(placeKey)}_${_safe(benefitId)}';

  Future<BenefitPass?> getPass(String placeKey, String benefitId) async {
    try {
      final remote = await _remote.activePass(placeKey, benefitId);
      if (remote != null) return remote;
    } catch (_) {
      // La maqueta conserva el pase local si el backend aún no fue migrado.
    }
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey(placeKey, benefitId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BenefitPass(
        code: json['code'].toString(),
        activatedAt: DateTime.parse(json['activated_at'].toString()),
        expiresAt: DateTime.parse(json['expires_at'].toString()),
        status: json['status']?.toString() ?? 'requested',
      );
    } catch (_) {
      return null;
    }
  }

  Future<BenefitPass> activate({
    required String placeKey,
    required String placeName,
    required String benefitId,
  }) async {
    try {
      return await _remote.claim(
        placeKey: placeKey,
        placeName: placeName,
        benefitId: benefitId,
      );
    } catch (_) {
      // Respaldo de presentación cuando no hay conexión con el servidor.
    }
    final existing = await getPass(placeKey, benefitId);
    if (existing?.isActive ?? false) return existing!;
    final now = DateTime.now();
    final pass = BenefitPass(
      code: _codeFor(placeName, benefitId),
      activatedAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey(placeKey, benefitId),
      jsonEncode({
        'code': pass.code,
        'activated_at': pass.activatedAt.toIso8601String(),
        'expires_at': pass.expiresAt.toIso8601String(),
        'status': pass.status,
      }),
    );
    return pass;
  }

  String _codeFor(String placeName, String benefitId) {
    final place = _safe(placeName).replaceAll('_', '').toUpperCase();
    final agency = _safe(benefitId).replaceAll('_', '').toUpperCase();
    final suffix = (placeName.hashCode ^ benefitId.hashCode)
        .abs()
        .toString()
        .padLeft(4, '0');
    final placeToken = place.length > 4 ? place.substring(0, 4) : place;
    final agencyToken = agency.length > 3 ? agency.substring(0, 3) : agency;
    return 'RUTA-$placeToken-$agencyToken-${suffix.substring(suffix.length - 4)}';
  }

  String _safe(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
