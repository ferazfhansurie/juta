import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:juta_app/screens/blast.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/utils/progress_dialog.dart';

class AutomationScreen extends StatefulWidget {
  @override
  _AutomationScreenState createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  List<String> automationNames = []; // List to store automation names
  String companyId = "";
  String email = "";
  User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> automation = [];
  List<dynamic> opp = [];
    String ghlToken = '';
       final GlobalKey progressDialogKey = GlobalKey<State>();
    List<dynamic> pipelines = [];
  @override
  void initState() {
    super.initState();
    email = user!.email!;
    getUser();
  }

  Future<void> getUser() async {
    await FirebaseFirestore.instance
        .collection("user")
        .doc(email)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          companyId = snapshot.get("companyId");
        });
       
        getAutomations(); // Call getAutomations here
      } else {
        print("Snapshot not found");
      }
  
    });
        await  FirebaseFirestore.instance
          .collection("companies")
          .doc(companyId)
          .get()
          .then((snapshot) async {
        if (snapshot.exists) {
          setState(() {
            ghlToken = snapshot.get("ghlToken");
          });
          Map<String, dynamic>? data = snapshot.data();
        }});
  }

  void getAutomations() async {
    QuerySnapshot? querySnapshot;
    try {
      querySnapshot = await FirebaseFirestore.instance
          .collection("companies")
          .doc(companyId)
          .collection("automations")
          .get();
    } catch (error) {
      print("Error fetching automations: $error");
      return;
    }

    List<Map<String, dynamic>> automationsData = [];
    if (querySnapshot.docs.isNotEmpty) {
      querySnapshot.docs.forEach((doc) {
        var automationData = doc.data() as Map<String, dynamic>;
        print(automationData);

        if (automationData.containsKey('name') &&
            automationData.containsKey('webhook')&&
            automationData.containsKey('body')
            ) {
          String name = automationData['name'];
          String webhook = automationData['webhook'];
 String body = automationData['body'];
 String image = automationData['image']??"";
          automationsData.add({
            'name': name,
            'webhook': webhook,
             'body': body,
              'image': image,
          });
        }
      });
    } else {
      print("No automations found");
    }

    setState(() {
      automation = automationsData;
    });
  }
  
Future<List<dynamic>> fetchPipelines() async {
  String baseUrl = 'https://rest.gohighlevel.com';
  String endpoint = '/v1/pipelines/';

  Uri uri = Uri.parse(baseUrl + endpoint);
  String token = ghlToken; // Your GoHighLevel API token

  try {
    http.Response response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
     pipelines = responseBody['pipelines'] as List<dynamic>;


      return pipelines; // Return the list of pipelines
    } else {
      print('Failed to fetch pipelines: ${response.statusCode}');
      return []; // Return an empty list in case of failure
    }
  } catch (error) {
    print('Error fetching pipelines: $error');
    return []; // Return an empty list in case of error
  }
}
Future<void> fetchOpportunitiesFromFirstPipeline() async {
  pipelines = await fetchPipelines();
  if (pipelines.isNotEmpty) {
    String firstPipelineId = pipelines[0]['id'];
    setState(() {
});
    // Fetch the rest of the opportunities in the background
    
     opp.addAll(await fetchAllOpportunitiesFromPipeline(firstPipelineId)) ;
     
  ProgressDialog.unshow(context, progressDialogKey);
  }
}
Future<List<dynamic>> fetchAllOpportunitiesFromPipeline(String pipelineId, {int? maxOpportunities}) async {
  String baseUrl = 'https://rest.gohighlevel.com';
  String endpoint = '/v1/pipelines/$pipelineId/opportunities';
  String token = ghlToken; // Your GoHighLevel API token
  List<dynamic> allOpportunities = [];
  String? nextPageUrl;
  int fetchedOpportunities = 0;
 opp.clear();
  do {
    Uri uri = nextPageUrl == null ? Uri.parse(baseUrl + endpoint) : Uri.parse(nextPageUrl);

    try {
      http.Response response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        List<dynamic> opportunities = responseBody['opportunities'] ?? [];
        nextPageUrl = responseBody['meta']['nextPageUrl'];

        allOpportunities.addAll(opportunities);
        fetchedOpportunities += opportunities.length;

        // Check if maximum number of opportunities has been reached
        if (maxOpportunities != null && fetchedOpportunities >= maxOpportunities) {
          break;
        }

        if (opportunities.isEmpty) {
          break;
        }
      } else {
        print('Failed to fetch opportunities: HTTP ${response.statusCode} - ${response.reasonPhrase}');
        break; // Exit the loop on failure
      }
    } catch (error) {
      print('Error fetching opportunities: $error');
      break; // Exit the loop on exception
    }
  } while (nextPageUrl != null);

  return allOpportunities;
}
  Future<void> callAutomation(Map<String, dynamic> automationName) async {
 ProgressDialog.show(context, progressDialogKey);
   await fetchOpportunitiesFromFirstPipeline();
  
     print("Contacts loaded successfully: $opp");
       Navigator.of(context)
                              .push(CupertinoPageRoute(builder: (context) {
                            return BlastScreen(opp: opp,auto:automationName);
                          }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Blast",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 22,
                                           fontFamily: 'SF',
                          fontWeight: FontWeight.bold,
                           color: Color(0xFF2D3748),)),
            Flexible(
          
              child: ListView.builder(shrinkWrap: true,
                itemCount: automation.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical:8.0),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            automation[index]['name'],
                            style: TextStyle(fontSize: 18,
                                           fontFamily: 'SF',
                          fontWeight: FontWeight.bold,
                           color: Color(0xFF2D3748)),
                          ),
                          subtitle:Column(
                            children: [
                              if(automation[index]['image'] != "")
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius:BorderRadius.circular(8),
                                  child: Image.network(automation[index]['image'])),
                              ),
                              Card(
                                color: Color(0xFF0D85FF),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(automation[index]['body'],
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Color.fromARGB(255, 255, 255, 255),
                                               fontFamily: 'SF',
                                                      fontWeight: FontWeight.w400,
                                                    ),),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            
                            callAutomation(automation[index]);
                          },
                        ),
                        Divider(color:Color.fromARGB(255, 19, 19, 19),height: 2 ,)
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
