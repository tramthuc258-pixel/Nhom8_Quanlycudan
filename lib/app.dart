import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/routes/app_router.dart';
import 'core/routes/route_guard.dart';
import 'core/payments/payment_return_link.dart';
import 'core/theme/app_theme.dart';
import 'dependencies.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/models/user.dart';
import 'features/auth/screens/login_page.dart';
import 'features/housing/screens/public/public_housing_page.dart';
import 'core/notifications/push_notification_service.dart';

class HomieApp extends StatefulWidget {
  const HomieApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  State<HomieApp> createState() => _HomieAppState();
}

class _HomieAppState extends State<HomieApp> {
  static const _paymentReturnChannel = MethodChannel('homie/payment_return');
  bool _guestMode = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<PushNotificationTap>? _pushTapSubscription;
  PushNotificationTap? _pendingPushTap;
  String? _pendingPaymentInvoiceId;

  @override
  void initState() {
    super.initState();
    final push = widget.dependencies.pushNotificationService;
    _pendingPushTap = push?.takePendingTap();
    _pushTapSubscription = push?.notificationTaps.listen(_handlePushTap);
    _paymentReturnChannel.setMethodCallHandler(_handlePaymentReturn);
    unawaited(_takeInitialPaymentReturn());
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingPush());
  }

  @override
  void dispose() {
    unawaited(_pushTapSubscription?.cancel());
    _paymentReturnChannel.setMethodCallHandler(null);
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = widget.dependencies.authController;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Homie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: authController,
        builder: (context, _) {
          final user = authController.currentUser;
          if (user != null && _pendingPushTap != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _openPendingPush(),
            );
          }
          if (user != null && _pendingPaymentInvoiceId != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _openPendingPaymentReturn(),
            );
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: user == null
                ? _buildPublicEntry(authController)
                : AppRouter.buildAuthenticatedHome(
                    context: context,
                    dependencies: widget.dependencies,
                    user: user,
                    onLogout: _logout,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPublicEntry(AuthController authController) {
    if (_guestMode) {
      return PublicHousingPage(
        key: const ValueKey<String>('public-housing'),
        controller: widget.dependencies.housingController,
        onResidentLogin: () => setState(() => _guestMode = false),
      );
    }
    return LoginPage(
      key: const ValueKey<String>('combined-login'),
      controller: authController,
      portal: LoginPortal.combined,
      onContinueAsGuest: () => setState(() => _guestMode = true),
      onLoginSuccess: (User _) {},
    );
  }

  void _logout() {
    widget.dependencies.authController.logout();
    if (mounted) setState(() => _guestMode = false);
  }

  void _handlePushTap(PushNotificationTap tap) {
    _pendingPushTap = tap;
    _openPendingPush();
  }

  Future<void> _takeInitialPaymentReturn() async {
    try {
      _queuePaymentReturn(
        await _paymentReturnChannel.invokeMethod<String>(
          'takePendingPaymentReturn',
        ),
      );
    } on MissingPluginException {
      // Android mới có cổng nhận liên kết thanh toán.
    } on PlatformException {
      // Ứng dụng vẫn dùng được khi Android không trả được intent ban đầu.
    }
  }

  Future<void> _handlePaymentReturn(MethodCall call) async {
    if (call.method == 'paymentReturn' && call.arguments is String) {
      _queuePaymentReturn(call.arguments as String);
    }
  }

  void _queuePaymentReturn(String? link) {
    final invoiceId = invoiceIdFromPaymentReturn(link);
    if (invoiceId == null) return;
    _pendingPaymentInvoiceId = invoiceId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _openPendingPaymentReturn(),
    );
  }

  void _openPendingPaymentReturn() {
    final invoiceId = _pendingPaymentInvoiceId;
    final context = _navigatorKey.currentContext;
    final navigator = _navigatorKey.currentState;
    final user = widget.dependencies.authController.currentUser;
    if (!mounted ||
        invoiceId == null ||
        context == null ||
        navigator == null ||
        user == null ||
        user.mustChangePassword ||
        !RouteGuard.canOpenResidentArea(user)) {
      return;
    }
    _pendingPaymentInvoiceId = null;
    navigator.popUntil((route) => route.isFirst);
    unawaited(
      AppRouter.openPushReference(
        context: context,
        dependencies: widget.dependencies,
        user: user,
        referenceType: 'invoice',
        referenceId: invoiceId,
        fallbackToNotificationCenter: false,
      ),
    );
  }

  void _openPendingPush() {
    final tap = _pendingPushTap;
    final context = _navigatorKey.currentContext;
    final user = widget.dependencies.authController.currentUser;
    if (!mounted ||
        tap == null ||
        context == null ||
        user == null ||
        user.mustChangePassword) {
      return;
    }
    _pendingPushTap = null;
    AppRouter.openPushReference(
      context: context,
      dependencies: widget.dependencies,
      user: user,
      notificationId: tap.notificationId,
      referenceType: tap.referenceType,
      referenceId: tap.referenceId,
    );
  }
}
