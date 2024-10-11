

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:juta_app/screens/conversations.dart';
import 'package:juta_app/screens/drip.dart';
import 'package:juta_app/screens/message.dart';
import 'package:juta_app/utils/toast.dart';

// ignore: must_be_immutable
class ForwardScreen extends StatefulWidget {
  List<dynamic> opp;
  int? from ;
  String? message;
  String whapi;
  ForwardScreen({super.key, required this.opp,this.from,required this.message, required this.whapi});

  @override
  State<ForwardScreen> createState() => _ForwardScreenState();
}

class _ForwardScreenState extends State<ForwardScreen> {
  TextEditingController searchController = TextEditingController();
  bool checkAll = false;
    List<dynamic> selected = [];
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
                      SizedBox(
              height: 25,
            ),
      
                           Container(
         alignment:Alignment.centerRight ,
        width: MediaQuery.of(context).size.width * 70 / 100,
        child: Align(
          alignment:Alignment.centerRight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D85FF),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  widget.message!,
                  style: const TextStyle(fontSize: 17.0, color: Colors.white,
                                             fontFamily: 'SF',),
                ),
              ),
              
         
                SizedBox(height: 10,),
            ],
          ),
        ),
      ),
            SizedBox(
              height: 25,
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
                                          setState(() {
                                               selected.remove(widget.opp[i]);
                                          });
                                     
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
                              print(widget.opp[index]);
                              return Material(
                            
                                child: ListTile(
                                  title: Text(
                                    widget.opp[index]['contact']['name'] != null?widget.opp[index]['contact']['name'] :widget.opp[index]['contact']['phone'],
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
                                      if(isSelect == false) {
                                        setState(() {
                                      !isSelect;
                                      selected.add( widget.opp[index]);
                                      });
                                      }else{
                                          setState(() {
                                      isSelect;
                                      selected.remove( widget.opp[index]);
                                      });
                                      }
                                    },
                                  ),
                                ),
                              );
                            })),
                              SizedBox(
              height: 25,
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
                      "Forward",
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

  Future<void> sendAllAtOnce(List<dynamic> selectedContacts) async {
    for (var contact in selectedContacts) {
      if (selected.contains(contact)) {
        String contactId = contact['contact']['phone'];
        var id = contactId.split('+')[1]+'@s.whatsapp.net';
        print(id);
        // Construct the webhook URL
    await sendMessage2(id);
   Navigator.pop(context);
   Navigator.pop(context);
         Toast.show(context,"success","Forwarded");

      }
    
    }

 
  }
  Future<void> fetchChats(String phone ) async {
   List<dynamic> allConversations = [];
 

    const String apiUrl = 'https://gate.whapi.cloud/chats';
     String apiToken = widget.whapi; // Replace with your actual WHAPI Token

    final queryParameters = {
      'count': '100', // Adjust based on how many chats you want to fetch
      // 'offset': '0', // Uncomment and adjust if you need pagination
    };

    final uri = Uri.parse(apiUrl).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': apiToken,
          'Content-Type': 'application/json',
        },
      );
print(response.body);
      if (response.statusCode == 200) {
       final data = json.decode(response.body);
      // Assuming the chats are in a field named 'chats'. Adjust this according to the actual response structure.
      final List<dynamic> chatsList = data['chats'] ?? []; // Use the correct key based on the API response
      setState(() {
        allConversations = chatsList;
       
      });
      bool found = false;
      String id = "";
      dynamic convo;
      for(int i = 0 ; i< allConversations.length;i++){
        print(allConversations[i]);
        String chatId = allConversations[i]['id'];
                // Use regular expression to extract only digits
                RegExp numRegex = RegExp(r'\d+');
                String numberOnly = numRegex.firstMatch(chatId)?.group(0) ?? '';
        if(numberOnly == phone){
          found = true;
         id = allConversations[i]['id'];
convo= allConversations[i];
 if(i ==0){
                
      String chatId = phone.split('+')[1]+"@s.whatsapp.net";
      print("convoooo"+convo);
   
       }
        }
      
      }
  
      } else {
        print('Failed to fetch chats: ${response.statusCode}');
        setState(() {
 
        });
      }

    } catch (e) {
      print('Error fetching chats: $e');
      setState(() {

      });
   
    }
  }
    Future<void> fetchMessagesForChat(String chatId,dynamic chat) async {
  try {
    String url = 'https://gate.whapi.cloud/messages/list/$chatId';
    // Optionally, include query parameters like count, offset, etc.

    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.whapi}', // Replace with your actual Whapi access token
      },
    );
print(response.body);
 if (response.statusCode == 200) {
  var data = json.decode(response.body);
  
  // Ensure messages is treated as a List<Map<String, dynamic>>.
  // We use .cast<Map<String, dynamic>>() to ensure the correct type.
  List<Map<String, dynamic>> messages = (data['messages'] is List)
      ? data['messages'].cast<Map<String, dynamic>>()
      : [];
print(messages);
  // Now 'messages' is guaranteed to be a List<Map<String, dynamic>>,
  // which you can safely pass to another widget.
       Navigator.pop(context);
    Navigator.pop(context);

} else {
      print('Failed to fetch messages: ${response.body}');
   
    }
  } catch (e) {
    print('Error fetching messages for chat: $e');
  
  }
}
  Future<void> sendMessage2(String to) async {

  try {

    String messageText = widget.message!;
    Map<String, dynamic> tags = {}; // Replace with your tags
       setState(() {
  
                              });
await sendTextMessage(to,messageText);


  } catch (e) {
    // Handle error
    print('Error in sendMessage: $e');
  }
}
  Future<void> sendTextMessage(String to, String messageText) async {
  try {
    String url = 'https://gate.whapi.cloud/messages/text';
    var body = json.encode({
      'to': to, // Phone number or Chat ID
      'body': messageText, // Message text
      // Include other parameters as needed
    });

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Authorization': 'Bearer ${widget.whapi}', // Replace with your actual Whapi access token
      },
      body: body,
    );
print(response.body);
    if (response.statusCode == 201) {
      print('Message sent successfully');
    } else {
      print('Failed to send message: ${response.body}');
    }
  } catch (e) {
    print('Error sending text message: $e');
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
