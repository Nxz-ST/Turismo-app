import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/tourism_benefit.dart';
import '../services/benefit_wallet_service.dart';
import '../services/benefit_api_service.dart';
import '../services/mock_benefit_catalog.dart';

class TourismBenefitsScreen extends StatefulWidget {
  const TourismBenefitsScreen({
    super.key,
    required this.placeKey,
    required this.placeName,
    required this.category,
    required this.locationLabel,
  });

  final String placeKey;
  final String placeName;
  final String category;
  final String locationLabel;

  @override
  State<TourismBenefitsScreen> createState() => _TourismBenefitsScreenState();
}

class _TourismBenefitsScreenState extends State<TourismBenefitsScreen> {
  List<TourismBenefit> _benefits = const [];
  bool _catalogLoading = true;
  final Map<String, BenefitPass> _passes = {};

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      _benefits = await BenefitApiService().forPlace(
        placeKey: widget.placeKey,
        placeName: widget.placeName,
      );
    } catch (_) {
      _benefits = MockBenefitCatalog.forPlace(
        placeName: widget.placeName,
        category: widget.category,
      );
    }
    _catalogLoading = false;
    await _loadPasses();
  }

  Future<void> _loadPasses() async {
    for (final benefit in _benefits) {
      final pass = await BenefitWalletService.instance.getPass(
        widget.placeKey,
        benefit.id,
      );
      if (pass != null && pass.isActive) _passes[benefit.id] = pass;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Beneficios RutaAmiga')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
      children: [
        _destinationHeader(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Elige cómo viajar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text(
              '${_benefits.length} opciones',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Compara el beneficio, lo incluido y las condiciones antes de elegir.',
          style: TextStyle(color: AppColors.textLight, fontSize: 12),
        ),
        const SizedBox(height: 14),
        if (_catalogLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final benefit in _benefits) ...[
            _BenefitCard(
              benefit: benefit,
              activePass: _passes[benefit.id],
              onTap: () => _openBenefit(benefit),
            ),
            const SizedBox(height: 13),
          ],
        const SizedBox(height: 8),
        const _CommercialClarityCard(),
      ],
    ),
  );

  Widget _destinationHeader() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF2B5A50),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.location_on_rounded, color: Colors.white),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.placeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (widget.locationLabel.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC5D9D3),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8C9),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'hasta 15%',
            style: TextStyle(
              color: Color(0xFF9B570A),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _openBenefit(TourismBenefit benefit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BenefitDetailScreen(
          placeKey: widget.placeKey,
          placeName: widget.placeName,
          benefit: benefit,
        ),
      ),
    );
    await _loadPasses();
  }
}

class BenefitDetailScreen extends StatefulWidget {
  const BenefitDetailScreen({
    super.key,
    required this.placeKey,
    required this.placeName,
    required this.benefit,
  });

  final String placeKey;
  final String placeName;
  final TourismBenefit benefit;

  @override
  State<BenefitDetailScreen> createState() => _BenefitDetailScreenState();
}

class _BenefitDetailScreenState extends State<BenefitDetailScreen> {
  BenefitPass? _pass;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPass();
  }

  Future<void> _loadPass() async {
    final pass = await BenefitWalletService.instance.getPass(
      widget.placeKey,
      widget.benefit.id,
    );
    if (mounted) setState(() => _pass = pass?.isActive == true ? pass : null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Detalle de la experiencia')),
    bottomNavigationBar: _bottomAction(),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 116),
      children: [
        _agencyHero(),
        const SizedBox(height: 18),
        Text(
          widget.benefit.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(widget.benefit.summary),
        const SizedBox(height: 18),
        _priceCard(),
        const SizedBox(height: 24),
        _ListSection(
          title: 'Qué incluye',
          icon: Icons.check_circle_outline_rounded,
          items: widget.benefit.included,
          color: AppColors.primary,
        ),
        const SizedBox(height: 20),
        _ListSection(
          title: 'Condiciones del beneficio',
          icon: Icons.info_outline_rounded,
          items: widget.benefit.conditions,
          color: const Color(0xFFB66708),
        ),
        const SizedBox(height: 20),
        const _CommercialClarityCard(),
      ],
    ),
  );

  Widget _agencyHero() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF173D35), Color(0xFF0F755B)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        _AgencyAvatar(initials: widget.benefit.agencyInitials, large: true),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.benefit.agencyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFC45C),
                    size: 17,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.benefit.rating.toStringAsFixed(1)} · Operador aliado',
                    style: const TextStyle(
                      color: Color(0xFFD5E9E2),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _priceCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2EAE7)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.benefit.benefitLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.benefit.duration,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.benefit.discountPercentage > 0)
              Text(
                'S/ ${widget.benefit.originalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Text(
              'S/ ${widget.benefit.rutaAmigaPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'precio por persona',
              style: TextStyle(fontSize: 8, color: AppColors.textLight),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _bottomAction() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24081712),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: _loading
            ? null
            : (_pass == null ? _activate : () => _showPass(_pass!)),
        icon: Icon(
          _pass == null
              ? Icons.redeem_rounded
              : Icons.confirmation_number_outlined,
        ),
        label: Text(
          _loading
              ? 'Preparando...'
              : (_pass == null
                    ? 'Activar beneficio'
                    : 'Ver mi código activo'),
        ),
      ),
    ),
  );

  Future<void> _activate() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.redeem_rounded,
                color: AppColors.primary,
                size: 34,
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Activar este beneficio?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generaremos un pase válido por 7 días. No realiza ningún cobro: coordinas tu visita directamente con la agencia.',
                style: TextStyle(color: AppColors.textLight, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Generar mi beneficio'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final pass = await BenefitWalletService.instance.activate(
      placeKey: widget.placeKey,
      placeName: widget.placeName,
      benefitId: widget.benefit.id,
    );
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _pass = pass;
      _loading = false;
    });
    await _showPass(pass);
  }

  Future<void> _showPass(BenefitPass pass) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BenefitPassSheet(
      pass: pass,
      placeName: widget.placeName,
      benefit: widget.benefit,
    ),
  );
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.benefit,
    required this.onTap,
    this.activePass,
  });

  final TourismBenefit benefit;
  final BenefitPass? activePass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: benefit.recommended
                ? const Color(0xFF9ED6C4)
                : const Color(0xFFE1E8E5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AgencyAvatar(initials: benefit.agencyInitials),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              benefit.agencyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '★ ${benefit.rating.toStringAsFixed(1)} · ${benefit.duration}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (benefit.recommended)
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFD98245),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              benefit.title,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    benefit.benefitLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                if (benefit.discountPercentage > 0) ...[
                  Text(
                    'S/ ${benefit.originalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  'S/ ${benefit.rutaAmigaPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Icon(
                  activePass == null
                      ? Icons.visibility_outlined
                      : Icons.check_circle_rounded,
                  size: 18,
                  color: activePass == null
                      ? AppColors.primary
                      : AppColors.success,
                ),
                const SizedBox(width: 7),
                Text(
                  activePass == null ? 'Ver experiencia' : 'Código activo',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _BenefitPassSheet extends StatelessWidget {
  const _BenefitPassSheet({
    required this.pass,
    required this.placeName,
    required this.benefit,
  });

  final BenefitPass pass;
  final String placeName;
  final TourismBenefit benefit;

  String get _expiry =>
      '${pass.expiresAt.day.toString().padLeft(2, '0')}/'
      '${pass.expiresAt.month.toString().padLeft(2, '0')}/${pass.expiresAt.year}';

  String get _whatsAppMessage =>
      'Hola ${benefit.agencyName}, quiero coordinar este beneficio de RutaAmiga.\n\n'
      'Lugar: $placeName\n'
      'Beneficio: ${benefit.benefitLabel}\n'
      'Código: ${pass.code}\n'
      'Válido hasta: $_expiry\n\n'
      '¿Podrían confirmar disponibilidad?';

  Future<void> _openWhatsApp() async {
    final phone = (benefit.whatsappPhone ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final uri = Uri.https('wa.me', phone.isEmpty ? '/' : '/$phone', {
      'text': _whatsAppMessage,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Share.share(_whatsAppMessage);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.only(top: 50),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE3E0),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 18),
            const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 44,
            ),
            const SizedBox(height: 9),
            Text(
              pass.status == 'confirmed'
                  ? 'Beneficio confirmado'
                  : 'Solicitud creada',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              '$placeName · ${benefit.agencyName}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8F5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFCFE3DA)),
              ),
              child: Column(
                children: [
                  const Text(
                    'CÓDIGO RUTAAMIGA',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 9),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pass.code,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 25,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 132,
                    height: 54,
                    child: CustomPaint(painter: _DemoPassPattern(pass.code)),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Válido hasta $_expiry',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              pass.status == 'confirmed'
                  ? 'La agencia confirmó tu solicitud. Conserva este código para usar el beneficio.'
                  : 'Envía el código a la agencia por WhatsApp. La agencia confirmará la disponibilidad desde su panel.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Muestra este código a la agencia al coordinar tu visita.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openWhatsApp,
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Coordinar por WhatsApp'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: pass.code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado.')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copiar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Share.share(
                      'Beneficio RutaAmiga\n${benefit.agencyName}\n$placeName\nCódigo: ${pass.code}\nVálido hasta $_expiry',
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Compartir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AgencyAvatar extends StatelessWidget {
  const _AgencyAvatar({required this.initials, this.large = false});
  final String initials;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    width: large ? 58 : 44,
    height: large ? 58 : 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFFFE8C9),
      borderRadius: BorderRadius.circular(large ? 18 : 14),
    ),
    child: Text(
      initials,
      style: TextStyle(
        color: const Color(0xFF9B570A),
        fontSize: large ? 18 : 14,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });
  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2EAE7)),
        ),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[index],
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
              if (index < items.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _CommercialClarityCard extends StatelessWidget {
  const _CommercialClarityCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2F6),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFF2F7183), size: 21),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Los beneficios comerciales están separados de la validación turística. Un aliado nunca modifica el estado oficial o comunitario del lugar.',
            style: TextStyle(
              color: Color(0xFF315866),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DemoPassPattern extends CustomPainter {
  _DemoPassPattern(this.value);
  final String value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryDark;
    final units = value.codeUnits;
    var x = 0.0;
    var index = 0;
    while (x < size.width) {
      final width = 2.0 + (units[index % units.length] % 4);
      if (index.isEven || units[index % units.length].isOdd) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 0, width, size.height),
            const Radius.circular(1),
          ),
          paint,
        );
      }
      x += width + 2;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant _DemoPassPattern oldDelegate) =>
      oldDelegate.value != value;
}
