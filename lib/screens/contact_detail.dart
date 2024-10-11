// ignore_for_file: sized_box_for_whitespace, use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/screens/tags.dart';
import 'package:juta_app/utils/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetail extends StatefulWidget {
   ContactDetail({super.key, this.labels, this.name,
    this.phone, this.botToken,
    this.accessToken, this.contactId,
    this.conversation, this.integrationId,
    this.botId, this.pipelineId,
this.opportunity});

  String? accessToken;
  String? botId;
  String? contactId;
  String? conversation;
  String? integrationId;
  String? botToken;
  List<dynamic>? labels ;
  String? name;
  Map<String, dynamic>? opportunity;
  String? phone;
  String? pipelineId;

  @override
  State<ContactDetail> createState() => _ContactDetailState();
}

class _ContactDetailState extends State<ContactDetail> {
     String companyId = "";
  List<String> dropdownItems = [];
     String email = "";
   TextEditingController nameController = TextEditingController();
    TextEditingController phoneController = TextEditingController();
     int selectedValue = 0; // Store the selected value index
     bool typing = false;
      User? user = FirebaseAuth.instance.currentUser;

     @override
  void initState() {
    // TODO: implement initState
    nameController.text = widget.name!;
    phoneController.text = widget.phone!;
     email = user!.email!;
    getCompany();
    super.initState();
  }

  Future<void> updateOpportunityWithTags(
  String apiKey,
  String pipelineId,
  String opportunityId,
  Map<String, dynamic> opportunityData,
  List<dynamic> tags,
) async {
  final String baseUrl =
      'https://rest.gohighlevel.com/v1/pipelines/$pipelineId/opportunities/$opportunityId';

  try {
    // Add tags to the opportunity data
    opportunityData['title'] = opportunityData['name'];
    opportunityData['tags'] = tags;

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(opportunityData),
    );
print(response.body);
    if (response.statusCode == 200) {
      // Opportunity updated successfully
      print('Opportunity updated with tags');
    } else {
      // Request failed with a non-200 status code
      print('Failed to update opportunity: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    // Handle any errors that occur during the request
    print('Error: $error');
  }
}

Future<void> getCompany() async {
  try {
    await FirebaseFirestore.instance
        .collection("user")
        .doc(email)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          companyId = snapshot.get("companyId");
        });
      } else {
        print("Snapshot not found");
      }
    });

    final companySnapshot = await FirebaseFirestore.instance
        .collection("companies")
        .doc(companyId)
        .collection("employee")
        .get();

    if (companySnapshot.docs.isNotEmpty) {
      // Clear the notifications list before adding data from documents
      dropdownItems.clear();

      for (final doc in companySnapshot.docs) {
    
        final data = doc.data();
      dropdownItems.add(data['name']);
      print(data.toString());
        setState(() {
          
        });
      }

    
    } else {
      print("No documents found in Employee subcollection");
    }
  } catch (e) {
    print("Error: $e");
  }
}

    Future<void> addTagsToContact( List<dynamic> tags) async {
  final String baseUrl = 'https://rest.gohighlevel.com/v1/contacts/${widget.contactId}/tags/';
  final String apiKey = widget.accessToken!; // Replace 'YOUR_API_KEY' with your actual API key

  // Create the request body
  Map<String, dynamic> requestBody = {
    "tags": tags,
  };

  // Convert the request body to JSON
  String jsonBody = json.encode(requestBody);

  // Set up the headers
  Map<String, String> headers = {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  try {
    // Send POST request to add tags to the contact
    http.Response response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonBody,
    );
    if (response.statusCode == 200) {
    //  await _handleRefresh();
      Navigator.pop(context);
      Toast.show(context,'success','Tag Added');
   
      print('Tags added to contact successfully');
    } else {
      // Handle the error
          Toast.show(context,'danger','Failed to add tags');
      print('Failed to add tags. Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    // Handle any potential exceptions
    print('Error adding tags: $error');
  }



}

  Future<void> deleteConversation(String conversationId) async {
  String url = 'https://api.botpress.cloud/v1/chat/conversations/$conversationId';

  http.Response response = await http.delete(
    Uri.parse(url),
    headers: {
      'Content-type': 'application/json',
      'Authorization': 'Bearer ${widget.botToken}',
      'x-bot-id': widget.botId!,
      'x-integration-id': widget.integrationId!,
    },
  );
  print(response.body);
  if (response.statusCode == 200) {
    Navigator.pop(context);
     Navigator.pop(context);
    // Optionally, navigate away or update the UI
  } else {
    // Handle error
  }
}

 Future<bool> deleteContact(String pipelineId, String opportunityId, String token) async {
    final url = Uri.parse('https://rest.gohighlevel.com/v1/pipelines/$pipelineId/opportunities/$opportunityId');
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Assuming a successful deletion doesn't return a body, or change as needed
      Toast.show(context, "success", "Contact Deleted");
      Navigator.pop(context);
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized request. Check the access token.');
    } else {
      throw Exception('Failed to delete opportunity. Status code: ${response.statusCode}');
    }
  }
      Widget _buildCupertinoPicker() {
    return Column(
      children: [
        Text(
                                                 "Assigned Salesman",
                                                 style: TextStyle(fontSize: 16.0, color: Color(0xFF2D3748),
                                               fontFamily: 'SF',),
                               ),
        Container(
          height: 100.0,
          color: Colors.white,
          child: CupertinoPicker(
            
            itemExtent: 32.0,
            onSelectedItemChanged: (int index) {
              setState(() {
                selectedValue = index;
              });
            },
            children: List<Widget>.generate(dropdownItems.length, (int index) {
              return Center(
                child: Text(
                  dropdownItems[index],
                  style: TextStyle(fontSize: 20.0),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: 'SF',
      ),
      child: Center(
        child: Scaffold(
          floatingActionButton: Container(
            height: 65,
            width: 65,
decoration:BoxDecoration(
  borderRadius: BorderRadius.circular(100),
  color: Color(0xFF2D3748),
),
            child:   GestureDetector(
              onTap: (){
          
                _launchWhatsapp(widget.opportunity!['contact']['phone']);
              },
               child: Image.asset(
                                        'assets/images/whatsapp.png',
                                        fit: BoxFit.contain,
                                        scale: 9,
                                      ),
             ),
          ),
       appBar: AppBar(
        backgroundColor:Color.fromARGB(255, 255, 255, 255),
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child:Text( 'Cancel',style: TextStyle( color: Color(0xFF2D3748),fontSize: 16),
                     )),
          
              
            
               GestureDetector(
               
                child: Container(
                
                  child: Text("Edit Opportunity",style: const TextStyle(color: Color(0xFF2D3748),fontSize: 18),)),
              ),
          
              
            
          
          
              
              GestureDetector(
                  onTap: () async {
                    widget.labels!.add(dropdownItems[selectedValue]);
                   await addTagsToContact(widget.labels!);
                    updateOpportunityWithTags(
                      widget.accessToken!,
                      widget.pipelineId!,
                     widget.opportunity!['id'],
                      widget.opportunity!,
                     widget.labels!
                    );
                    print( widget.opportunity);
                Toast.show(context, "success", "Contact Saved");
                  },
                  child:Text( 'Save',style: TextStyle( color: Color.fromARGB(255, 59, 123, 233),fontSize: 16),
                     )),
                 
                         
               
                  
            ],
          ),
        ),

      ),
          body:  Builder(builder: (context) {
                  return Container(
                
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        left: 20,
                        right: 20
                      ),
                      child: Column(
                       
                        children: [
                          Center(
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color:  Color(0xFF2D3748),
                                borderRadius: BorderRadius.circular(100)
                              ),
                              child: Center(child: Text( widget.name!.substring(0, 1).toUpperCase(),style: TextStyle(color: Colors.white,fontSize: 40)),),
                            ),
                          ),
                       SizedBox(height: 10,),
                                 _buildCupertinoPicker(),
                                         Divider(),
                          SizedBox(height: 20,),
                              Container(
                           decoration: BoxDecoration(
                            color: Color.fromARGB(255, 182, 183, 187),
                            borderRadius: BorderRadius.circular(8)
                          ),
                           child: Padding(
                             padding: const EdgeInsets.all(4),
                            child: TextField(
                                                  controller: nameController,
                                                  decoration: InputDecoration(
                              hintText: 'Name',
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'SF',
                                fontWeight: FontWeight.w400,
                              ),
                             
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(0, 122, 122, 122), // Remove border color
                                  width: 0,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(0, 78, 78, 78), // Remove border color
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
                          ),
                        ),
                         SizedBox(height: 20,),
                              Container(
                           decoration: BoxDecoration(
                            color: Color.fromARGB(255, 182, 183, 187),
                            borderRadius: BorderRadius.circular(8)
                          ),
                           child: Padding(
                             padding: const EdgeInsets.all(4),
                            child: TextField(
                                                  controller: phoneController,
                                                  decoration: InputDecoration(
                              hintText: 'Phone',
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'SF',
                                fontWeight: FontWeight.w400,
                              ),
                             
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(0, 122, 122, 122), // Remove border color
                                  width: 0,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: const Color.fromARGB(0, 78, 78, 78), // Remove border color
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
                          ),
                        ),
                        Divider(),
                        if(widget.labels != null)
                          Container(
                                      height: 40,
                                     
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          shrinkWrap: true,
                                          itemCount: widget.labels!.length,
                                          itemBuilder: ((context, index) {
                                          return   Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 5),
                                            child: Card(
                                             color: Color(0xFF2D3748),
                                              child: Container(
                                               
                                              
                                                child: Padding(
                                                  padding: const EdgeInsets.all(5),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      
                                                      Text(
                                                                                               widget.labels![index],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                         fontFamily: 'SF',
                                                       
                                                      fontSize: 18
                                                                                              
                                                      ),
                                                                                              ),
                                                                                          
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        })),
                                      ),
                                      SizedBox(height: 20,),
                   
               Divider(),
           
                   
                        ],
                      ),
                    ),
                  );
                }),
            
        ),
      ),
    );
    
  }
    void _launchWhatsapp(String number) async {
    String url = 'https://wa.me/$number';
    try {
      await launch(url);
    } catch (e) {
      throw 'Could not launch $url';
    }
  }
} 