// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juta_app/services/auth_service.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:juta_app/utils/toast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddUser extends StatefulWidget {
  String companyId;
  String apiKey;
String email;
String locationId;
String company;
  AddUser({super.key, required this.companyId, required this.apiKey,required this.email,required this.locationId,required this.company });

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  String session = "";
  int sessions =0;
     String sessionName = "";
       String type = "";
  int types =0;
     String typeName = "";
   List<String> _listSession = ['1', '4','10','20'];
   List<String> _listType = ['Private 1:1','Duo 2:1'];
  FirebaseAuth auth = FirebaseAuth.instance;
  
void saveContact(BuildContext context) async {
  String name = nameController.text;
  String email = phoneNumberController.text; // Using email instead of phoneNumber
  print(widget.apiKey);
  print(widget.email);
  String? locationId = widget.locationId;
  print(locationId);
      final GlobalKey progressDialogKey = GlobalKey<State>();
    ProgressDialog.show(context, progressDialogKey);
  if (name.isNotEmpty && email.isNotEmpty && locationId != null) {
    // Register user in Firebase authentication
    try {
      // Creating Firebase user as admin


      // Now you can proceed to add the user to HighLevel
      Map<String, dynamic> userData = {
        'firstName': name,
        'email': email,
        'type': 'account',
        'role': 'user',
        'locationIds': [locationId],
        "password": "123456",
        "permissions": {
          "campaignsEnabled": true,
          "campaignsReadOnly": false,
          "contactsEnabled": true,
          "workflowsEnabled": true,
          "triggersEnabled": true,
          "funnelsEnabled": true,
          "websitesEnabled": false,
          "opportunitiesEnabled": true,
          "dashboardStatsEnabled": true,
          "bulkRequestsEnabled": true,
          "appointmentsEnabled": true,
          "reviewsEnabled": true,
          "onlineListingsEnabled": true,
          "phoneCallEnabled": true,
          "conversationsEnabled": true,
          "assignedDataOnly": false,
          "adwordsReportingEnabled": false,
          "membershipEnabled": false,
          "facebookAdsReportingEnabled": false,
          "attributionsReportingEnabled": false,
          "settingsEnabled": true,
          "tagsEnabled": true,
          "leadValueEnabled": true,
          "marketingEnabled": true
        }
      };

      const String apiUrl = 'https://rest.gohighlevel.com/v1/users/';
      final String apiKey = widget.apiKey;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(userData),
      );

      print(response.body);

      if (response.statusCode == 200) {
        print('User added successfully to HighLevel: ${response.body}');
        // You can parse the response here if needed.
   
  final userCredential =
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: "123456"
    );
 await FirebaseFirestore.instance.collection('user').doc(email).set({
        'name': name,
        'email': email,
        'company': widget.company,
        'companyId': widget.companyId,
        // Add other user data as needed
      });
   await FirebaseFirestore.instance.collection('companies').doc(widget.companyId)
        .collection('employee').doc(email).set({
      'name': name,
      // Add other employee data as needed
    });
       await AuthenticationService(auth).signOut();
           final user = await auth.signInWithEmailAndPassword(
        email: email, password: '123456');
        
         ProgressDialog.unshow(context, progressDialogKey);
              nameController.clear();
        phoneNumberController.clear();
        Toast.show(context, "success", "User Added");
      } else {
        print('Failed to add user to HighLevel: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Handle the failure case here
         ProgressDialog.unshow(context, progressDialogKey);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
         ProgressDialog.unshow(context, progressDialogKey);
      } else if (e.code == 'email-already-in-use') {
         ProgressDialog.unshow(context, progressDialogKey);
        print('The account already exists for that email.');
      }
       ProgressDialog.unshow(context, progressDialogKey);
      print('Firebase authentication error: $e');
    } catch (e) {
       ProgressDialog.unshow(context, progressDialogKey);
      print('Error: $e');
    }
  } else {
    // Handle case where one or both fields are empty.
     ProgressDialog.unshow(context, progressDialogKey);
    Toast.show(context, "danger", "Both cannot be empty");
    print("Both fields are required");
  }
}
Future<String?> getLocationId(String email, String apiKey) async {
  try {
    final response = await http.get(
      Uri.parse('https://rest.gohighlevel.com/v1/locations/lookup?email=$email'),
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );
print(response.body);
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String? locationId = responseData['id'];
      return locationId;
    } else {
      print('Failed to get locationId: ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error: $e');
    return null;
  }
  
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF3790DD),
                      fontSize: 16,
                      fontFamily: 'SF',
                      fontWeight: FontWeight.w500,
                      height: 0,
                    ),
                  ),
                ),
              
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Icon(CupertinoIcons.person_circle,
                  color: Color(0xFF2D3748), size: 50),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Color.fromARGB(255, 210, 210, 210),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  children: [
                 
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Name',
                        hintStyle: TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 16,
                          fontFamily: 'SF',
                          fontWeight: FontWeight.w400,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.transparent, // Remove border color
                            width: 0,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.transparent, // Remove border color
                            width: 0,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 16,
                        fontFamily: 'SF',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                            Divider(
                      color: Color(0xFF2D3748),
                    ),
                    TextField(
                      controller: phoneNumberController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: Color(0xFF2D3748),
                          fontSize: 16,
                          fontFamily: 'SF',
                          fontWeight: FontWeight.w400,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.transparent, // Remove border color
                            width: 0,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.transparent, // Remove border color
                            width: 0,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 16,
                        fontFamily: 'SF',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
               
                  ],
                ),
              ),
            ),
        
         
            Spacer(),
            GestureDetector(
              onTap: () {
          
              saveContact(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Container(
                  width: 260,
                  height: 46,
                  decoration: BoxDecoration(
                      color: Color(0xFF2D3748),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Add",
                        style: TextStyle(color: Colors.white,
                                           fontFamily: 'SF', fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
 

}
