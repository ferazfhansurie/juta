import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:juta_app/screens/add_appointment.dart';
import 'package:juta_app/screens/appointment_detail.dart';
import 'package:juta_app/screens/lead_appointment.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

class Appointment extends StatefulWidget {
  const Appointment({super.key});

  @override
  State<Appointment> createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment> {
  List<dynamic> appointments = [];

  String botId = '';
  String accessToken = '';
  String workspaceId = '';
  String integrationId = '';
  User? user = FirebaseAuth.instance.currentUser;
  String email = '';
  String firstName = '';
  String company = '';
  String companyId = '';
  String calendarId = '';
  String pipelineId = '';
  String apiKey = ''; // Replace with your actual token
    List<dynamic> opp = [];
    String ghlToken = '';
    String? contactId ;
       final GlobalKey progressDialogKey = GlobalKey<State>();
    List<dynamic> pipelines = [];
    DateTime  _selectedDay  = DateTime.now();

 final ScrollController _scrollController = ScrollController();

  final String baseUrl = "https://api.botpress.cloud";
  Future<void> fetchConfigurations() async {
    email = user!.email!;
    await FirebaseFirestore.instance
        .collection("user")
        .doc(email)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          firstName = snapshot.get("name");
          company = snapshot.get("company");
          companyId = snapshot.get("companyId");
        });

      } else {
        print("Snapshot not found");
      }
    }).then((value) {
      FirebaseFirestore.instance
          .collection("companies")
          .doc(companyId)
          .get()
          .then((snapshot) async {
        if (snapshot.exists) {
          setState(() {
            accessToken = snapshot.get("accessToken");
  
            botId = snapshot.get("botId");
            integrationId = snapshot.get("integrationId");
            workspaceId = snapshot.get("workspaceId");
            calendarId = snapshot.get("calendarId");
            pipelineId = snapshot.get("pipelineId");
            apiKey = snapshot.get("apiKey");
            ghlToken =snapshot.get("ghlToken");
          });
             await fetchAppointments();
        } else {
          print("Snapshot not found");
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    fetchConfigurations();

  }

  Future<void> fetchAppointments() async {

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: 30));
    DateTime endOfWeek = now.add(Duration(days: 6));

    int startDate = startOfWeek.toUtc().millisecondsSinceEpoch;
    int endDate = endOfWeek.toUtc().millisecondsSinceEpoch;
    try {
      List<dynamic> fetchedAppointments =
          await getAppointments(calendarId, startDate, endDate);
      setState(() {
        appointments = fetchedAppointments;
      });
   contactId = await getContactIdByEmail("faeezree@gmail.com",ghlToken);

    } catch (error) {
      print(error);
    }
  }
Future<String?> getContactIdByEmail(String email, String ghlToken) async {
  String apiUrl = 'https://rest.gohighlevel.com/v1/users/location';
  Map<String, String> headers = {
    'Authorization': 'Bearer $apiKey',
  };
  final response = await http.get(
    Uri.parse(apiUrl),
    headers: headers,
  );
  print("Response Body: " + response.body);
  if (response.statusCode == 200) {
    Map<String, dynamic> responseBody = json.decode(response.body);
    List<dynamic> users = responseBody['users'];

    // Find the user by email and return the contact ID
    final user = users.firstWhere(
      (u) => u['email'].toLowerCase() == email.toLowerCase(),
      orElse: () => null,
    );

    return user != null ? user['id'] : null;
  } else {
    throw Exception('Failed to load user data');
  }
}
  Future<List<dynamic>> getAppointments(
      String calendarId, int startDate, int endDate) async {
    String apiUrl = 'https://rest.gohighlevel.com/v1/appointments/';
    Map<String, String> headers = {
      'Authorization': 'Bearer $apiKey',
    };
    String urlWithParams = apiUrl +
        '?calendarId=$calendarId&startDate=$startDate&endDate=$endDate&includeAll=true';
    try {
      final response = await http.get(
        Uri.parse(urlWithParams),
        headers: headers,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        List<dynamic> appointments = responseBody['appointments'];
        return appointments;
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (error) {
      print(error);
      throw Exception('Failed to load appointments');
    }
  }
  Future<void> callAutomation() async {
       contactId = await getContactIdByEmail(user!.email!,ghlToken);
     print(contactId);
 ProgressDialog.show(context, progressDialogKey);
   await fetchOpportunitiesFromFirstPipeline();
  
     print("Contacts loaded successfully: $opp");
       Navigator.of(context)
                              .push(CupertinoPageRoute(builder: (context) {
                            return LeadAppointmentScreen(opp: opp,calendarId: calendarId,token: ghlToken,userId: contactId!,);
                          }));
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
Future<void> _refreshAppointments() async {
  // Fetch new appointments and update the state

   appointments.clear();
  await fetchAppointments();
  // You can also handle exceptions and errors here
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: (){
callAutomation();
                    
          },
          child: Card(
          color: Color(0xFF2D3748),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.add,color: Colors.white,size: 30,),
            )),
        ),
      ),
      body: Container(
          height: MediaQuery.sizeOf(context).height,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 10, right: 10),
      color: Colors.white,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         
                          SizedBox(
                            height: 10,
                          ),
                          Text('Appointments',
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  fontSize:22,
                                  fontWeight: FontWeight.bold,
                                             fontFamily: 'SF',
                                                  color: Color(0xFF2D3748),)),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            child: TableCalendar(
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, date, _) {
                                  // Check if date has appointments
                                  bool hasAppointments =
                                      appointments.any((appointment) {
                                    var startTime =
                                        DateTime.parse(appointment['startTime']);
                                    var formattedDate = DateFormat('yyyy-MM-dd')
                                        .format(startTime);
                                    return formattedDate ==
                                        DateFormat('yyyy-MM-dd').format(date);
                                  });
                                
                             DateTime now = DateTime.now();
    bool isToday = (date.year == now.year && date.month == now.month && date.day == now.day);
                                  return Container(
                                    margin: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color:(isToday )?Colors.redAccent:(_selectedDay == date)
                                          ?  Color(0xFF2D3748)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${date.day}',
                                            style: TextStyle(color:(isToday)?Colors.white:(_selectedDay == date)
                                              ?  Colors.white
                                              : Color(0xFF2D3748),
                                              fontSize: 18,
                                                 fontFamily: 'SF',),
                                          ),
                                         
                                          if(hasAppointments)

                                          Container(
                                            height: 5,
                                            width: 5,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(100),
                                            color:Color(0xFF2D3748) ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
      
                                // Add other properties as needed
                              ),
                              rowHeight: 40,
                              firstDay: DateTime.utc(2010, 10, 16),
                              lastDay: DateTime.utc(2030, 3, 14),
                              focusedDay:_selectedDay,
                              
                               onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                        });
                        // Scroll to the selected date in the ListView
                        _scrollToList(selectedDay);
                      },
               
                              calendarStyle: CalendarStyle(
                               todayDecoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                isTodayHighlighted: true,
                                defaultTextStyle: TextStyle(color: Color(0xFF2D3748)),
                                weekendTextStyle: TextStyle(color: Color(0xFF2D3748)),
                                holidayTextStyle: TextStyle(color: Color(0xFF2D3748)),
                                outsideDaysVisible: false,
                                todayTextStyle: TextStyle(color: Colors.white,fontSize: 30),
                               
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle:
                                    TextStyle(color: Color(0xFF2D3748), fontSize: 18),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  color: Color(0xFF2D3748),
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            color: Color(0xFF2D3748),
                          ),
                          Container(
                            height: MediaQuery.sizeOf(context).height * 32/ 100,
                            child: RefreshIndicator(
                      onRefresh: _refreshAppointments,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  (appointments.isEmpty)
                                      ? Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                color: const Color.fromARGB(
                                                    255, 109, 109, 109)),
                                            SizedBox(
                                              width: 15,
                                            ),
                                            Text(
                                              'No appointments scheduled',
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                  fontSize: 15,
                                               fontFamily: 'SF',
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color.fromARGB(
                                                      255, 109, 109, 109)),
                                            ),
                                          ],
                                        )
                                      : Flexible(
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: appointments.length,
                                            itemBuilder: (context, index) {
                                              var appointment = appointments[index];
                                              var endTime = DateTime.parse(
                                                  appointment['endTime']).add(Duration(hours: 8));
                                              var startTime = DateTime.parse(
                                                  appointment['startTime']).add(Duration(hours: 8));
                                              var formattedStartTime =
                                                  DateFormat('EEE dd/MM')
                                                      .format(startTime);
                                              var temp =
                                                  formattedStartTime.split(' ');
                                              var formattedStartTime2 =
                                                  DateFormat('hh:mma')
                                                      .format(startTime);
                                              var formattedEndTime2 =
                                                  DateFormat('hh:mma')
                                                      .format(endTime);
                                              return GestureDetector(
                                                onTap: (){
                                                  print("HAHAHAHAHAHA"+appointments[index].toString());
                                                    Navigator.of(context)
                                .push(CupertinoPageRoute(builder: (context) {
                              return AppointmentDetail(
                                opp:appointments[index],
                                userId: contactId!,
                                calendarId: calendarId,
                                token:ghlToken,
                                appointmentId: appointments[index]['id'],
                                startTime:startTime,
                              );
                            }));
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Column(
                                                            children: [
                                                              Text(temp[0],
                                                                  style: TextStyle(
                                                                      color: Color(0xFF2D3748),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                 fontFamily: 'SF',
                                                                      fontSize: 15)),
                                                              Text(temp[1],
                                                                  style: TextStyle(
                                                                    color:
                                                                        Color(0xFF2D3748),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                 fontFamily: 'SF',
                                                                  )),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              width:
                                                                  10), // Add some spacing between date and title
                                                          Card(
                                                        
                                                             
                                                              child: Container(
                                                                      width: 240,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(8),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                          appointment[
                                                                              'title'],
                                                                          style: TextStyle(
                                                                              color: Color(0xFF2D3748),
                                                                              fontWeight: FontWeight.bold,
                                                                                                             fontFamily: 'SF',),),
                                                                      Row(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .center,
                                                                        children: [
                                                                          Container(
                                                                            height: 5,
                                                                            width: 5,
                                                                            decoration: BoxDecoration(
                                                                                color: Color(0xFF2D3748),
                                                                                borderRadius:
                                                                                    BorderRadius.circular(100)),
                                                                          ),
                                                                          SizedBox(
                                                                            width: 2,
                                                                          ),
                                                                          Text(
                                                                            '$formattedStartTime2 - $formattedEndTime2',
                                                                            style: TextStyle(
                                                                                color: Color(0xFF2D3748),
                                                                                                             fontFamily: 'SF',
                                                                                fontSize:
                                                                                    11),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              )),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ]))
              ])),
    );
  }
    Future<void> _scrollToList(DateTime selectedDate) async {
    // Filter appointments based on the selected date
    List<dynamic> filteredAppointments = appointments.where((appointment) {
      var startTime = DateTime.parse(appointment['startTime']).toLocal();
      return startTime.year == selectedDate.year &&
          startTime.month == selectedDate.month &&
          startTime.day == selectedDate.day;
    }).toList();

    // Scroll the ListView to the filtered appointments
    if (filteredAppointments.isNotEmpty) {
      int index = appointments.indexOf(filteredAppointments.first);
      await _scrollController.animateTo(index * 70,
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }
}
