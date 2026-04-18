import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_navigator.dart';
import '../screens/main_wrapper.dart';

class NotificationService {
  const NotificationService._();

  static const NotificationService instance = NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String payloadTransactions = 'transactions';
  static const String payloadGoals = 'goals';
  static const String payloadChat = 'chat';

  Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final NotificationAppLaunchDetails? launchDetails = await _plugin
        .getNotificationAppLaunchDetails();
    final NotificationResponse? launchResponse =
        launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handleNotificationResponse(launchResponse);
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'spendwise_alerts',
          'SpendWise Alerts',
          channelDescription: 'Notifications for transactions and goals',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final int id = DateTime.now().microsecondsSinceEpoch.remainder(1 << 31);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  void _handleNotificationResponse(NotificationResponse? response) {
    if (response == null) {
      return;
    }

    final NavigatorState? navigator = appNavigatorKey.currentState;
    final String payload = (response.payload ?? '').trim();
    if (navigator == null || payload.isEmpty) {
      return;
    }

    switch (payload) {
      case payloadTransactions:
        navigator.pushNamed('/transactions');
        break;
      case payloadGoals:
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const MainWrapperScreen(initialIndex: 2),
          ),
          (Route<dynamic> route) => false,
        );
        break;
      case payloadChat:
        navigator.pushNamed('/chat');
        break;
      default:
        break;
    }
  }
}
