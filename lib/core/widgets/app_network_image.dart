import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.headers,
    this.width,
    this.height,
    this.fallbackIcon = Icons.landscape_outlined,
  });

  final String url;
  final BoxFit fit;
  final Map<String, String>? headers;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _ImageFallback(icon: fallbackIcon);
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: headers,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (_, __) => const _ImageSkeleton(),
      errorWidget: (_, __, ___) => _ImageFallback(icon: fallbackIcon),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFE5ECE9), Color(0xFFF4F7F5), Color(0xFFE5ECE9)],
      ),
    ),
    child: Center(
      child: SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.primarySoft,
    child: Center(child: Icon(icon, color: AppColors.primary, size: 30)),
  );
}
