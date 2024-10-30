// ignore_for_file: must_be_immutable, unnecessary_null_comparison, use_build_context_synchronously, library_private_types_in_public_api

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juta_app/models/conversations.dart';
import 'package:juta_app/screens/message.dart';
import 'package:juta_app/screens/notification.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:juta_app/utils/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Conversations extends StatefulWidget {
  const Conversations({super.key});

  @override
  _ConversationsState createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  int currentIndex = 0;
    int conversationCount = 0;
  TextEditingController searchController = TextEditingController();
  String filter = "";
  List<Map<String,dynamic>> conversations = [];
  final GlobalKey progressDialogKey = GlobalKey<State>();
  TextEditingController messageController = TextEditingController();
  String stageId ="";
  List<Map<String, dynamic>> users = [];
  String botId = '';
  String accessToken = '';
  String ghlToken = '';
  String nextTokenConversation = '';
  String prevTokenConversation = '';
  String nextTokenUser = '';
    String prevTokenUser = '';
  String workspaceId = '';
  String integrationId = '';
  User? user = FirebaseAuth.instance.currentUser;
  String email = '';
  String firstName = '';
  String company = '';
  String companyId = '';
  final String baseUrl = "https://api.botpress.cloud";
  ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<dynamic> allUsers = [];
    List<dynamic> opportunities = [];
  List<dynamic> pipelines = [];
   int currentPage = 1;
  int totalPages = 10;
   String nextToken = '';
    String prevToken = '';
         String  messageToken ="";
  String? nextPageUrl;
  String? prevPageUrl;
  int fetchedOpportunities = 0;
  String whapiToken = "Botpress";
  String ghl ='';
  String ghl_location = '';
  String refresh_token ='';
  String role ="1";
  List<dynamic> availableTags = [];
List<dynamic> selectedTags = ['All'];
bool _isLoadingMore = false;
bool v2 = false;
bool isDarkMode = false; // Add this line to track dark mode state
Future<void> saveDarkModePreference(bool isDarkMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDarkMode);
}
Future<bool> loadDarkModePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDarkMode') ?? false; // Default to false if not set
}
Future<List> getLocationTags() async {
  try {
    // Predefined tags
    List<String> predefinedTags = [
      'Mine',
      'All',
      'Unassigned',
      'Group',
      'Unread',
      'Snooze',
      'Stop Bot'
    ];

    // Reference to the tags subcollection in Firestore
    CollectionReference tagsRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('tags');

    // Get the documents in the tags subcollection
    QuerySnapshot tagsSnapshot = await tagsRef.get();

    // Clear existing tags
    availableTags.clear();

    // Add predefined tags first
    availableTags.addAll(predefinedTags);

    // Add tags from Firebase
    if (tagsSnapshot.docs.isNotEmpty) {
      for (var doc in tagsSnapshot.docs) {
        String tagName = doc.get('name'); // Assuming each tag document has a 'name' field
        if (!availableTags.contains(tagName)) {
          availableTags.add(tagName);
        }
      }
    }

    return availableTags;
  } catch (e) {
    print('Error loading tags from Firebase: $e');
    return [];
  }
}
Future<void> toggleTagSelection(String tag) async {
  setState(()  {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
       
    } else {
      selectedTags.clear();
      selectedTags.add(tag);
    }
  });
     await fetchContacts();
}


  Future<void> listenNotification() async {
     FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
     await fetchContactsBackground();
      });
     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      });
}
Future<void> fetchConfigurations(bool refresh) async {
  email = user!.email!;
  await FirebaseFirestore.instance
      .collection("user")
      .doc(email)
      .get()
      .then((snapshot) {
    if (snapshot.exists) {
      setState(() {
        firstName = snapshot.get("name") ?? "Default Name";
        company = snapshot.get("company") ?? "Default Company";
        companyId = snapshot.get("companyId") ?? "Default CompanyId";
        role = snapshot.get("role") ?? "Default CompanyId";
        print('User details - Name: $firstName, Company: $company, Company ID: $companyId');
      });
       FirebaseMessaging.instance.subscribeToTopic(companyId);
    } else {
      print('User snapshot not found for email: $email');
    }
  }).then((value) {
    if (companyId != null && companyId.isNotEmpty) {
      print('Fetching company details for companyId: $companyId');
      FirebaseFirestore.instance
          .collection("companies")
          .doc(companyId)
          .get()
          .then((snapshot) async {
        if (snapshot.exists) {
          print('Company snapshot found for companyId: $companyId');
             if (mounted) {
               setState(() {
                 var automationData = snapshot.data() as Map<String, dynamic>;
                   if(automationData.containsKey('v2')) {
                    v2 = snapshot.get("v2");
                  }
                  if (automationData.containsKey('ghl_accessToken')){
      ghl = snapshot.get("ghl_accessToken");
                }    if (automationData.containsKey('ghl_refreshToken')){
      refresh_token = snapshot.get("ghl_refreshToken");
                }
                  if (automationData.containsKey('ghl_location')){
      ghl_location = snapshot.get("ghl_location");
                }
               if(automationData.containsKey('whapiToken')) {
                 whapiToken= snapshot.get("whapiToken");
               }
               print("whapi"+v2.toString());
           
          });
                  await getLocationTags();
                  await fetchEmployeeNames();
                    await fetchContacts();
             }
;
        } else {
          print('Company snapshot not found for companyId: $companyId');
        }
      });
    } else {
      print('companyId is null or empty');
    }
  });
  print('Configuration fetching complete.');
}
Map<String, dynamic> getLatestMessageDetails(Map<String, dynamic> conversation) {
  String latestMessage = 'No message';
  DateTime latestTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  if (conversation['last_message'] != null) {
    var lastMessage = conversation['last_message'];
    if (lastMessage['type'] == 'text') {
      latestMessage = lastMessage['text']?['body'] ?? 'No message';
    } else if (lastMessage['type'] != 'text') {
      latestMessage = 'Photo';
    } else {
      latestMessage = 'Unsupported message type';
    }
    int timestamp = lastMessage['timestamp'] ?? 0;
    latestTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  return {
    'latestMessageTimestamp': latestTimestamp,
    'latestMessage': latestMessage,
  };
}

Future<void> fetchContacts() async {
  print('Fetching contacts...');
  try {
    setState(() {
      _isLoading = true;
    });

    // Fetch contacts from Firestore
      final companyDocRef = FirebaseFirestore.instance.collection("companies").doc(companyId);
    final contactsSnapshot = await companyDocRef.collection("contacts")
        .orderBy('last_message.timestamp', descending: true)
        .limit(20 * currentPage)
        .get();
      var contacts = contactsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch pinned contacts and unread counts from Firestore
    final userDocRef = FirebaseFirestore.instance.collection("user").doc(email);
    final pinnedContactsSnapshot = await userDocRef.collection("pinned").get();
    final pinnedContacts = pinnedContactsSnapshot.docs.map((doc) => doc.data()['chat_id']).toList();
    print("pinned");

    // Merge pinned contacts and unread counts with contact data
    final List<Map<String, dynamic>> mergedContacts = List<Map<String, dynamic>>.from(contacts).map((contact) {
      final chatId = contact['chat_id'];
      final isPinned = pinnedContacts.contains(chatId);
     final unreadCount = contact['unreadCount'] ?? 0; // Use existing unreadCount or default to 0

      return {
        ...contact,
        'pinned': isPinned,
        'unreadCount': unreadCount,
      };
    }).toList();

    setState(() {
      conversations = mergedContacts;
      _isLoading = false;
    });
    print(contacts);
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    print('Error fetching contacts: $error');
  }
}
Future<void> fetchMoreContacts() async {
  print('Fetching contacts...');
  try {
  Toast.show(context, 'success', 'Fetching more data');

    // Fetch contacts from Firestore
      final companyDocRef = FirebaseFirestore.instance.collection("companies").doc(companyId);
    final contactsSnapshot = await companyDocRef.collection("contacts")
        .orderBy('last_message.timestamp', descending: true)
        .limit(20 * currentPage)
        .get();
      var contacts = contactsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch pinned contacts and unread counts from Firestore
    final userDocRef = FirebaseFirestore.instance.collection("user").doc(email);
    final pinnedContactsSnapshot = await userDocRef.collection("pinned").get();
    final pinnedContacts = pinnedContactsSnapshot.docs.map((doc) => doc.data()['chat_id']).toList();
    print("pinned");


    // Merge pinned contacts and unread counts with contact data
    final List<Map<String, dynamic>> mergedContacts = List<Map<String, dynamic>>.from(contacts).map((contact) {
      final chatId = contact['chat_id'];
      final isPinned = pinnedContacts.contains(chatId);
     final unreadCount = contact['unreadCount'] ?? 0; // Use existing unreadCount or default to 0

      return {
        ...contact,
        'pinned': isPinned,
        'unreadCount': unreadCount,
      };
    }).toList();

    setState(() {
      conversations = mergedContacts;
      _isLoading = false;
    });
    print(contacts);
  } catch (error) {
  
    print('Error fetching contacts: $error');
  }
}
Future<void> fetchContactsBackground() async {
  print('Fetching contacts...');
  try {
 

    // Fetch contacts from Firestore
      final companyDocRef = FirebaseFirestore.instance.collection("companies").doc(companyId);
    final contactsSnapshot = await companyDocRef.collection("contacts")
        .orderBy('last_message.timestamp', descending: true)
        .limit(20 * currentPage)
        .get();
    var contacts = contactsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch pinned contacts and unread counts from Firestore
    final userDocRef = FirebaseFirestore.instance.collection("user").doc(email);
    final pinnedContactsSnapshot = await userDocRef.collection("pinned").get();
    final pinnedContacts = pinnedContactsSnapshot.docs.map((doc) => doc.data()['chat_id']).toList();
    print("pinned");

    // Merge pinned contacts and unread counts with contact data
    final List<Map<String, dynamic>> mergedContacts = List<Map<String, dynamic>>.from(contacts).map((contact) {
      final chatId = contact['chat_id'];
      final isPinned = pinnedContacts.contains(chatId);
     final unreadCount = contact['unreadCount'] ?? 0; 

      return {
        ...contact,
        'pinned': isPinned,
        'unreadCount': unreadCount,
      };
    }).toList();

    setState(() {
      conversations = mergedContacts;

    });
    print(contacts);
  } catch (error) {
  
    print('Error fetching contacts: $error');
  }
}
List<String> employeeNames = [];
Future<void> fetchEmployeeNames() async {
  try {
    QuerySnapshot employeeSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('employee')
        .get();

    employeeNames = employeeSnapshot.docs
        .map((doc) => doc['name'] as String)
        .map((name) => name.toLowerCase())
        .toList();
  } catch (e) {
    print('Error fetching employee names: $e');
  }
}
List<Map<String, dynamic>> filteredConversations() {
  List<Map<String, dynamic>> pinnedChats = [];
  List<Map<String, dynamic>> otherChats = [];
  List<Map<String, dynamic>> groupChats = conversations.where((contact) => contact['chat_id'] != null && contact['chat_id'].contains('@g.us')).toList();
    if (!selectedTags.contains('Snooze')) {
    conversations = conversations.where((conversation) {
      List<String> tags = List<String>.from(conversation['tags'] ?? []);
      return !tags.any((tag) => tag.toLowerCase() == 'snooze');
    }).toList();
  }

if (selectedTags.isEmpty || selectedTags.contains('All')) {
conversations = conversations;
  }  else if (selectedTags.contains('Mine')) {
     conversations = conversations.where((conversation) {
      List<String> tags = List<String>.from(conversation['tags'] ?? []);
      return tags.any((tag) => tag.toLowerCase() == firstName.toLowerCase());
    }).toList();
  } else if (selectedTags.contains('Group')) {
    conversations = conversations.where((conversation) =>
      conversation['chat_id'] != null && conversation['chat_id'].contains('@g.us')
    ).toList();
  }else if (selectedTags.contains('Snooze')) {
    conversations = conversations.where((conversation) {
      List<String> tags = List<String>.from(conversation['tags'] ?? []);
      return tags.any((tag) => tag.toLowerCase() == 'snooze');
    }).toList();
  } else if (selectedTags.contains('Unread')) {
    conversations = conversations.where((conversation) =>
      (conversation['unreadCount'] ?? 0) > 0
    ).toList();
  }  else if (selectedTags.contains('Unassigned')) {
    conversations = conversations.where((conversation) {
      List<String> tags = List<String>.from(conversation['tags'] ?? []);
      return !tags.any((tag) => employeeNames.contains(tag.toLowerCase()));
    }).toList();
  } else {
  conversations = conversations.where((conversation) {
    List<dynamic> conversationTags = (conversation['tags'] ?? []).map((tag) => tag.toString().toLowerCase()).toList();
    return selectedTags.any((selectedTag) => conversationTags.contains(selectedTag.toLowerCase()));
  }).toList();
}
   conversations = conversations.take(1000).toList();
  // Filter conversations based on user role and tags
  if (role == "2" || role == "4") {
    conversations = conversations.where((conversation) {
      List<String> tags = List<String>.from(conversation['tags'] ?? []);
      return tags.any((tag) => tag.toLowerCase() == firstName.toLowerCase());
    }).toList();

  //  conversations.addAll(groupChats);
  }

  // Separate pinned and non-pinned chats
  conversations.forEach((conversation) {
    if (conversation['pinned']) {
      pinnedChats.add(conversation);
    } else {
      otherChats.add(conversation);
    }
  });

  // Function to get latest message details
  Map<String, dynamic> getLatestMessageDetails(Map<String, dynamic> conversation) {
    String latestMessage = 'No message';
    DateTime latestTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

    if (conversation['last_message'] != null) {
      var lastMessage = conversation['last_message'];
      if (lastMessage is Map<String, dynamic>) {
        if (lastMessage['type'] == 'text') {
          latestMessage = lastMessage['text']?['body'] ?? 'No message';
        } else if (lastMessage['type'] != 'text') {
          latestMessage = lastMessage['type'] ?? 'Media';
        } else {
          latestMessage = 'Unsupported message type';
        }
      } else if (lastMessage is List) {
        // Handle list type
        latestMessage = lastMessage.isNotEmpty ? lastMessage.first.toString() : 'No message';
      } else if (lastMessage is String) {
        // Handle string type
        latestMessage = lastMessage;
      } else {
        latestMessage = 'Unsupported message format';
      }
     var timestamp = lastMessage['timestamp'];
    if (timestamp is Timestamp) {
      latestTimestamp = timestamp.toDate();
    } else if (timestamp is int) {
      latestTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else {
      print('Unexpected timestamp type: ${timestamp.runtimeType}');
      latestTimestamp = DateTime.now(); // Fallback to current time
    }
    }

    return {
      'latestMessageTimestamp': latestTimestamp,
      'latestMessage': latestMessage,
    };
  }

  // Add latest message details to chats
  List<Map<String, dynamic>> addLatestMessageDetails(List<Map<String, dynamic>> chats) {
    return chats.map((conversation) {
      var latestDetails = getLatestMessageDetails(conversation);
      return {
        ...conversation,
        'latestMessageTimestamp': latestDetails['latestMessageTimestamp'],
        'latestMessage': latestDetails['latestMessage'],
      };
    }).toList();
  }

  pinnedChats = addLatestMessageDetails(pinnedChats);
  otherChats = addLatestMessageDetails(otherChats);

  // Sort pinned and other chats by timestamp
  pinnedChats.sort((a, b) {
    return b['latestMessageTimestamp'].compareTo(a['latestMessageTimestamp']);
  });
  
  otherChats.sort((a, b) {
    return b['latestMessageTimestamp'].compareTo(a['latestMessageTimestamp']);
  });

  // Combine sorted pinned and other chats
  List<Map<String, dynamic>> sortedConversations = [...pinnedChats, ...otherChats];

  // Filter by search term
  String searchTerm = searchController.text.toLowerCase();
  if (searchTerm.isNotEmpty) {
    sortedConversations = sortedConversations.where((conversation) {
      String userName = (conversation['chat']?['name'] ?? '').toLowerCase();
      String phoneNumber = (conversation['id'] ?? '').toLowerCase(); // Assuming 'id' contains the phone number
      String latestMessage = (conversation['latestMessage'] ?? '').toLowerCase();
      return userName.contains(searchTerm) || phoneNumber.contains(searchTerm) || latestMessage.contains(searchTerm);
    }).toList();
  }

  return sortedConversations;
}

void _showAddTagDialog(Map<String, dynamic> conversation, ColorScheme colorScheme) {
  List<String> specialTags = ['Mine', 'All', 'Unassigned', 'Group', 'Unread'];
  List<dynamic> allTags = availableTags.where((tag) => !specialTags.contains(tag)).toList();
  List<String> selectedTags = List<String>.from(conversation['tags'] ?? [])
    .where((tag) => !specialTags.contains(tag)).toList();
  String newTag = '';

  // Add a list of employee names
  
  List<String> selectedEmployees = [];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: colorScheme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Manage Tags', style: TextStyle(color: colorScheme.onBackground, fontWeight: FontWeight.bold)),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Text('Tags', style: TextStyle(color: colorScheme.onBackground, fontWeight: FontWeight.bold)),
                        ...allTags.map((tag) => Card(
                          color: colorScheme.surface,
                          child: CheckboxListTile(
                            title: Text(tag, style: TextStyle(color: colorScheme.onSurface)),
                            value: selectedTags.contains(tag),
                            activeColor: colorScheme.primary,
                            checkColor: colorScheme.onPrimary,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                          ),
                        )).toList(),
                        SizedBox(height: 16),
                        Text('Assign to Employee', style: TextStyle(color: colorScheme.onBackground, fontWeight: FontWeight.bold)),
                        ...employeeNames.map((employee) => Card(
                          color: colorScheme.surface,
                          child: CheckboxListTile(
                            title: Text(employee, style: TextStyle(color: colorScheme.onSurface)),
                            value: selectedEmployees.contains(employee),
                            activeColor: colorScheme.primary,
                            checkColor: colorScheme.onPrimary,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedEmployees.add(employee);
                                } else {
                                  selectedEmployees.remove(employee);
                                }
                              });
                            },
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    style: TextStyle(color: colorScheme.onBackground),
                    decoration: InputDecoration(
                      hintText: "Enter new tag",
                      hintStyle: TextStyle(color: colorScheme.onBackground.withOpacity(0.6)),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      newTag = value;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Add New Tag'),
               
                onPressed: () {
                  if (newTag.isNotEmpty && !allTags.contains(newTag)) {
                    setState(() {
                      allTags.add(newTag);
                      selectedTags.add(newTag);
                      newTag = '';
                    });
                  }
                },
              ),
              ElevatedButton(
                child: Text('Save'),
                
                onPressed: () {
                  List<String> updatedTags = [...selectedTags, ...selectedEmployees];
                  _updateConversationTags(conversation, updatedTags);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _updateConversationTags(Map<String, dynamic> conversation, List<String> newTags) async {
  try {
    // Update the conversation in Firestore
    await FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('contacts')
      .doc(conversation['id'])
      .update({'tags': newTags});
    
    // Update the local state
    setState(() {
      conversation['tags'] = newTags;
      // Trigger a re-filter of conversations
      conversations = List.from(conversations);
    });
    
_handleRefresh();
  } catch (e) {
    print('Error updating tags: $e');
  
  }
}

  void onSearchTextChanged(String text) {
    setState(() {
      filter = text;
    });
  }

Future<void> _handleRefresh() async {
  setState(() {
    _isLoading = true;
    conversations.clear();
  });
await fetchContacts();
}
@override
void initState() {
  super.initState();
  _scrollController.addListener(_scrollListener);
  loadDarkModePreference().then((value) {
    setState(() {
      isDarkMode = value;
    });
  });
  listenNotification();
    fetchConfigurations(false);
}
void _scrollListener() async {
  if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
    if (!_isLoadingMore && currentPage < totalPages) {
      setState(() {
        _isLoadingMore = true;
      });
      currentPage++;
      await fetchMoreContacts();
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
}
Future<void> markConversationAsRead(String chatId) async {
  try {
    // Update the unreadCount in Firestore
    await FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('contacts')
      .doc(chatId)
      .update({'unreadCount': 0});

    // Update the local state
    setState(() {
      conversations = conversations.map((conversation) {
        if (conversation['chat_id'] == chatId) {
          return {...conversation, 'unreadCount': 0};
        }
        return conversation;
      }).toList();
    });

    print('Marked conversation as read: $chatId');
  } catch (error) {
    print('Error marking conversation as read: $error');
  }
}

 void toggleDarkMode() {
  setState(() {
    isDarkMode = !isDarkMode;
    saveDarkModePreference(isDarkMode); // Save the preference
  });
}

  @override
  Widget build(BuildContext context) {
      
  
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
  ));
    final colorScheme = isDarkMode
        ? ColorScheme.dark(
            primary: Color(0xFF101827),
            secondary: Colors.tealAccent,
            surface: Color(0xFF1F2937),
            background: Color(0xFF101827),
            onBackground: Colors.white,
          )
        : ColorScheme.light(
            primary: Color(0xFF2D3748),
            secondary: Color(0xFF2D3748),
            surface: Colors.white,
            background: Colors.white,
            onBackground: Color(0xFF2D3748),
          );

    return Theme(
      data: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.background,
          foregroundColor: colorScheme.onBackground,
        ),
        // ... other theme properties ...
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              
              left: 20,
            ),
            height: MediaQuery.of(context).size.height,
            color: colorScheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        company,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'SF',
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              TextEditingController numberController = TextEditingController();
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Container(
                                     width: MediaQuery.of(context).size.width * 0.9, // Set width to 90% of screen width
                                    child: AlertDialog(
                                        backgroundColor: colorScheme.background,
                                      title: Text('Enter Number',style: TextStyle(color: colorScheme.onBackground)),
                                      content: Row(
                                        children: [
                                          Text('+60',style: TextStyle(color: colorScheme.onBackground)),
                                          SizedBox(width: 10,),
                                          Container(
                                            width: 200,
                                            child: TextField(
                                              controller: numberController,
                                              keyboardType: TextInputType.phone,
                                              style: TextStyle(color: colorScheme.onBackground),
                                              decoration: InputDecoration(hintText: 'Enter phone number',hintStyle: TextStyle(color: colorScheme.onBackground)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Cancel',style: TextStyle(color: colorScheme.onBackground),),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.background,
                                           
                                          ),
                                          onPressed: () {
                                            String phoneNumber = "+60"+numberController.text.trim();
                                            print(phoneNumber);
                                            String chat = phoneNumber+"@s.whatsapp.net";
                                              print(chat);
                                            String chatId = chat.split('+')[1];
                                            print(chatId);
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => MessageScreen(chatId: chatId, messages: [], conversation: {}, whapi: whapiToken, name: phoneNumber, phone: phoneNumber,accessToken: ghl,location: ghl_location,userName:firstName),
                                              ),
                                            );
                                          },
                                          child: Text('Message',style: TextStyle(color: colorScheme.onBackground),),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.add, size: 30, color: colorScheme.onBackground),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              setState(() {
                                conversations.clear();
                                _isLoading = true;
                              });
                              _handleRefresh();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.refresh,size: 30,color: colorScheme.onBackground,),
                            ),
                          ),
                           IconButton(
                            icon: Icon(
                            Icons.notifications,
                              color: colorScheme.onBackground,
                            ),
                            onPressed: (){
                              Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => NotificationScreen(),
                                            ),
                                          );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: colorScheme.onBackground,
                            ),
                            onPressed: toggleDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.onBackground),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontFamily: 'SF',
                      ),
                      cursorColor: colorScheme.onBackground,
                      controller: searchController,
                      onChanged: onSearchTextChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusColor: colorScheme.onBackground,
                        hoverColor: colorScheme.onBackground,
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.6),
                          fontFamily: 'SF',
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: colorScheme.onBackground,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 30,
                  padding: EdgeInsets.only(top:5),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableTags.length,
                    itemBuilder: (context, index) {
                      String tag = availableTags[index];
                      bool isSelected = selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () => toggleTagSelection(tag),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueGrey : Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
),


                Container(
                height: MediaQuery.of(context).size.height *79/100,
                child: RefreshIndicator(
             
                  onRefresh: _handleRefresh,
                  child: _isLoading
                ?  Center(
                    child: CircularProgressIndicator(
                       color: colorScheme.onBackground
                    ),
                  )
                : ListView.builder(
                        controller: _scrollController,
                         padding: EdgeInsets.only(bottom: 80),
                        itemCount: filteredConversations().length,
                        itemBuilder: (context, index) {
                          final conversation = filteredConversations()[index];
                          final pic = (conversation['profilePicUrl']!= null||conversation['profilePicUrl']!='')?conversation['profilePicUrl']:null;
                         final number = (conversation['phone'] != null && conversation['phone'].contains('+'))
    ? conversation['phone'].split("+")[1]
    : conversation['phone'];
                          final userName = (conversation['chat']?['name'] != null)?conversation['chat']['name'] :"+"+ number;
                          final latestMessage = conversation['latestMessage'] ?? 'No message';
                     
                          final latestTimestamp = conversation['latestMessageTimestamp'] ?? DateTime.now();
                          var unread = (conversation['unreadCount'] != null)?conversation['unreadCount']:0;
                          var tags = (conversation['tags'] != null)?conversation['tags']:[];
                          final now = DateTime.now();
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final lastWeek = now.subtract(Duration(days: now.weekday));
  final lastMessageDateTime = latestTimestamp.toLocal();
  String formattedDate;
  if (lastMessageDateTime.day == now.day &&
      lastMessageDateTime.month == now.month &&
      lastMessageDateTime.year == now.year) {
    formattedDate = DateFormat.jm().format(lastMessageDateTime);
  } else if (lastMessageDateTime.day == yesterday.day &&
      lastMessageDateTime.month == yesterday.month &&
      lastMessageDateTime.year == yesterday.year) {
    formattedDate = 'Yesterday';
  } else if (lastMessageDateTime.isAfter(lastWeek)) {
    formattedDate = DateFormat('EEEE').format(lastMessageDateTime);
  } else {
    formattedDate = DateFormat('dd/MM/yyyy').format(lastMessageDateTime);
  }
  int phoneIndex = (conversation['phoneIndex'] != null)?conversation['phoneIndex']:0;
                          final numberOnly = (conversation['chat_id'] != null)?(!conversation['chat_id']?.contains('@g'))?number ?? '':'Group':"";
                          return GestureDetector(
                           onLongPress: role != "2" ? () => _showAddTagDialog(conversation, colorScheme) : null,
                                  onTap: () async {
                                       ProgressDialog.show(context, progressDialogKey);
  print(numberOnly);
                                       if (conversation['unreadCount'] != 0) {
    await markConversationAsRead("+"+numberOnly);
  }
                                print(conversation);
                             
 fetchMessagesForChat(conversation['chat_id'], conversation, userName, numberOnly,pic,conversation['phone'],tags,phoneIndex);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                         height: 50,
                                         width: 50,
                                          decoration: BoxDecoration(
                                          color: Color(0xFF2D3748),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Center(
    child: (conversation['profilePicUrl'] == null || conversation['profilePicUrl'].isEmpty)
      ? Icon(CupertinoIcons.person_fill, size: 45, color: Colors.white)
      : ClipOval(
          child: Image.network(
            conversation['profilePicUrl'],
            fit: BoxFit.cover,
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) {
              return Icon(CupertinoIcons.person_fill, size: 45, color: Colors.white);
            },
          ),
        ),
  ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  width: 180,
                                                  child: Text(
                                                    userName ?? "Webchat",
                                                    maxLines: 1,
                                                    style:  TextStyle(
                                                      color:  colorScheme.onBackground,
                                                     fontFamily: 'SF',
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                     //updatedAtText,
                                                     formattedDate,
                                                      style:  TextStyle(
                                                        color:(unread != 0)?Colors.red :colorScheme.onBackground,
                                                         fontFamily: 'SF',
                                                      fontSize: 10
                                                      ),
                                                    ),
                                                  
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 25,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        width: 220,
                                                        child: Text(
                                                          latestMessage ?? "",
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style:  TextStyle(
                                                            color:  colorScheme.onBackground,
                                                               fontFamily: 'SF',
                                                               fontSize: 12,
                                                            fontWeight: FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                   
                                                       Row(
                                                         children: [
                                                           if (conversation['pinned'])
                                                            Icon(CupertinoIcons.pin_fill, size: 16, color:colorScheme.onBackground),
                                                             if(unread != 0)
                                                           Container(
                                                             height: 15,
                                                             width: 15,
                                                             decoration: BoxDecoration(
                                                               borderRadius: BorderRadius.circular(100),
                                                               color: Colors.redAccent
                                                             ),
                                                             child: Center(
                                                               child: Text(
                                                                 unread.toString(),
                                                                 style: TextStyle(color: Colors.white, fontSize: 10),
                                                               ),
                                                             ),
                                                           ),
                                                         ],
                                                       ),
                                                
                                                   
                                                    ],
                                                  ),
                                                ),
                                                    if (tags.isNotEmpty)
                                                  Wrap(
                                                    spacing: 4.0,
                                                    runSpacing: 4.0,
                                                    children: tags.map<Widget>((tag) {
                                                      return Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blueGrey,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          tag,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                              ],
                                            ),
                                         
                                                  SizedBox(height: 5,),
                                              const Divider(
                                              height: 1,
                                           color: Color.fromARGB(255, 153, 155, 158),
                                              thickness: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                               
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ),
             
            ],
          ),
        ),
      ),
    ));
  }
Future<void> fetchMessagesForChat(String chatId, dynamic chat, String name, String phone, String? pic, String contactId, List<dynamic> tags,int phoneIndex) async {
  try {
    List<Map<String, dynamic>> messages = [];
print(v2);
    if (v2) {
      // Fetch messages from Firebase
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('contacts')
          .doc(contactId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(100)  // Adjust the limit as needed
          .get();

      messages = messagesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      print(messages[0]);
    } else {
      // Fetch messages from Whapi API
      String url = 'https://gate.whapi.cloud/messages/list/$chatId';
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $whapiToken',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        messages = (data['messages'] is List)
            ? data['messages'].cast<Map<String, dynamic>>()
            : [];
      } else {
        print('Failed to fetch messages: ${response.body}');
        return;
      }
    }

    ProgressDialog.hide(progressDialogKey);

    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (context) {
      return MessageScreen(
        companyId: companyId,
        contactId: contactId,
        tags: tags,
        chatId: chatId,
        messages: messages,
        conversation: chat,
        whapi: whapiToken,
        name: name,
        accessToken: ghl,
        phone: phone,
        pic: pic,
        location: ghl_location,
      userName:firstName,
      phoneIndex: phoneIndex,
      );
    })).then((_) {
      // Refresh contacts after coming back from the MessageScreen
      fetchContacts();
    });
  } catch (e) {
    print('Error fetching messages for chat: $e');
    ProgressDialog.hide(progressDialogKey);
  }
}
Future<dynamic> getContact(String number) async {
  // API endpoint
  var url = Uri.parse('https://services.leadconnectorhq.com/contacts/search/duplicate');

  // Request headers
  var headers = {
    'Authorization': 'Bearer ${ghl}',
    'Version': '2021-07-28',
    'Accept': 'application/json',
  };

  // Request parameters
  var params = {
    'locationId': ghl_location,
    'number': number,
  };

  // Send GET request
  var response = await http.get(url.replace(queryParameters: params), headers: headers);
print(response);
  // Handle response
  if (response.statusCode == 200) {
    // Success
    var data = jsonDecode(response.body);
    print(data['contact']);
    setState(() {
     
    });
    return data['contact'];
  } else {
    // Error
    print('Failed to get contact. Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
    return null;
  }
}
}
