import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:juta_app/home.dart';
import 'package:juta_app/screens/login.dart';
import 'package:juta_app/screens/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:juta_app/services/notification.dart';

Future<void> main() async {
  debugPaintSizeEnabled = false;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));

  // TODO: Push Notification
  // // Firebase Cloud Messaging (FCM)

  WidgetsFlutterBinding.ensureInitialized();
    //await NotificationService().init();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyCFlkTGPLX5ir9nYOJQqf9ypE_k3JeIDy0",
          projectId: "onboarding-a5fcb",
          messagingSenderId: "334607574757",
          appId: "1:334607574757:android:9aa9e893edfa28ec87960c"));
            await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true, provisional: false);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true,badge: true,sound: true,);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'juta',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFF111B21),
        primaryColor: Colors.white,
        textTheme: CupertinoTextThemeData(
          navActionTextStyle: TextStyle(
            fontFamily: 'SF',
            fontSize: 16,
            // Additional properties...
          ),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: 'SF',
            fontSize: 34,
            // Additional properties...
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => Home(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
      name:
          'com.tedainternational.tdlabs', // Replace with your app name if needed
      options: FirebaseOptions(
          apiKey: "AIzaSyCc0oSHlqlX7fLeqqonODsOIC3XA8NI7hc",
          projectId: "onboarding-a5fcb",
          messagingSenderId: "334607574757",
          appId: "1:334607574757:android:9aa9e893edfa28ec87960c"));
  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true, provisional: false);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true,badge: true,sound: true,);
  await setupFlutterNotifications();
  // Your added code for handling messages while the app is in the background
  print('Handling a background message ${message.messageId}');
  print(' message ${message.toMap()}');
  if (message.notification != null) {
    if (message.notification != null) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print("Received a message: ${message.notification!.title}");
      });
      if (message.notification!.title!.contains("Juta Software")) {
        Map<String, dynamic> noti = {};
        RegExp regExp = RegExp(r'(\w+) Messaged Our Bot (\d+)');
        RegExpMatch? match = regExp.firstMatch(message.notification!.body!);

        String name = match?.group(1) ?? '';
        String phoneNumber = match?.group(2) ?? '';

// Format sent time

        String formattedSentTime = message.sentTime!.toLocal().toString();

        noti['name'] = name;
        noti['phone_number'] = phoneNumber;
        noti['formatted_time'] = formattedSentTime;
      noti['body'] = message.notification!.body;

        addNotificationToUser("001", noti);
      }
      print(
          'Message also contained a notification: ${message.notification!.title}');
    }
  }
}

bool isFlutterLocalNotificationsInitialized = false;
late AndroidNotificationChannel channel;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future<void> setupFlutterNotifications() async {
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  /// Create an Android Notification Channel.
  ///
  /// We use this channel in the `AndroidManifest.xml` file to override the
  /// default FCM channel to enable heads up notifications.
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          // TODO add a proper drawable resource to android, for now using
          //      one that already exists in example app.
          icon: 'launch_background',
        ),
      ),
    );
  }
}

FirebaseFirestore firestore = FirebaseFirestore.instance;
Future<void> addNotificationToUser(
    String companyId, Map<String,dynamic> notification) async {
  DocumentReference userRef = firestore.collection('companies').doc(companyId);
  await userRef.update({
    "notification": FieldValue.arrayUnion([
        {
          "name": notification['name'],
          "phone":notification['phone_number'],
          "read":false,
          "sentTime": notification['formatted_time'],
          "body":notification['body'],
        },
      ])
  });
}