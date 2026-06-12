import 'package:flutter/material.dart';

import 'package:healthbridge_mobile/view/theme/app_theme.dart';

class HbUniversityLogo extends StatelessWidget {
  const HbUniversityLogo({
    super.key,
    this.size = 28,
    this.showSurface = true,
    this.surfaceColor = Colors.white,
  });

  final double size;
  final bool showSurface;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/ppu-logo.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (!showSurface) {
      return SizedBox(
        width: size,
        height: size,
        child: Padding(padding: EdgeInsets.all(size * 0.08), child: logo),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: logo,
    );
  }
}

class HbAppBarTitle extends StatelessWidget {
  const HbAppBarTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HbUniversityLogo(size: 30),
        const SizedBox(width: 10),
        Flexible(
          child: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }
}
