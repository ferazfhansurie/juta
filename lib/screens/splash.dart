
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = FirebaseAuth.instance;
  bool isDarkMode = false; // Add this line to track dark mode state
  @override
  void initState() {
    super.initState();
  loadDarkModePreference().then((value) {
    setState(() {
      isDarkMode = value;
    });
  });
    _initFirebaseMessaging();
    Future.delayed(const Duration(milliseconds: 500), () {
      _autoLogin(context);
    });
  }
Future<bool> loadDarkModePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
}
  @override
  Widget build(BuildContext context) {
     
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
  ));
    final colorScheme = isDarkMode
        ? ColorScheme.dark(
            primary: Color(0xFF101827),
            secondary: Colors.tealAccent,
            surface: Color(0xFF1F2937),
            background: Color(0xFF101827),
            onBackground: Colors.white,
          )
        : ColorScheme.light(
            primary: Color(0xFF2D3748),
            secondary: Color(0xFF2D3748),
            surface: Colors.white,
            background: Colors.white,
            onBackground: Color(0xFF2D3748),
          );

    return Theme(
      data: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.background,
          foregroundColor: colorScheme.onBackground,
        ),
        // ... other theme properties ...
      ),
      child: Scaffold(
       
        body: Container(
             color: colorScheme.background,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Center(
            child:  Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset('assets/images/logo2.png',
                              fit: BoxFit.contain, width: 75),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  void _initFirebaseMessaging() {
    // TODO: Firebase messaging
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //   if (NotificationService().notificationDetails != null) {
    //     await flutterLocalNotificationsPlugin.show(
    //       (DateTime.now().millisecondsSinceEpoch /1000).floor(),
    //       message.notification!.title,
    //       message.notification!.body,
    //       NotificationService().notificationDetails,
    //       payload: jsonEncode(message.data),
    //     );
    //   }
    // });
    //
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    //   NotificationService().gotoNotification(message.data);
    // });
  }

  Future<void> _autoLogin(context) async {
       print("home");
      Navigator.pushReplacementNamed(context, '/home');
 User? user = _auth.currentUser;
    if (user != null) {
   
    } else {
      print("login");
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
