

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/screens/add_appointment.dart';
import 'package:juta_app/screens/drip.dart';
import 'package:juta_app/utils/toast.dart';

// ignore: must_be_immutable
class LeadAppointmentScreen extends StatefulWidget {
  List<dynamic> opp;
String userId;
String token;
String calendarId;
  LeadAppointmentScreen({super.key, required this.opp,required this.userId,required this.token,required this.calendarId});

  @override
  State<LeadAppointmentScreen> createState() => _LeadAppointmentScreenState();
}

class _LeadAppointmentScreenState extends State<LeadAppointmentScreen> {
  TextEditingController searchController = TextEditingController();
  bool checkAll = false;
    List<dynamic> selected = [];
  @override
  void initState() {
 
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top , left: 20, right: 20),
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
            SizedBox(
              height: 25,
            ),
            SizedBox(
                height: MediaQuery.of(context).size.height*89/100,
                width: double.infinity,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 216, 215, 215),
                              borderRadius: BorderRadius.circular(15)),
                          height: 45,
                          child: TextField(
                            style: const TextStyle(color: Color(0xFF2D3748),
                                           fontFamily: 'SF',),
                            cursorColor: Colors.white,
                            controller: searchController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              focusColor: Colors.white,
                              hoverColor: Colors.white,
                              hintText: 'Search',
                              hintStyle: TextStyle(
                                  color: Color(0xFF2D3748),
                                           fontFamily: 'SF', fontSize: 15),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 22,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                
                    Divider(
                      height: 1,
                    ),
                    Flexible(
                        child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: widget.opp.length,
                            itemBuilder: (context, index) {
                    
                              return GestureDetector(
                                onTap: (){
     Navigator.of(context)
                                .push(CupertinoPageRoute(builder: (context) {
                              return AddAppointment(
                                opp:widget.opp[index],
                                userId: widget.userId,
                                calendarId: widget.calendarId,
                                token: widget.token,
                              );
                            }));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Card(
                                                              
                                    child: ListTile(
                                    leading:  Container(
                                   height: 35,
                            width:35,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2D3748),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(child: Text(  widget.opp[index]['name'].isNotEmpty ?   widget.opp[index]['name'].substring(0, 1).toUpperCase() : '',style: TextStyle(color: Colors.white,fontSize: 14),)),
                                ),
                                      title: Text(
                                        widget.opp[index]['name'],
                                        style: TextStyle(color: Color(0xFF2D3748),
                                               fontFamily: 'SF',fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.opp[index]['contact']['phone'],
                                            style: TextStyle(color: Color(0xFF2D3748),
                                                   fontFamily: 'SF',),
                                          ),
                                          Text(
                                        widget.opp[index]['contact']['email'] ?? "",
                                        style: TextStyle(color: Color(0xFF2D3748),
                                               fontFamily: 'SF',),
                                      ),
                                        ],
                                      ),
                             
                                    ),
                                  ),
                                ),
                              );
                            })),
              
                  ],
                )),
          ],
        ),
      ),
    );
  }

  _showBlastSetting(double height, List<dynamic> selected) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        print(selected);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white,
                    width: 0.0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Blasting Setting',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 16,
                                           fontFamily: 'SF',
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),
            Container(
                color: Colors.black,
                height: height,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 100,
                              child: Text(
                                'Now',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 16,
                                           fontFamily: 'SF',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            Icon(Icons.send_outlined),
                          ],
                        ),
                      ),
                      Divider(
                        color: Color.fromARGB(255, 19, 19, 19),
                      ),
                   /*   Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: 100,
                            child: Text(
                              'Scehdule',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  fontSize: 16,
                                           fontFamily: 'SF',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Icon(CupertinoIcons.clock),
                        ],
                      ),
                      Divider(
                        color: Color.fromARGB(255, 19, 19, 19),
                      ),*/
                      GestureDetector(
                        onTap: () {
                      
                         
                        },
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 100,
                                child: Text(
                                  'Drip',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                              Icon(CupertinoIcons.drop),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  void sendAllAtOnce(List<dynamic> selectedContacts) {
    for (var contact in selectedContacts) {
      if (selected.contains(contact)) {
        String contactId = contact['id'];
        print(contactId);
        // Construct the webhook URL
   

         Toast.show(context,"success","Message Sent");
        Navigator.pop(context,true);
      }
    }
  }

  void sendToWebhook(String webhookUrl, String contactId) async {
    try {
      Map<String, dynamic> leadData = {'contact': contactId};
      var response = await http.post(
        Uri.parse(webhookUrl),
        body: leadData,
      );

      print(response.body);
      if (response.statusCode == 200) {
        print('Webhook triggered successfully for contact ID: $contactId');
       
      } else {
        print(
            'Error triggering webhook for contact ID: $contactId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering webhook for contact ID: $contactId: $e');
    }
  }
}
