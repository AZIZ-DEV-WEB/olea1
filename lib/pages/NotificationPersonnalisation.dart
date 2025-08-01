import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void initializeNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('ic_notification');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showCustomNotification(RemoteMessage message) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'olea_channel', // ID du canal
    'OLEA ONE',     // Nom visible du canal
    channelDescription: 'Notifications des formations OLEA',
    icon: 'ic_notification',
    color: Color(0xFFF8AF3C), // Couleur orange OLEA
    playSound: true,
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: const BigTextStyleInformation(''), // Pour le texte long
  );

  final NotificationDetails notificationDetails =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'Formation OLEA ONE',
    message.notification?.body ?? 'Une nouvelle formation vous attend !',
    notificationDetails,
  );
}
