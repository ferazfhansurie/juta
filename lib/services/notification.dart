import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// @copyright Copyright (c) 2021
/// @author David Cheang <davidcheang83@gmail.com>
/// @version 1.0.1 (null-safety)

class NotificationService {
  NotificationDetails? notificationDetails;
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  Future<void> init() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');


    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,

    );

    
    

    if (Platform.isIOS) {

    
    } else if (Platform.isAndroid) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('default', 'Default Channel',
              channelDescription: 'Default Channel',
              importance: Importance.high,
              icon: 'ic_launcher',
             );
      notificationDetails =
          const NotificationDetails(android: androidPlatformChannelSpecifics);
    }
  }

  Future<String?> getFirebaseMessagingToken() async {
    bool hasService = true;

    FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    return  await firebaseMessaging.getToken();
  }


}
