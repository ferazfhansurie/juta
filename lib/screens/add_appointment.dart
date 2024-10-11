// ignore_for_file: must_be_immutable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:juta_app/utils/toast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddAppointment extends StatefulWidget {
dynamic opp;
String calendarId;
String token;
String userId;
  AddAppointment({super.key,this.opp ,required this.calendarId,required this.token,required this.userId });

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
List<String> status = ['Confimed','Pending'];
String statusName = "Confirmed";
String date = "";
int dateEpock = 0;
String time = "Select Time";
String slot ="";
 final GlobalKey progressDialogKey = GlobalKey<State>();
Future<void> bookAppointment(String calendarId, String timezone, String slot, String phone, String token) async {
  final response = await http.post(
    Uri.parse('https://rest.gohighlevel.com/v1/appointments/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'calendarId': calendarId,
      'selectedTimezone': timezone,
      'selectedSlot': slot,

      'phone': phone,
      'calendarNotes':nameController.text
    }),
  );
print(response.body);
  if (response.statusCode == 200) {
  Navigator.pop(context);
  } else {
    throw Exception('Failed to book appointment');
  }
}

Future<Map<String, List<String>>> fetchAvailableSlots(String calendarId, int startDate, int endDate, String timezone, String userId, String token) async {
  final response = await http.get(
    Uri.parse('https://rest.gohighlevel.com/v1/appointments/slots?calendarId=$calendarId&startDate=$startDate&endDate=$endDate&timezone=$timezone&userId=$userId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    Map<String, List<String>> slotsPerDate = {};
    
    // Iterate over each date key and extract the slots
    data.forEach((date, dateData) {
      slotsPerDate[date] = List<String>.from(dateData["slots"]);
    });

    return slotsPerDate;
  } else {
    throw Exception('Failed to load slots');
  }
}
@override
  void initState() {
    // TODO: implement initState

    phoneNumberController.text = widget.opp['contact']['phone'];
  
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20),
          child: GestureDetector(
            onTap: () {
             FocusScope.of(context).unfocus();
            },
            child: ListView(
              shrinkWrap: true,
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
                        
                        bookAppointment(widget.calendarId,"Asia/Kuala_Lumpur",slot,widget.opp['contact']['phone'],widget.token );
                       
                      },
                      child: const Text(
                        'Add',
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
                SizedBox(height: 20,),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                       
                        child: Row(
                          children: [
                            Container(
                                                 height: 50,
                                          width:50
                                          ,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF2D3748),
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: Center(child: Text(  widget.opp['name'].isNotEmpty ?   widget.opp['name'].substring(0, 1).toUpperCase() : '',style: TextStyle(color: Colors.white,fontSize: 14),)),
                                              ),
                                              SizedBox(width: 20,),
                                                 Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     Text(
                                                      widget.opp['name'],
                                                      style: TextStyle(color: Color(0xFF2D3748),
                                                             fontFamily: 'SF',fontWeight: FontWeight.bold),),
                                                             Text(
                                                  widget.opp['contact']['phone'],
                                                  style: TextStyle(color: Color(0xFF2D3748),
                                                         fontFamily: 'SF',fontWeight: FontWeight.w300),),
                                                            Text(
                                                  widget.opp['contact']['email'] ?? "",
                                                  style: TextStyle(color: Color(0xFF2D3748),
                                                         fontFamily: 'SF',fontWeight: FontWeight.w300),),  
                                                   ],
                                                 ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
 
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: (){
                        DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2024, 1, 1),
      onChanged: (date2) {
        print('change $date');
        setState(() {
          date = formatDate(date2);;
        });
      }, 
    
      onConfirm: (date2) {
        print('confirm $date');
        
        setState(() {
          date = formatDate(date2);;
          dateEpock= date2.millisecondsSinceEpoch;
        });
      },
      currentTime: DateTime.now(),
      locale: LocaleType.en,
    );
                    },
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,color: Color(0xFF2D3748),size: 25,), 
                            SizedBox(width: 20,),
                            Text(
                                                 (date != "")? date:"Select Date",
                                                  style: TextStyle(color: Color(0xFF2D3748),
                                                         fontFamily: 'SF',fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                    GestureDetector(
                      onTap: () async {
                       ProgressDialog.show(context, progressDialogKey);
                     Map<String,dynamic>slots =    await fetchAvailableSlots(widget.calendarId,dateEpock,dateEpock,"Asia/Kuala_Lumpur",widget.userId,widget.token);
                   print(formatEpoch(dateEpock));
                   ProgressDialog.unshow(context, progressDialogKey);
String date = formatEpoch(dateEpock);
                         _showSlots(slots[date] );
                      },
                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.punch_clock,color: Color(0xFF2D3748),size: 25,), 
                            SizedBox(width: 20,),
                            Text(
                                                 time,
                                                  style: TextStyle(color: Color(0xFF2D3748),
                                                         fontFamily: 'SF',fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                                        ),
                                      ),
                    ),
                   Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Card(
                                     child:    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Icon(Icons.notes,color: Color(0xFF2D3748),size: 25,), 
                            SizedBox(width: 20,),
                          Container(
                            width: 270,
                            height: 200,
                            child: TextField(
                              keyboardType: TextInputType.multiline,
                                    controller: nameController,
                                    expands: true,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      hintText: 'Notes (Optional)',
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
      ),
    );
  }
  String formatEpoch(int epoch) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(epoch);
  String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
  return formattedDate;
}
String formatDate(DateTime dateTime) {
  return DateFormat('EEE, MMM d, yyyy').format(dateTime);
}
    _showStatus() {
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Spacer(),
                  SizedBox(
                    width: 45,
                  ),
                
                  Spacer(),
                  CupertinoButton(
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Color.fromARGB(255, 109, 109, 109)),
                        child: Icon(Icons.close)),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // closing showCupertinoModalPopup
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                  ),
                ],
              ),
            ),
          
            SizedBox(
                height: 180,
                width: double.infinity,
                child: Container(
                  color: Colors.white,
                  child:      ListView.builder(
                        shrinkWrap: true,
              itemCount: status.length,
              itemBuilder: (context,index){
              return   GestureDetector(
                        onTap: () {
                     setState(() {
                       statusName = status[index];

                     });
                     Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Color(0xFF2D3748)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      (index == 0)?CupertinoIcons.check_mark:Icons.pending_actions,
                                      color: Colors.white,
                                    ),
                                  )),
                              SizedBox(
                                width: 10,
                              ),
                              Text(status[index],
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'SF',
                                      color: Color(0xFF020913))),
                            ],
                          ),
                        ),
                      );
            },)
                )),
          ],
        );
      },
    );
  }
    _showSlots(List<String> date) {
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
                mainAxisAlignment: MainAxisAlignment.end,

                children: [
                  Spacer(),
                  SizedBox(
                    width: 45,
                  ),
                
                  Spacer(),
                  CupertinoButton(
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: Color.fromARGB(255, 109, 109, 109)),
                        child: Icon(Icons.close)),
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // closing showCupertinoModalPopup
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 5.0,
                    ),
                  ),
                ],
              ),
            ),
          
            SizedBox(
                height: 500,
                width: double.infinity,
                child: Container(
                  color: Colors.white,
                  child:      ListView.builder(
                        shrinkWrap: true,
              itemCount: date.length,
              itemBuilder: (context,index){
                String time2 = extractTime(date[index]);
              return   Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: GestureDetector(
                            onTap: () {
                         setState(() {
                         time = time2;
                  slot = date[index];
                         });
                         Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment:MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(100),
                                          color: Color(0xFF2D3748)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                        Icons.punch_clock,
                                          color: Colors.white,
                                        ),
                                      )),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(time2,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'SF',
                                          color: Color(0xFF020913))),
                                ],
                              ),
                            ),
                          ),
                ),
              );
            },)
                )),
          ],
        );
      },
    );
  }
String extractTime(String iso8601String) {
  // Parse the date-time string into a DateTime object
  DateTime dateTime = DateTime.parse(iso8601String);
  // Format the DateTime object to a time string with AM/PM
  String formattedTime = DateFormat('h:mm a').format(dateTime); // 'a' stands for AM/PM marker
  return formattedTime;
}
}
