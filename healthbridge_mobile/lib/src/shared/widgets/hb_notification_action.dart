import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/common/presentation/viewmodels/notification_center_view_model.dart';
import '../../features/common/presentation/views/notifications_screen.dart';

class HbNotificationAction extends StatefulWidget {
  const HbNotificationAction({super.key});

  @override
  State<HbNotificationAction> createState() => _HbNotificationActionState();
}

class _HbNotificationActionState extends State<HbNotificationAction> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCenterViewModel>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final notificationCenter = context.watch<NotificationCenterViewModel>();
    final unreadCount = notificationCenter.unreadCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () async {
            await context.push(NotificationsScreen.routePath);
            if (!mounted) return;
            unawaited(notificationCenter.refreshUnreadCount(silent: true));
          },
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'الإشعارات',
        ),
        if (unreadCount > 0)
          PositionedDirectional(
            top: 6,
            end: 6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
