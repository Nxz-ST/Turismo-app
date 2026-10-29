import 'package:flutter/material.dart';

import '../../features/home/screens/home_screen.dart';
import '../../features/places/screens/evidence_hub_screen.dart';
import '../../features/places/screens/map_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/routes/screens/suggested_routes_screen.dart';
import '../constants/app_colors.dart';
import 'presence_lifecycle.dart';

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  void _open(BuildContext context, int index) {
    if (index == currentIndex) return;
    final target = switch (index) {
      0 => const HomeScreen(),
      1 => const MapScreen(),
      2 => const SuggestedRoutesScreen(),
      3 => const EvidenceHubScreen(),
      _ => const ProfileScreen(),
    };
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PresenceLifecycle(child: target),
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      onDestinationSelected: (index) => _open(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
          label: 'Descubrir',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore, color: AppColors.primary),
          label: 'Explorar',
        ),
        NavigationDestination(
          icon: Icon(Icons.route_outlined),
          selectedIcon: Icon(Icons.route, color: AppColors.primary),
          label: 'Rutas',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_a_photo_outlined),
          selectedIcon: Icon(Icons.add_a_photo, color: AppColors.primary),
          label: 'Aportar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Mi perfil',
        ),
      ],
    );
  }
}
