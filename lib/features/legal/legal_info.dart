/// Datos de los documentos legales que la app muestra y registra.
///
/// Si cambian los textos de forma importante, sube [termsVersion]: a todos los
/// usuarios se les pedirá aceptar de nuevo. Los textos viven en `docs/legal/`
/// y se copian a `assets/legal/` con `tool/sync_legal.sh`.
class LegalInfo {
  const LegalInfo._();

  static const termsVersion = '1.0';
  static const termsAsset = 'assets/legal/terminos.md';
  static const privacyAsset = 'assets/legal/privacidad.md';

  /// Correo para derechos ARCO y retiro de consentimiento.
  static const contactEmail = 'sebastian.chinchay@upeu.edu.pe';
}
