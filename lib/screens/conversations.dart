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
  String? userPhone = '0';
  Map<String, String> phoneNames = {};
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
 String userPhoneCount = '';
   String phoneCount = '';
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
        if(snapshot.data()!.containsKey("phone")){    
        userPhone = snapshot.get("phone")?.toString()??''; // Add this line
        }
       
        if(snapshot.data()!.containsKey("phoneCount")){
        userPhoneCount = snapshot.get("phoneCount")?.toString()??''; // Add this line
        }
        
      });
 
    } else {
          }
  }).then((value) {
    if (companyId != null && companyId.isNotEmpty) {
            FirebaseFirestore.instance
          .collection("companies")
          .doc(companyId)
          .get()
          .then((snapshot) async {
        if (snapshot.exists) {
                       if (mounted) {
               setState(() {
                 var automationData = snapshot.data() as Map<String, dynamic>;
                   if(automationData.containsKey('v2')) {
                    v2 = snapshot.get("v2");
                  }
                  if(automationData.containsKey('phoneCount')){
                     phoneCount = snapshot.get("phoneCount");
                              int phoneCountInt = int.parse(phoneCount);
                  phoneNames.clear(); // Clear existing phone names
                  for (int i = 0; i < phoneCountInt; i++) { // Changed from <= to <
                    String phoneKey = 'phone${i+1}';
                    if (automationData.containsKey(phoneKey)) {
                      String phoneName = snapshot.get(phoneKey) ?? '';
                      if (phoneName.isNotEmpty) {
                        phoneNames[i.toString()] = phoneName;
                      }
                    }
                  }
                            
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
           
           
          });
               String topic = '';
      if(userPhone != null && phoneCount != '' && phoneCount != "0" && userPhone!.isNotEmpty){
        topic = '${companyId}_phone_${userPhone}';
      } else {
        topic = companyId;
      }
            // Modify subscription logic based on phone presence
          FirebaseMessaging.instance.subscribeToTopic(topic);
          print(topic);
                  await getLocationTags();
                  await fetchEmployeeNames();
                    await fetchContacts();
             }
;
        } else {
                  }
      });
    } else {
          }
  });
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
    try {
    setState(() {
      _isLoading = true;
    });

    // Fetch contacts from Firestore
      final companyDocRef = FirebaseFirestore.instance.collection("companies").doc(companyId);
    final contactsSnapshot = await companyDocRef.collection("contacts")
        .orderBy('last_message.timestamp', descending: true)
        .limit(100 * currentPage)
        .get();
      var contacts = contactsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch pinned contacts and unread counts from Firestore
    final userDocRef = FirebaseFirestore.instance.collection("user").doc(email);
    final pinnedContactsSnapshot = await userDocRef.collection("pinned").get();
    final pinnedContacts = pinnedContactsSnapshot.docs.map((doc) => doc.data()['chat_id']).toList();
    
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
      } catch (error) {
    setState(() {
      _isLoading = false;
    });
      }
}
Future<void> fetchMoreContacts() async {
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
      } catch (error) {
  
      }
}
Future<void> fetchContactsBackground() async {
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
      } catch (error) {
  
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
      }
}
List<Map<String, dynamic>> filteredConversations() {
  if (userPhone != null) {
       
         conversations = conversations.where((conversation) {
      // Check for both phoneIndexes array and single phoneIndex
      var phoneIndexes = conversation['phoneIndexes'];
      var singlePhoneIndex = conversation['phoneIndex'];
      int? userPhoneInt = int.tryParse(userPhone!);
      
      // Debug prints
                              
      // Check if phoneIndexes array exists and includes userPhone
      if (phoneIndexes != null && phoneIndexes is List) {
        return phoneIndexes.contains(userPhoneInt);
      }
      
      // Fallback to single phoneIndex comparison
      return singlePhoneIndex?.toString() == userPhone;
    }).toList();
  }
  List<Map<String, dynamic>> pinnedChats = [];
  List<Map<String, dynamic>> otherChats = [];
   
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
  List<String> selectedEmployees = [];

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.96,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: isDarkMode ? Brightness.dark : Brightness.light,
                  primaryColor: CupertinoColors.systemBlue,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: CupertinoAlertDialog(
                    title: Text('Manage Tags', 
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      )
                    ),
                    content: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: double.maxFinite,
                      child: Column(
                        children: [
                          Expanded(
                            child: CupertinoScrollbar(
                              child: ListView(
                                children: [
                                  _buildSectionHeader('Tags', colorScheme),
                                  ...allTags.map((tag) => _buildTagItem(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedTags.add(tag);
                                        } else {
                                          selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                    colorScheme: colorScheme,
                                  )).toList(),
                                  
                                  _buildSectionHeader('Assign to Employee', colorScheme),
                                  ...employeeNames.map((employee) => _buildTagItem(
                                    tag: employee,
                                    isSelected: selectedEmployees.contains(employee),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedEmployees.add(employee);
                                        } else {
                                          selectedEmployees.remove(employee);
                                        }
                                      });
                                    },
                                    colorScheme: colorScheme,
                                  )).toList(),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          CupertinoTextField(
                            placeholder: "Enter new tag",
                            placeholderStyle: TextStyle(
                              color: colorScheme.onBackground.withOpacity(0.6),
                            ),
                            style: TextStyle(color: colorScheme.onBackground),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onChanged: (value) {
                              newTag = value;
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      CupertinoDialogAction(
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
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        child: Text('Save'),
                        onPressed: () {
                          List<String> updatedTags = [...selectedTags, ...selectedEmployees];
                          _updateConversationTags(conversation, updatedTags,conversation['phone']);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
Future<void> _updateConversationTags(Map<String, dynamic> conversation, List<String> newTags,String chatId) async {
  try {
    print(chatId);
    // Update the conversation in Firestore
    await FirebaseFirestore.instance
      .collection('companies')
      .doc(companyId)
      .collection('contacts')
      .doc(chatId)
      .update({'tags': newTags});
    
    // Update the local state
    setState(() {
      conversation['tags'] = newTags;
      // Trigger a re-filter of conversations
      conversations = List.from(conversations);
    });
    
_handleRefresh();
  } catch (e) {
      
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

      } catch (error) {
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
          primary: CupertinoColors.systemBackground.darkColor,
          secondary: CupertinoColors.secondarySystemBackground.darkColor,
          surface: CupertinoColors.secondarySystemBackground.darkColor,
          background: CupertinoColors.systemBackground.darkColor,
          onBackground: CupertinoColors.label.darkColor,
        )
      : ColorScheme.light(
          primary: CupertinoColors.systemBackground,
          secondary: CupertinoColors.secondarySystemBackground,
          surface: CupertinoColors.systemBackground,
          background: CupertinoColors.systemBackground,
          onBackground: CupertinoColors.label,
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
               CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        Text(
                          phoneNames[userPhone] ?? 'Select Phone',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color: CupertinoColors.systemBlue ,
                        ),
                      ],
                    ),
                    onPressed: () {
                      
                                  showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: colorScheme.background,
                                    title: Text('Select Phone',
                                        style: TextStyle(color: colorScheme.onBackground)),
                                    content: Container(
                                      width: double.minPositive,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: phoneNames.length,
                                        itemBuilder: (context, index) {
                                          String key = phoneNames.keys.elementAt(index);
                                          return ListTile(
                                            title: Text(
                                              phoneNames[key]!,
                                              style: TextStyle(color: colorScheme.onBackground),
                                            ),
                                            selected: key == userPhone,
                                            onTap: () async {
                                              // Update Firebase first
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection("user")
                                                    .doc(email)
                                                    .update({
                                                  'phone': key
                                                });
                                                
                                                setState(() {
                                                  userPhone = key;
                                                });
                                                
                                                Navigator.pop(context);
                                                fetchContacts(); // Refresh contacts with new phone filter
                                                
                                                // Show success message
                                                Toast.show(context, 'success', 
                                                  'Phone switched to ${phoneNames[key]}');
                                                  
                                              } catch (e) {
                                                                                                Toast.show(context, 'error', 
                                                  'Failed to update phone. Please try again.');
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                           
                            
                    },
                  ),
                   Spacer(),
                  Row(
                    children: [
                          GestureDetector(
                            onTap: () async {
                              TextEditingController numberController = TextEditingController();
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return CupertinoTheme(
                                    data: CupertinoThemeData(
                                      brightness: isDarkMode ? Brightness.dark : Brightness.light,
                                      primaryColor: CupertinoColors.systemBlue,
                                    ),
                                    child: CupertinoAlertDialog(
                                      title: Text(
                                        'Enter Number',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onBackground,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.onBackground.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '+60',
                                                  style: TextStyle(color: colorScheme.onBackground),
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: CupertinoTextField(
                                                    controller: numberController,
                                                    keyboardType: TextInputType.phone,
                                                    placeholder: 'Enter phone number',
                                                    style: TextStyle(color: colorScheme.onBackground),
                                                    decoration: BoxDecoration(
                                                      color: Colors.transparent,
                                                      border: Border.all(color: Colors.transparent),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: Text('Cancel'),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
// ... existing code ...
CupertinoDialogAction(
  isDefaultAction: true,
  child: Text('Message'),
  onPressed: () {
    print(numberController.text);
    String phoneNumber = numberController.text.trim();
    
    // Clean the phone number: remove all non-digit characters
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove leading 60 if present
    if (phoneNumber.startsWith('60')) {
      phoneNumber = phoneNumber.substring(2);
    }
    
    // Ensure the phone number is valid
    if (phoneNumber.isEmpty) {
      Toast.show(context, 'error', 'Please enter a valid phone number');
      return;
    }
    
    // Format the chat ID and display number
    String chatId = "60$phoneNumber@c.us";
    print(chatId);
    String displayNumber = "+60$phoneNumber";
    
    Navigator.of(context).pop();
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => MessageScreen(
          chatId: chatId,
          companyId: companyId,
          messages: [],
          conversation: {},
          whapi: whapiToken,
          name: displayNumber,
          phone: displayNumber,
          accessToken: ghl,
          location: ghl_location,
          userName: firstName,
          phoneIndex: userPhone != null ? int.parse(userPhone!) : 0,
        ),
      ),
    );
  },
),
// ... existing code ...
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(CupertinoIcons.plus, size: 30, color: colorScheme.onBackground),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                 decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: colorScheme.onBackground.withOpacity(0.05),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
                child: CupertinoSearchTextField(
                  controller: searchController,
                  onChanged: onSearchTextChanged,
                  style: TextStyle(color: colorScheme.onBackground),
                  placeholder: 'Search conversations...',
                ),
              ),
            ),
           Container(
              height: 30,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableTags.length,
                itemBuilder: (context, index) {
                  String tag = availableTags[index];
                  bool isSelected = selectedTags.contains(tag);
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: CupertinoButton(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      color: isSelected 
                        ? CupertinoColors.systemBlue 
                        : colorScheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected 
                            ? CupertinoColors.white 
                            : colorScheme.onBackground,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () => toggleTagSelection(tag),
                    ),
                  );
                },
              ),
            ),


                Container(
                height: MediaQuery.of(context).size.height *72/100,
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
                          final userName = (conversation['contactName'] != null)?conversation['contactName'] :"+"+ number;
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
                                onLongPress: () => _showAddTagDialog(conversation, colorScheme) ,
                                onTap: () async {
                                  ProgressDialog.show(context, progressDialogKey);
                                    if (conversation['unreadCount'] != 0) {
    await markConversationAsRead("+"+numberOnly);
                                  }
                                                             
 fetchMessagesForChat(conversation['chat_id'], conversation, userName, numberOnly,pic,conversation['phone'],tags,phoneIndex);
                                },
                                child: Container(
                                  decoration: BoxDecoration(

      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: colorScheme.onBackground.withOpacity(0.05),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
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
                                            boxShadow: [
      BoxShadow(
        color: colorScheme.onBackground.withOpacity(0.1),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
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
                                                             boxShadow: [
      BoxShadow(
        color: CupertinoColors.systemBlue.withOpacity(0.2),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
                                                            color: CupertinoColors.systemBlue ,
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

      messages = messagesSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((message) {
            // Filter out unwanted message types
            String type = message['type'] ?? '';
            bool validType = type != 'action' && 
                           type != 'e2e_notification' && 
                           type != 'notification_template';

            // Check phone index conditions
            bool validPhoneIndex = userPhone == null || 
                              
                                 message['phoneIndex'] == null ||
                                 message['phoneIndex'] == int.parse(userPhone!);

            return validType && validPhoneIndex;
          })
          .toList();
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
  // Handle response
  if (response.statusCode == 200) {
    // Success
    var data = jsonDecode(response.body);
        setState(() {
     
    });
    return data['contact'];
  } else {
    // Error
            return null;
  }
}
Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      title,
      style: TextStyle(
        color: colorScheme.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildTagItem({
  required String tag,
  required bool isSelected,
  required Function(bool?) onChanged,
  required ColorScheme colorScheme,
}) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isSelected ? CupertinoColors.systemBlue : colorScheme.onBackground.withOpacity(0.1),
        width: 1,
      ),
    ),
    child: CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () => onChanged(!isSelected),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 150,
            child: Text(
              tag,
              style: TextStyle(
                color: colorScheme.onBackground,
                fontSize: 16,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              CupertinoIcons.check_mark,
              color: CupertinoColors.systemBlue,
              size: 20,
            ),
        ],
      ),
    ),
  );
}
}
