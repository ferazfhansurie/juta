// ignore_for_file: unused_field, unnecessary_null_comparison

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:juta_app/home.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _selected = false;
  bool _isLoading = false;
  bool info = false;
  bool isDarkMode = false; // Add this line to track dark mode state
Future<void> saveDarkModePreference(bool isDarkMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDarkMode);
}
Future<bool> loadDarkModePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
}
 @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadDarkModePreference().then((value) {
    setState(() {
      isDarkMode = value;
    });
  });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
        body: SingleChildScrollView(
          child: Container(
          
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                height: MediaQuery.of(context).size.height,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 55,
                        ),
                        Container(
                             height: 200,
                             width: 200 ,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset('assets/images/logo2.png',
                         
                                fit: BoxFit.contain,),
                          ),
                        ),
            SizedBox(
                          height: 55,
                        ),
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
          
                                Container(
                                  decoration: BoxDecoration(
                           
                                      border: Border.all( color: colorScheme.onBackground,),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: TextField(
                                      style: TextStyle( color:  colorScheme.onBackground,
                                               fontFamily: 'SF',), 
                                      cursorColor:  colorScheme.onBackground,
                                      decoration:
                                          InputDecoration.collapsed(hintText: "Email address",hintStyle: TextStyle( color:  colorScheme.onBackground,),fillColor:Colors.white ),
                                      controller: _usernameController,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15,),
           Container(
                                  decoration: BoxDecoration(
                               
                                      border: Border.all( color:  colorScheme.onBackground,),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: TextField(
                                      style: TextStyle( color:  colorScheme.onBackground,
                                               fontFamily: 'SF',), 
                                      obscureText: true,
                                      cursorColor:  colorScheme.onBackground,
                                      decoration:
                                          InputDecoration.collapsed(hintText: "Password",hintStyle: TextStyle( color:  colorScheme.onBackground,
                                               fontFamily: 'SF',)),
                                      controller: _passwordController,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ),
                          SizedBox(
                            height: 55,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal:15.0),
                            child:  SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _login(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CupertinoColors.systemBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                          ),
      Padding(
        padding: const EdgeInsets.only(top:150),
        child: Center(
      child: Text(
                                          'Version 2.13',
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                              fontFamily: 'SF',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 109, 109, 109)),
                                        ),
        ),
      ),
                      ],
                    ),
                  ),
                ),
          
              ],
            ),
          ),
        ),
      ),
    );
  }

 

Future<void> _login(BuildContext context) async {
  final GlobalKey progressDialogKey = GlobalKey<State>();
  try {
    // Basic validation
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      throw 'Please enter both email and password';
    }

    ProgressDialog.show(context, progressDialogKey);
    String username = _usernameController.text.trim(); // Trim whitespace
    String password = _passwordController.text;

    // Print for debugging (remove in production)
    print('Attempting login with email: $username');
    
    final userCredential = await _auth.signInWithEmailAndPassword(
        email: username, password: password);
    
    if (userCredential.user != null) {
      ProgressDialog.unshow(context, progressDialogKey);
      Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) {
        return const Home();
      }));
    }
  } on FirebaseAuthException catch (e) {
    ProgressDialog.unshow(context, progressDialogKey);
    String errorMessage;
    
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found with this email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided.';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email format.';
        break;
      default:
        errorMessage = 'Error: ${e.message}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ),
    );
  } catch (e) {
    ProgressDialog.unshow(context, progressDialogKey);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An unexpected error occurred: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
}
