import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/view/navigation/app_router.dart';
import 'package:healthbridge_mobile/view/theme/app_theme.dart';

class HealthBridgeApp extends StatefulWidget {
  const HealthBridgeApp({super.key});

  @override
  State<HealthBridgeApp> createState() => _HealthBridgeAppState();
}

class _HealthBridgeAppState extends State<HealthBridgeApp> {
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(context.read<AuthViewModel>());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, _, __) {
        return MaterialApp.router(
          title: 'HealthBridge',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: _appRouter.router,
        );
      },
    );
  }
}
