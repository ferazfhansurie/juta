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

class AppointmentDetail extends StatefulWidget {
dynamic opp;
String calendarId;
String appointmentId;
String token;
String userId;
DateTime startTime;
  AppointmentDetail({super.key,this.opp,required this.startTime,required this.calendarId,required this.appointmentId,required this.token,required this.userId });

  @override
  State<AppointmentDetail> createState() => _AppointmentDetailState();
}

class _AppointmentDetailState extends State<AppointmentDetail> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
List<String> status = ['Confimed','Pending'];
String statusName = "Confirmed";
String date = "";
int dateEpock = 0;
String time = "Select Time";
String slot ="";
 final GlobalKey progressDialogKey = GlobalKey<State>();
Future<void> updateAppointment(String appointmentId, String timezone, String slot, String phone, String token) async {
  final response = await http.put(
    Uri.parse('https://rest.gohighlevel.com/v1/appointments/$appointmentId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'selectedTimezone': timezone,
      'selectedSlot': slot,
      'phone': phone, // Assuming you still need to update the phone number
      // Add any other fields that you need to update
    }),
  );

  print(response.body);

  if (response.statusCode == 200) {
    Navigator.pop(context);
  } else {
    throw Exception('Failed to update appointment');
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
void formatAndSplitDateTime(String startTime) {
  // Parse the startTime string into a DateTime object
  DateTime dateTime = DateTime.parse(startTime).toLocal();

  // Format the DateTime object to a date string (e.g., '2024-01-31')
  String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

  // Format the DateTime object to a time string with AM/PM (e.g., '10:00 AM')
  String formattedTime = DateFormat('h:mm a').format(dateTime);

  // Assign to your date and time strings
  date = formattedDate;
  time = formattedTime;
}
@override
  void initState() {
    // TODO: implement initState

    phoneNumberController.text = widget.opp['contact']['phone'];
nameController.text= widget.opp['notes'];
formatAndSplitDateTime(widget.opp['startTime']);
dateEpock = DateTime.now().millisecondsSinceEpoch;

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
                      updateAppointment(widget.appointmentId,"Asia/Kuala_Lumpur",slot,widget.opp['contact']['phone'],widget.token );
                       
                      },
                      child: const Text(
                        'Save',
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
                                                child: Center(child: Text(  widget.opp['title'].isNotEmpty ?   widget.opp['title'].substring(0, 1).toUpperCase() : '',style: TextStyle(color: Colors.white,fontSize: 14),)),
                                              ),
                                              SizedBox(width: 20,),
                                                 Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     Text(
                                                      widget.opp['title'],
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
          date = formatDate(date2);
        });
      }, 
    
      onConfirm: (date2) {
        print('confirm $date');
        
        setState(() {
          date = formatDate(date2);
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
                                                date,
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
    
                   // Parse the ISO string
      

          // Format the time
         String formattedTime = formatIsoString(date[index]);
   
              return   Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: GestureDetector(
                            onTap: () {
                         setState(() {
                         time = formattedTime;
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
                                  Text(formattedTime,
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
String formatIsoString(String isoString) {
  // Parse the ISO string without converting it to local time
  DateTime utcTime = DateTime.parse(isoString).toUtc();

  // Since the time is in +08:00 time zone, add 8 hours to the UTC time
  DateTime correctedTime = utcTime.add(Duration(hours: 8));

  // Format the time
  return DateFormat('h:mm a').format(correctedTime);
}


}
