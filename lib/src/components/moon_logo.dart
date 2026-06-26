import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Moonleaf brand mark (crescent moon + leaf). Reused on the splash and
/// the settings/about screen. [withBackdrop] wraps it in the night-gradient
/// rounded badge used for branding surfaces.
class MoonLogo extends StatelessWidget {
  const MoonLogo({super.key, this.size = 96, this.withBackdrop = true});

  final double size;
  final bool withBackdrop;

  @override
  Widget build(BuildContext context) {
    final glyph = Image.asset(
      'assets/icon/icon_foreground.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!withBackdrop) return glyph;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.1, -0.2),
          radius: 0.9,
          colors: AppColors.nightGradient,
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.5),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: glyph,
    );
  }
}
