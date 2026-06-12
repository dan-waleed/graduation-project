import 'package:go_router/go_router.dart';

import 'package:healthbridge_mobile/view/features/auth/login_screen.dart';
import 'package:healthbridge_mobile/modelView/features/auth/auth_view_model.dart';
import 'package:healthbridge_mobile/view/features/splash/splash_screen.dart';
import 'package:healthbridge_mobile/view/navigation/app_route_access.dart';
import 'package:healthbridge_mobile/view/navigation/app_route_registry.dart';

class AppRouter {
  AppRouter(this.authViewModel);

  final AuthViewModel authViewModel;

  late final GoRouter router = GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authViewModel,
    routes: AppRouteRegistry.build(),
    redirect: (_, state) {
      final authState = authViewModel.state;
      final currentPath = state.matchedLocation;

      if (authState == AuthFlowState.bootstrapping) {
        return currentPath == SplashScreen.routePath
            ? null
            : SplashScreen.routePath;
      }

      if (!authViewModel.isAuthenticated) {
        return currentPath == LoginScreen.routePath
            ? null
            : LoginScreen.routePath;
      }

      if (currentPath == SplashScreen.routePath ||
          currentPath == LoginScreen.routePath) {
        return AppRouteAccess.homeForRole(authViewModel.currentUser?.role);
      }

      final allowedRoutes = AppRouteAccess.allowedRoutesForRole(
        authViewModel.currentUser?.role,
      );
      if (!allowedRoutes.contains(currentPath)) {
        return AppRouteAccess.homeForRole(authViewModel.currentUser?.role);
      }

      return null;
    },
  );
}
