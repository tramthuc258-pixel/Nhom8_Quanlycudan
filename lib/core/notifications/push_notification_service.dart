import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import 'firebase_bootstrap.dart';

class PushNotificationTap {
  const PushNotificationTap({
    required this.type,
    this.notificationId,
    this.referenceType,
    this.referenceId,
  });

  final String type;
  final String? notificationId;
  final String? referenceType;
  final String? referenceId;
}

class PushNotificationService {
  PushNotificationService(this._apiClient);

  static const _channel = AndroidNotificationChannel(
    'homie_important',
    'Thông báo Homie',
    description: 'Hóa đơn, yêu cầu và thông báo vận hành từ Homie.',
    importance: Importance.high,
  );

  final ApiClient _apiClient;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<PushNotificationTap> _tapController =
      StreamController<PushNotificationTap>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _currentToken;
  bool _initialized = false;
  PushNotificationTap? _pendingTap;

  Stream<PushNotificationTap> get notificationTaps => _tapController.stream;

  PushNotificationTap? takePendingTap() {
    final value = _pendingTap;
    _pendingTap = null;
    return value;
  }

  Future<void> initialize() async {
    if (_initialized || !supportsHomieFirebase || Firebase.apps.isEmpty) {
      return;
    }
    _initialized = true;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) _emitTap(data);
        } on FormatException {
          // Payload lỗi không được làm ứng dụng bị dừng.
        }
      },
    );
    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    _tokenRefreshSubscription = messaging.onRegistered.listen((token) {
      _currentToken = token;
      if (_apiClient.accessToken != null) {
        unawaited(_registerToken(token));
      }
    });
    // Không chặn màn hình khởi động trong lúc Firebase cấp mã thiết bị.
    unawaited(_requestFirebaseRegistration(messaging));

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _emitTap(message.data),
    );
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _emitTap(initialMessage.data);
  }

  Future<bool> registerCurrentDevice() async {
    if (!_initialized) await initialize();
    if (!_initialized) return false;
    if (_currentToken == null) {
      final registration = Completer<String>();
      late final StreamSubscription<String> subscription;
      subscription = FirebaseMessaging.instance.onRegistered.listen((token) {
        _currentToken = token;
        if (!registration.isCompleted) registration.complete(token);
        unawaited(subscription.cancel());
      });
      try {
        await FirebaseMessaging.instance.register();
      } catch (_) {
        await subscription.cancel();
        return false;
      }
      try {
        _currentToken = await registration.future.timeout(
          const Duration(seconds: 15),
        );
      } on TimeoutException {
        await subscription.cancel();
      }
    }
    final token = _currentToken;
    if (token == null || token.isEmpty) return false;
    _currentToken = token;
    return _registerToken(token);
  }

  Future<void> deactivateCurrentDevice() async {
    final token = _currentToken;
    if (token == null || _apiClient.accessToken == null) return;
    try {
      await _apiClient.patch(
        '/device-installations/deactivate',
        body: <String, Object?>{'firebaseToken': token},
      );
    } catch (_) {
      // Đăng xuất vẫn tiếp tục nếu API tạm thời không truy cập được.
    }
  }

  Future<bool> _registerToken(String token) async {
    if (_apiClient.accessToken == null) return false;
    try {
      await _apiClient.post(
        '/device-installations',
        body: <String, Object?>{
          'firebaseToken': token,
          'platform': 'ANDROID',
          'deviceName': 'Thiết bị Android',
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestFirebaseRegistration(FirebaseMessaging messaging) async {
    try {
      await messaging.register();
    } catch (_) {
      // Firebase có thể tạm thời chưa sẵn sàng; lần đăng nhập sẽ thử lại.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'Homie';
    final body = notification?.body ?? message.data['message']?.toString();
    if (body == null || body.isEmpty) return;
    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'homie_important',
          'Thông báo Homie',
          channelDescription:
              'Hóa đơn, yêu cầu và thông báo vận hành từ Homie.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _emitTap(Map<String, dynamic> data) {
    if (_tapController.isClosed) return;
    final tap = PushNotificationTap(
      type: data['type']?.toString() ?? 'system',
      notificationId: _nonEmpty(data['notificationId']),
      referenceType: _nonEmpty(data['referenceType']),
      referenceId: _nonEmpty(data['referenceId']),
    );
    if (_tapController.hasListener) {
      _pendingTap = null;
      _tapController.add(tap);
    } else {
      _pendingTap = tap;
    }
  }

  String? _nonEmpty(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  void dispose() {
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    unawaited(_tokenRefreshSubscription?.cancel());
    unawaited(_tapController.close());
  }
}
