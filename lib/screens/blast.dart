

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/screens/drip.dart';
import 'package:juta_app/utils/toast.dart';

// ignore: must_be_immutable
class BlastScreen extends StatefulWidget {
  List<dynamic> opp;
  Map<String, dynamic>? auto;
  int? from ;
  BlastScreen({super.key, required this.opp,  this.auto,this.from});

  @override
  State<BlastScreen> createState() => _BlastScreenState();
}

class _BlastScreenState extends State<BlastScreen> {
  TextEditingController searchController = TextEditingController();
  bool checkAll = false;
    List<dynamic> selected = [];
    TextEditingController _messageController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    if( widget.from == 0){
   
      checkAll = true;
      selected.addAll(widget.opp);
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

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
                GestureDetector(
                  onTap: () {
                  
                  
                    print(selected);
                   sendAllAtOnce(selected);
                  },
                  child: const Text(
                    'Send',
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
                height: 600,
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select All",
                              style: TextStyle(fontSize: 16,
                                           fontFamily: 'SF',
                          fontWeight: FontWeight.bold,
                           color: Color(0xFF2D3748),),
                            ),
                            Checkbox(
                              checkColor: Colors.black,
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                if (states.contains(MaterialState.disabled)) {
                                  return Colors.black.withOpacity(.32);
                                }
                                return Colors.white;
                              }),
                              value: checkAll,
                              onChanged: (value) {
                                setState(() {
                                  checkAll = value!;
                                  if (checkAll == true) {
                                    for (int i = 0;
                                        i < widget.opp.length;
                                        i++) {
                                        selected.add(widget.opp[i]);
                                    }
                                  } else {
                                    for (int i = 0;
                                        i < widget.opp.length;
                                        i++) {
                                        selected.remove(widget.opp[i]);
                                    }
                                  }
                                });
                              },
                            )
                          ]),
                    ),
                    Divider(
                      height: 1,
                      color: Color.fromARGB(255, 19, 19, 19),
                    ), 
                    Flexible(
                        child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: widget.opp.length,
                            itemBuilder: (context, index) {
                              bool isSelect = selected.contains( widget.opp[index]);
                              return Material(
                            
                                child: ListTile(
                                  title: Text(
                                    widget.opp[index]['name'],
                                    style: TextStyle(color: Color(0xFF2D3748),
                                           fontFamily: 'SF',),
                                  ),
                                  trailing: Checkbox(
                                    checkColor: Colors.black,
                                    activeColor: Colors.black,
                                    fillColor:
                                        MaterialStateProperty.resolveWith<
                                            Color>((Set<MaterialState> states) {
                                      if (states
                                          .contains(MaterialState.disabled)) {
                                        return Colors.black.withOpacity(.32);
                                      }
                                      return Colors.white;
                                    }),
                                    value:isSelect,
                                    onChanged: (value) {
                                      setState(() {
                                      !isSelect;
                                      selected.add( widget.opp[index]);
                                      });
                                    },
                                  ),
                                ),
                              );
                            })),
                            TextField(
                                              onSubmitted: (value) async {
                                
       

   
                                                 //await sendMessage2();
                                             
                                                                 
                                              },
                                              
                                              maxLines: null,
                                              expands: true,
                                              cursorColor: Colors.black,
                                              
                                              style:
                                                  const TextStyle( color: Color(0xFF2D3748),
                                                  fontSize: 15,
                                                   fontFamily: 'SF'),
                                              controller: _messageController,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                  
                                              ),
                                            ),
                                GestureDetector(
              onTap: () {
                print(selected);
                   sendAllAtOnce(selected);
              },
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
                      "Send",
                      style: TextStyle(color: Colors.white,
                                         fontFamily: 'SF', fontSize: 15),
                    ),
                  ),
                ),
              ),
            )
                  ],
                )),
          ],
        ),
      ),
    );
  }
  Future<void> sendMessage2(String to) async {

  try {

    String messageText = _messageController.text;
    Map<String, dynamic> tags = {}; // Replace with your tags
       setState(() {
                                _messageController.clear();
                       
                              });
                         
  } catch (e) {
    // Handle error
    print('Error in sendMessage: $e');
  }
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
                      
                           Navigator.of(context)
                              .push(CupertinoPageRoute(builder: (context) {
                            return BlastSettingPage(autowebhook: widget.auto!['webhook'],selected:selected);
                          }));
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
        String webhookUrl = widget.auto!['webhook'];

        // Send data to webhook for this contact
        sendToWebhook(webhookUrl, contactId);
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
