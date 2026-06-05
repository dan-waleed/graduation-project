import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'hb_custom_card.dart';

class HbQuickActionCard extends StatelessWidget {
  const HbQuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HbCustomCard(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 172),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.18),
                    AppTheme.secondary.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'عرض التفاصيل',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
