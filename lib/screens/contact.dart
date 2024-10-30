// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:juta_app/utils/toast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Contact extends StatefulWidget {
  String companyId;
  String apiKey;
   String pipelineId;
   String stageId;
  Contact({super.key, required this.companyId, required this.apiKey, required this.pipelineId,required this.stageId});

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> {
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
   _showPickerType() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white,
                    width: 0.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // closing showCupertinoModalPopup
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                  ),
                  CupertinoButton(
                    child: Text('Confirm',
                      style: const TextStyle(
                        color: Color(0xFF3790DD),
                      ),),
                    onPressed: () {
                      setState(() {
                        type = _listType[types];
                        typeName =type;
                      });
                      Navigator.of(context)
                          .pop(); // closing showCupertinoModalPopup
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: types),
                backgroundColor: Colors.white,
                onSelectedItemChanged: (value) {
                  setState(() {
                    types = value;
                  });
                },
                itemExtent: 32.0,
                children: const [
                  Text(
                    'Private 1:1',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromARGB(255, 104, 104, 104),
                        fontWeight: FontWeight.w300),
                  ),
                  Text(
                    'Duo 2:1',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromARGB(255, 104, 104, 104),
                        fontWeight: FontWeight.w300),
                  ),
                 
                ],
              ),
            ),
          ],
        );
      },
    );
  }
   _showPickerSession() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white,
                    width: 0.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // closing showCupertinoModalPopup
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                  ),
                  CupertinoButton(
                    child: Text('Confirm',
                      style: const TextStyle(
                        color: Color(0xFF3790DD),
                      ),),
                    onPressed: () {
                      setState(() {
                        session = _listSession[sessions];
                        sessionName =session;
                      });
                      Navigator.of(context)
                          .pop(); // closing showCupertinoModalPopup
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: sessions),
                backgroundColor: Colors.white,
                onSelectedItemChanged: (value) {
                  setState(() {
                    sessions = value;
                  });
                },
                itemExtent: 32.0,
                children: const [
                  Text(
                    '1 Session',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromARGB(255, 104, 104, 104),
                        fontWeight: FontWeight.w300),
                  ),
                  Text(
                    '4 Session',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromARGB(255, 104, 104, 104),
                        fontWeight: FontWeight.w300),
                  ),
                   Text(
                    '10 Session',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromARGB(255, 104, 104, 104),
                        fontWeight: FontWeight.w300),
                  ),
                   Text(
                    '20 Session',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color.fromARGB(255, 104, 104, 104),
                        fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  void saveContact(BuildContext context) async {
    String name = nameController.text;
    String phoneNumber = phoneNumberController.text;
    if (name.isNotEmpty && phoneNumber.isNotEmpty) {
        Map<String, dynamic> userData = {
      'title': name, // Assuming 'title' is the field for name
      'name':name,
      'phone': phoneNumber,
      'status': 'open', // Set the desired status here
      'companyName': 'Your Company Name', // Set the company name
      'tags': [sessionName, typeName], // Set tags as needed
      'monetaryValue': 0, // Set monetary value as needed
      'stageId':widget.stageId
    };
final String apiUrl = 'https://rest.gohighlevel.com/v1/pipelines/${widget.pipelineId}/opportunities/';
  final String apiKey = widget.apiKey; // Replace with your actual API key

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
      print('Contact added successfully: ${response.body}');
      // You can parse the response here if needed.
      nameController.clear();
      phoneNumberController.clear();
      
      Toast.show(context, "success", "Contact Added");
    } else {
      print('Failed to add contact: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
      // Optionally, you can show a confirmation dialog or navigate to another screen.
    } else {
      // Handle case where one or both fields are empty.
      Toast.show(context, "danger", "Both cannot be empty");
      print("Both fields are required");
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
                        hintText: 'Phone Number',
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
            SizedBox(height: 20,),
               GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _showPickerSession();
            },
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.systemGrey5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                         width:90,
                        child: Text(
                          'Session',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (sessionName == ''),
                        replacement: Container(
                          width: 17,
                        ),
                        child: Row(
                          children: const [
                            SizedBox(width: 2),
                            Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              size: 6,
                              color: CupertinoColors.systemRed,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text(
                          (sessionName != null) ? sessionName! : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                    child: Icon(CupertinoIcons.chevron_right),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20,),
               GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
        _showPickerType();
            },
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.systemGrey5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                         width:90,
                        child: Text(
                          'Type',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (typeName == ''),
                        replacement: Container(
                          width: 17,
                        ),
                        child: Row(
                          children: const [
                            SizedBox(width: 2),
                            Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              size: 6,
                              color: CupertinoColors.systemRed,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 30),
                      child: Text(
                          (typeName != null) ? typeName! : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                    child: Icon(CupertinoIcons.chevron_right),
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
