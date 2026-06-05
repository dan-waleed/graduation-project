import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'src/app/app.dart';
import 'src/core/network/api_client.dart';
import 'src/data/repositories/app_repository.dart';
import 'src/data/repositories/auth_repository.dart';
import 'src/data/repositories/dashboard_repository.dart';
import 'src/data/services/auth_service.dart';
import 'src/data/services/app_data_service.dart';
import 'src/data/services/dashboard_service.dart';
import 'src/data/storage/token_storage.dart';
import 'src/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'src/features/common/presentation/viewmodels/notification_center_view_model.dart';

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
