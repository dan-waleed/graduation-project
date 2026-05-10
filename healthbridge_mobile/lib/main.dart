import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/core/network/api_client.dart';
import 'src/data/services/auth_service.dart';
import 'src/data/services/app_data_service.dart';
import 'src/data/services/dashboard_service.dart';
import 'src/data/storage/token_storage.dart';
import 'src/features/auth/presentation/controller/auth_controller.dart';
import 'src/features/common/presentation/controller/notification_center_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>(create: (_) => TokenStorage()),
        Provider<ApiClient>(create: (_) => ApiClient()),
        ProxyProvider<ApiClient, AppDataService>(
          update: (_, apiClient, service) {
            if (service != null) {
              service.rebind(apiClient);
              return service;
            }
            return AppDataService(apiClient: apiClient);
          },
        ),
        ProxyProvider<ApiClient, DashboardService>(
          update: (_, apiClient, service) {
            if (service != null) {
              service.rebind(apiClient);
              return service;
            }
            return DashboardService(apiClient: apiClient);
          },
        ),
        ProxyProvider2<ApiClient, TokenStorage, AuthService>(
          update: (_, apiClient, tokenStorage, __) => AuthService(
            apiClient: apiClient,
            tokenStorage: tokenStorage,
          ),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthController>(
          create: (context) => AuthController(
            authService: context.read<AuthService>(),
          )..bootstrap(),
          update: (_, authService, controller) =>
              controller!..rebind(authService),
        ),
        ChangeNotifierProxyProvider<AppDataService, NotificationCenterController>(
          create: (context) => NotificationCenterController(
            appDataService: context.read<AppDataService>(),
          )..initialize(),
          update: (_, appDataService, controller) {
            controller!.rebind(appDataService);
            unawaited(controller.initialize());
            return controller;
          },
        ),
      ],
      child: const HealthBridgeApp(),
    ),
  );
}
