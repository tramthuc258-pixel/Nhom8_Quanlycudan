import 'package:flutter/material.dart';

import 'package:homie/apps/shared/portal_access_denied_page.dart';
import 'package:homie/core/routes/app_router.dart';
import 'package:homie/core/routes/route_guard.dart';
import 'package:homie/core/theme/app_theme.dart';
import 'package:homie/dependencies.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/screens/login_page.dart';
import 'package:homie/features/housing/screens/public/public_housing_page.dart';

class ResidentPortalApp extends StatefulWidget {
  const ResidentPortalApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<ResidentPortalApp> createState() => _ResidentPortalAppState();
}

class _ResidentPortalAppState extends State<ResidentPortalApp> {
  bool _guestMode = false;

  @override
  void dispose() {
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = widget.dependencies.authController;
    return MaterialApp(
      title: 'Homie Cư dân',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          final user = authController.currentUser;
          if (user == null) {
            if (!_guestMode) {
              return LoginPage(
                key: const ValueKey<String>('resident-login'),
                controller: authController,
                portal: LoginPortal.resident,
                onContinueAsGuest: () => setState(() => _guestMode = true),
                onLoginSuccess: (User _) {},
              );
            }
            return PublicHousingPage(
              key: const ValueKey<String>('public-housing'),
              controller: widget.dependencies.housingController,
              onResidentLogin: () => setState(() => _guestMode = false),
            );
          }
          if (!RouteGuard.canOpenResidentArea(user)) {
            return PortalAccessDeniedPage(
              title: 'Không thể vào ứng dụng cư dân',
              message:
                  'Tài khoản ${user.fullName} thuộc cổng quản trị hoặc chưa có quyền cư dân.',
              onLogout: _logout,
            );
          }
          return AppRouter.buildAuthenticatedHome(
            context: context,
            dependencies: widget.dependencies,
            user: user,
            onLogout: _logout,
          );
        },
      ),
    );
  }

  void _logout() {
    widget.dependencies.authController.logout();
    if (mounted) setState(() => _guestMode = false);
  }
}
