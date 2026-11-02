import 'package:flutter/material.dart';

import 'package:homie/apps/shared/portal_access_denied_page.dart';
import 'package:homie/core/routes/app_router.dart';
import 'package:homie/core/routes/route_guard.dart';
import 'package:homie/core/theme/app_theme.dart';
import 'package:homie/dependencies.dart';
import 'package:homie/features/auth/models/user.dart';
import 'package:homie/features/auth/screens/login_page.dart';

class AdminPortalApp extends StatefulWidget {
  const AdminPortalApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<AdminPortalApp> createState() => _AdminPortalAppState();
}

class _AdminPortalAppState extends State<AdminPortalApp> {
  @override
  void dispose() {
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = widget.dependencies.authController;
    return MaterialApp(
      title: 'Homie Quản trị',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          final user = authController.currentUser;
          if (user == null) {
            return LoginPage(
              key: const ValueKey<String>('staff-login'),
              controller: authController,
              portal: LoginPortal.staff,
              onLoginSuccess: (User _) {},
            );
          }
          if (!RouteGuard.canOpenManagementArea(user)) {
            return PortalAccessDeniedPage(
              title: 'Không thể vào cổng quản trị',
              message:
                  'Tài khoản ${user.fullName} không có vai trò quản trị hoặc nhân viên.',
              onLogout: authController.logout,
            );
          }
          return AppRouter.buildAuthenticatedHome(
            context: context,
            dependencies: widget.dependencies,
            user: user,
            onLogout: authController.logout,
          );
        },
      ),
    );
  }
}
