

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/utils/toast.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationScreen extends StatefulWidget {

  NotificationScreen({super.key,});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  User? user = FirebaseAuth.instance.currentUser;
  String email = '';
bool isDarkMode = false; // Add this line to track dark mode state
  @override
  void initState() {
    super.initState();
    email = user!.email!;
    loadDarkModePreference().then((value) {
    setState(() {
      isDarkMode = value;
    });
  });
    getUser();
  }
Future<bool> loadDarkModePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
}
 Future<void> getUser() async {
    try {
      await FirebaseFirestore.instance
          .collection("user")
          .doc(email)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          setState(() {
           // companyId = snapshot.get("companyId");
          });
        } else {
          print("Snapshot not found");
        }
      });

      final userSnapshot = await FirebaseFirestore.instance
          .collection("user")
          .doc(email)
          .collection("notifications")
          .get();

     List<dynamic> uniqueNotifications = userSnapshot.docs.map((doc) => doc.data()).toList();

    // Sort notifications by timestamp in descending order
 
uniqueNotifications.sort((a, b) {
  DateTime timestampA = convertToDateTime(a['timestamp']);
  DateTime timestampB = convertToDateTime(b['timestamp']);
  return timestampB.compareTo(timestampA);
});
    setState(() {
      notifications = uniqueNotifications;
    });
    } catch (e) {
      print("Error: $e");
    }
  }

DateTime convertToDateTime(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  } else if (timestamp is DateTime) {
    return timestamp;
  } else {
    print('Unexpected timestamp type: ${timestamp.runtimeType}');
    return DateTime.now(); // Fallback to current time
  }
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
    return Theme
    (
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
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 
                      children: [
                         IconButton(
                              icon: Icon(
                               Icons.chevron_left,
                                color: colorScheme.onBackground,
                                size: 50,
                              ),
                              onPressed: (){
                                Navigator.of(context).pop();
                              }
                            ),
                        Text(
                          'Notifications',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF',
                            color: colorScheme.onBackground,
                          ),
                        ),
                                   IconButton(
  icon: Icon(
    CupertinoIcons.clear,
    color: colorScheme.onBackground,
    size: 30,
  ),
  onPressed: () async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.background,
      title: Text('Delete All Notifications', style: TextStyle(color: colorScheme.onBackground)),
          content: Text('Are you sure you want to delete all notifications?', style: TextStyle(color: colorScheme.onBackground)),
          actions: <Widget>[
           TextButton(
              child: Text('Cancel', style: TextStyle(color: colorScheme.onBackground)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Delete all notifications from Firestore
        await FirebaseFirestore.instance
            .collection("user")
            .doc(email)
            .collection("notifications")
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        // Clear local notifications list
        setState(() {
          notifications.clear();
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All notifications deleted')),
        );
      } catch (e) {
        print("Error deleting notifications: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notifications')),
        );
      }
    }
  },
),

                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: notifications.isEmpty ? 1 : notifications.length,
                    itemBuilder: (context, index) {
                      if (notifications.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 150,),
                            Icon(Icons.refresh, color: colorScheme.onBackground),
                            Center(
                              child: Text(
                                'No notifications available\nPull to Refresh',
                                textAlign: TextAlign.center,
                                style:  TextStyle(
                                  color: colorScheme.onBackground,
                                  fontFamily: 'SF',
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
        
                      final notification = notifications[index];
                      final dateFormat = DateFormat('h:mm a d/M/yyyy');
            print( notifications.length);
                      // Ensure the timestamp is converted to a DateTime object
                      DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
                        notification['timestamp'] * 1000,
                      );
        
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 200,
                                child: Text(
                                  notification['from'] ?? "Webchat",
                                  maxLines: 3,
                                  style:  TextStyle(
                                    color: colorScheme.onBackground,
                                    fontFamily: 'SF',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Row(
                                  children: [
                                    if (notification['read'] == false)
                                      Card(
                                        color: Colors.red,
                                        child: Container(height: 10, width: 10,),
                                      ),
                                    Text(
                                      dateFormat.format(dateTime) ?? "",
                                      style:  TextStyle(
                                        color: colorScheme.onBackground,
                                        fontFamily: 'SF',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notification['text']?['body'] ?? "Unreadable",
                            style:  TextStyle(
                              color: colorScheme.onBackground,
                              fontFamily: 'SF',
                              fontWeight: FontWeight.w400,
                              fontSize: 14
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                            height: 1,
                            color: Color.fromARGB(255, 153, 155, 158),
                            thickness: 1,
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    getUser();
    setState(() {});
  }
}
