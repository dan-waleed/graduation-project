import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:healthbridge_mobile/view/app/app.dart';
import 'package:healthbridge_mobile/model/core/network/api_client.dart';
import 'package:healthbridge_mobile/model/repositories/app_repository.dart';
import 'package:healthbridge_mobile/model/repositories/auth_repository.dart';
import 'package:healthbridge_mobile/model/repositories/dashboard_repository.dart';
import 'package:healthbridge_mobile/model/services/auth_service.dart';
import 'package:healthbridge_mobile/model/services/app_data_service.dart';
import 'package:healthbridge_mobile/model/services/dashboard_service.dart';
import 'package:healthbridge_mobile/model/storage/token_storage.dart';
import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/modelView/features/common/notification_center_view_model.dart';

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
        ProxyProvider<AppDataService, AppRepository>(
          update: (_, appDataService, repository) {
            if (repository != null) {
              repository.rebind(appDataService);
              return repository;
            }
            return AppRepository(appDataService: appDataService);
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
        ProxyProvider<DashboardService, DashboardRepository>(
          update: (_, dashboardService, repository) {
            if (repository != null) {
              repository.rebind(dashboardService);
              return repository;
            }
            return DashboardRepository(dashboardService: dashboardService);
          },
        ),
        ProxyProvider2<ApiClient, TokenStorage, AuthService>(
          update: (_, apiClient, tokenStorage, __) =>
              AuthService(apiClient: apiClient, tokenStorage: tokenStorage),
        ),
        ProxyProvider<AuthService, AuthRepository>(
          update: (_, authService, repository) {
            if (repository != null) {
              repository.rebind(authService);
              return repository;
            }
            return AuthRepository(authService: authService);
          },
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthViewModel>(
          create: (context) =>
              AuthViewModel(authRepository: context.read<AuthRepository>())
                ..bootstrap(),
          update: (_, authRepository, controller) =>
              controller!..rebind(authRepository),
        ),
        ChangeNotifierProxyProvider<AppRepository, NotificationCenterViewModel>(
          create: (context) => NotificationCenterViewModel(
            appRepository: context.read<AppRepository>(),
          )..initialize(),
          update: (_, appRepository, controller) {
            controller!.rebind(appRepository);
            unawaited(controller.initialize());
            return controller;
          },
        ),
      ],
      child: const HealthBridgeApp(),
    ),
  );
}
