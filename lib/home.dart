import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
  import 'package:juta_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/conversations.dart';

class CustomTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomTabBar({required this.currentIndex, required this.onTap});

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  @override
  Widget build(BuildContext context) {
    return (kIsWeb) ? Container() : Padding(
      padding: EdgeInsets.only(bottom: 20, left: 65, right: 65), // Updated padding
      child: Container(
        width: 50,
        height: 65,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildTabItem(Icons.home_filled, 0),
             //buildTabItem(Icons.notifications, 1),
              //buildTabItem(CupertinoIcons.calendar, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTabItem(IconData icon, int index) {
    bool isSelected = index == widget.currentIndex;

    return InkWell(
      onTap: () => widget.onTap(index),
      splashColor: Colors.transparent,
      child: Container(
        child: Icon(
          icon,
          size: 35,
          color: isSelected ? Colors.white : Color(0xFFB3B3B3),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String email = '';
  String firstName = '';
  String company = '';
    bool isDarkMode = false; // Add this line to track dark mode state
  Future<bool> loadDarkModePreference() async {
  final prefs = await SharedPreferences.getInstance();

  return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
  
}
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    email = user!.email!;
      loadDarkModePreference().then((value) {
    setState(() {
      isDarkMode = value;
    });
  });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void onTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  Future<void> openDrawer() async {
    // Use a GlobalKey to access the Scaffold and open the drawer
    FirebaseFirestore.instance
        .collection("user")
        .doc(email)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          firstName = snapshot.get("name");
          company = snapshot.get("company");
          print(firstName);
        });
      } else {
        print("Snapshot not found");
      }
    });
    _scaffoldKey.currentState?.openDrawer();
  }
 Future<void> conversationPage() async {
    // Use a GlobalKey to access the Scaffold and open the drawer
   setState(() {
      currentIndex = 1;
    });
  }

  Future<void> fetchUserData(String email) async {
    String apiKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb2NhdGlvbl9pZCI6Ikxja1g3eG1yT1VCdzhqOUcyblVyIiwiY29tcGFueV9pZCI6IjUzSGdWeXh4b05VYzV0Smd3OGZLIiwidmVyc2lvbiI6MSwiaWF0IjoxNjkzOTI4ODczNTc2LCJzdWIiOiJ1c2VyX2lkIn0.U1Uxi9q5WvQZ7L4QGnmqGUGUw11Sc5VXB8FlQW_RrYE'; // Replace with your actual token
    String apiUrl = "https://rest.gohighlevel.com/v1/users/lookup?email=$email";

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      print(response.body);
      if (response.statusCode == 200) {
        // Parse the response JSON
        var userData = json.decode(response.body);
        // Now you have the user data, you can use it to populate your Drawer
        print(userData);
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: (kIsWeb) ? null : Drawer(
        width: 225,
        child: Container(
          color: isDarkMode ? Colors.black : Colors.white,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 50, horizontal: 10),
                  children: [
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            CupertinoIcons.person_alt_circle, 
                            size: 50,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          Text(
                            firstName,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            "View Profile",
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(color: isDarkMode ? Colors.white : Colors.black),
                    ListTile(
                      title: Text(
                        'About Us',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        )
                      ),
                      onTap: () {
                        // Add your functionality for this sidebar item
                      },
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await AuthenticationService(auth).signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Color(0xFF111B21),
                        borderRadius: BorderRadius.circular(8)),
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent),
                        Text(
                          "Log Out",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body:IndexedStack(
        index: currentIndex,
        children: [
          Conversations(),
          //NotificationScreen(),
          //Appointment(),
        ],
      ),

    );
  }
}