import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';

const _guidePreferenceKey = 'rutaamiga_first_run_guide_v1';

Future<void> showFirstRunGuideIfNeeded(BuildContext context) async {
  final preferences = await SharedPreferences.getInstance();
  if (preferences.getBool(_guidePreferenceKey) == true || !context.mounted) {
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const _FirstRunGuide(),
  );
  await preferences.setBool(_guidePreferenceKey, true);
}

class _FirstRunGuide extends StatefulWidget {
  const _FirstRunGuide();

  @override
  State<_FirstRunGuide> createState() => _FirstRunGuideState();
}

class _FirstRunGuideState extends State<_FirstRunGuide> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.explore_rounded,
      eyebrow: 'DESCUBRE',
      title: 'Encuentra lugares cerca de ti',
      description:
          'Explora atractivos oficiales y descubrimientos corroborados por la comunidad.',
    ),
    (
      icon: Icons.route_rounded,
      eyebrow: 'PLANIFICA',
      title: 'Crea una ruta a tu medida',
      description:
          'Elige tiempo, experiencia y transporte para recibir recorridos compatibles.',
    ),
    (
      icon: Icons.add_a_photo_rounded,
      eyebrow: 'APORTA',
      title: 'Ayuda a completar el mapa',
      description:
          'Fotografía un lugar desde campo; RutaAmiga contrastará imagen, ubicación y contexto.',
    ),
  ];

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == _pages.length - 1) {
      Navigator.pop(context);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .68,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Así funciona RutaAmiga',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Omitir'),
              ),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) => setState(() => _page = page),
              itemCount: _pages.length,
              itemBuilder: (_, index) {
                final page = _pages[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        page.icon,
                        size: 62,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      page.eyebrow,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 25,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: index == _page ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _page
                      ? AppColors.primary
                      : const Color(0xFFD4DDD9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _next,
              icon: Icon(
                _page == _pages.length - 1
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _page == _pages.length - 1 ? 'Empezar a explorar' : 'Continuar',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
