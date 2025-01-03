import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:juta_app/screens/contact_detail.dart';
import 'package:juta_app/screens/video.dart';
import 'package:juta_app/utils/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:fluttertoast/fluttertoast.dart' as fluttertoast;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:juta_app/screens/forward.dart';
import 'package:juta_app/utils/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';

class MessageScreen extends StatefulWidget {
  List<Map<String, dynamic>> messages;
  final Map<String, dynamic> conversation;
  String? botId;
  String? accessToken;
  String? workspaceId;
  String? integrationId;
  String? id;
  String? userId;
  String? companyId;
  List<dynamic>? labels;
  String? contactId;
  String? pipelineId;
  String? messageToken;
  Map<String,dynamic>? opportunity;
  String? botToken;
  String? chatId;
  String? whapi;
  String? name;
  String? phone;
  String? pic;
  String? location;
  String? userName;
    List<dynamic>? tags;
    int? phoneIndex;
  MessageScreen(
      {required this.messages,
      required this.conversation,
      this.botToken,
      this.phone,
      this.botId,
      this.accessToken,
      this.workspaceId,
      this.integrationId,
      this.phoneIndex,
      this.id,
      this.whapi,
      this.userId,
      this.tags,
      this.companyId,
      this.contactId,
      this.opportunity,
      this.pipelineId,
      this.location,
      this.userName,
this.messageToken,
this.chatId,
this.name,
this.pic,
      this.labels});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  TextEditingController _messageController = TextEditingController();
  bool typing = false;
  bool expand = false;
  double height = 25;
  bool hasNewline = false;
  bool nowHasNewline = false;
  final String baseUrl = "https://api.botpress.cloud";
  bool stopBot = false;
  TextEditingController tagController = TextEditingController();
  int currentIndex = 0;
  TextEditingController searchController = TextEditingController();
  String filter = "";
  List<Map<String, dynamic>> conversations = [];
  final GlobalKey progressDialogKey = GlobalKey<State>();
  List<Map<String, dynamic>> users = [];
  String botId = '';
  String accessToken = '';
  String nextTokenConversation = '';
  String nextTokenUser = '';
  String workspaceId = '';
  String integrationId = '';
  User? user = FirebaseAuth.instance.currentUser;
  String email = '';
  String firstName = '';
  String company = '';
  String companyId = '';
  List<dynamic> allUsers = [];
  String nextMessageToken = '';
  String conversationId = "";
  UploadTask? uploadTask;
  final ScrollController _scrollController = ScrollController();
  final picker = ImagePicker();
  PlatformFile? pickedFile;
  VideoPlayerController? _controller;
  List<dynamic> pipelines = [];
  List<dynamic> opp = [];
 Map<String, dynamic> contactDetails = {};
List<dynamic> tags =[];
  Map<String, Uint8List?> _pdfCache = {};
    bool isDarkMode = false;
StreamSubscription<RemoteMessage>? _notificationSubscription;
  Map<String, dynamic>? replyToMessage;
  List<Map<String, dynamic>> quickReplies = [];
  bool showQuickReplies = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
     loadDarkModePreference();
    listenNotification();
       if (widget.tags != null && widget.tags!.contains('stop bot')) {
  stopBot = true;
}
      _scrollController.addListener(_scrollListener);
    _messageController.addListener(() {
      String value = _messageController.text;
                        
      // Check for '/' trigger
      if (value.startsWith('/')) {
        _showQuickRepliesOverlay();
      } else if (showQuickReplies && !value.contains('/')) {
        _hideQuickRepliesOverlay();
      }

      // Your existing height calculation code
      List<String> lines = value.split('\n');
      int newHeight = 50 + (lines.length - 1) * 20;
      if (value.length > 29) {
        int additionalHeight = ((value.length - 1) ~/ 29) * 25;
        newHeight += additionalHeight;
      }
      setState(() {
        height = newHeight.clamp(0, 200).toDouble();
      });
    });
    fetchQuickReplies();
  }

  Future<void> loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }
  void _scrollListener() {
  if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
      !_scrollController.position.outOfRange) {
        showToast("Fetching more data...");
    loadMoreMessages();
  }
}
Future<void> listenNotification() async {
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        List<Map<String, dynamic>> messages = [];
        
        // Fetch messages from Firestore
        QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('contacts')
            .doc(widget.contactId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(100) // Adjust the limit as needed
            .get();

        messages = messagesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        
        // Update the state if the widget is still mounted
        if (mounted) {
          setState(() {
            widget.messages = messages; // Update the messages list
          });
        }
      } catch (e) {
         // Handle any errors
      }
    });
  }

void showToast(String message) {
  fluttertoast.Fluttertoast.showToast(
    msg: message,
    toastLength:  fluttertoast.Toast.LENGTH_SHORT,
    gravity:  fluttertoast.ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.grey,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
  Future<void> loadMoreMessages() async {
  try {
      List<Map<String, dynamic>> newMessages = [];
      int oldestTimestamp = widget.messages.last['timestamp'];
        // Fetch more messages from Firebase
        QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('contacts')
            .doc(widget.contactId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
.where('timestamp', isLessThan: oldestTimestamp)
            .get();

        newMessages = messagesSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();


      setState(() {
        widget.messages.addAll(newMessages);
      });

          } catch (e) {
          }
}

  
Future<dynamic> getContact(String number) async {
  // API endpoint
  var url = Uri.parse('https://services.leadconnectorhq.com/contacts/search/duplicate');

  // Request headers
  var headers = {
    'Authorization': 'Bearer ${widget.accessToken!}',
    'Version': '2021-07-28',
    'Accept': 'application/json',
  };

  // Request parameters
  var params = {
    'locationId': widget.location!,
    'number': number,
  };

  // Send GET request
  var response = await http.get(url.replace(queryParameters: params), headers: headers);
  // Handle response
  if (response.statusCode == 200) {
    // Success
    var data = jsonDecode(response.body);
        setState(() {
      tags = (data['contact'] != null)?data['contact']['tags']:[];
    });
    return data['contact'];
  } else {
    // Error
            return null;
  }
}
   void _showImageDialog() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.media);
    if (result != null) {
      setState(() {
        pickedFile = result.files.first;
      if (pickedFile!.extension?.toLowerCase() == 'mp4' || pickedFile!.extension?.toLowerCase() == 'mov') {

          _controller?.dispose();
          _controller = VideoPlayerController.file(File(pickedFile!.path!))
            ..initialize().then((_) {
              setState(() {});
            });
        } else {
          _controller?.dispose();
          _controller = null;
        }
      });
    }
  }

Future<void> sendImageMessage(String to, PlatformFile? imageFile, String caption) async {
  if (imageFile == null || imageFile.path == null) {
    return;
  }
  
  String messageType = pickedFile!.extension?.toLowerCase() == 'mov' ? 'video' : 'image';
  print(messageType);
  
  setState(() {
    pickedFile = null;
    _messageController.clear();
  });

  try {
    // Upload the image to Firebase Storage and get the URL
    String imageUrl = await uploadImageToFirebaseStorage(imageFile);

    // Fetch the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated");
      return;
    }

    // Fetch user document from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(user.email)
        .get();

    if (!userSnapshot.exists) {
      print('No such user document!');
      return;
    }

    // Extract companyId from user data
    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
    String companyId = userData['companyId'];

    // Fetch company document from Firestore
    DocumentSnapshot companySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    if (!companySnapshot.exists) {
      print('No such company document!');
      return;
    }

    // Extract apiUrl from company data
    Map<String, dynamic> companyData = companySnapshot.data() as Map<String, dynamic>;
    String baseUrl = companyData['apiUrl'] ?? 'https://mighty-dane-newly.ngrok-free.app';

    // Construct the request URL
    String url = '$baseUrl/api/v2/messages/image/${widget.companyId}/${widget.chatId}';
    var body = json.encode({
      'imageUrl': imageUrl,
      'caption': caption,
      'phoneIndex': widget.phoneIndex,
      'userName': widget.userName,
    });

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final response2 = await http.get(Uri.parse(imageUrl));
      String base64Image = base64Encode(response2.bodyBytes);

      // Create a new message object
      Map<String, dynamic> newMessage = {
        'type': messageType,
        'from_me': true,
        messageType: {
          'data': base64Image, // For video, you might want to store a thumbnail or a different representation
        },
        'caption': caption,
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'chat_id': widget.chatId,
        'direction': 'outgoing',
      };

      // Update the UI
      setState(() {
        widget.messages.insert(0, newMessage);
        pickedFile = null; // Clear the picked file
        _messageController.clear();
      });
    } else {
      // Handle error
    }
  } catch (e) {
    // Handle exception
  }
}

Future<String> uploadImageToFirebaseStorage(PlatformFile imageFile) async {
  try {
    // Create a reference to the location you want to upload to in Firebase Storage
    String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + imageFile.name;
    Reference ref = FirebaseStorage.instance.ref().child('chat_images').child(fileName);

    // Upload the file to Firebase Storage
    UploadTask uploadTask = ref.putFile(File(imageFile.path!));

    // Wait for the upload to complete and get the download URL
    TaskSnapshot taskSnapshot = await uploadTask;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    return downloadUrl;
  } catch (e) {
        rethrow;
  }
}


  Future<void> updateStopBotStatus(String companyId, String contactId, bool stopBot) async {
    await FirebaseFirestore.instance
      .collection("companies")
      .doc(companyId)
      .collection("contacts")
      .doc(contactId)
      .get()
      .then((snapshot) {
        if (snapshot.exists) {
          List<dynamic> tags = snapshot.get("tags") ?? [];
          if (stopBot) {
            if (!tags.contains("stop bot")) {
              tags.add("stop bot");
            }
          } else {
            tags.remove("stop bot");
          }
          snapshot.reference.update({
            'tags': tags,
          }).then((_) {
                      }).catchError((error) {
                      });
        }
      }).catchError((error) {
              });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _notificationSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Colors.blue.withOpacity(0.5), // Change this to your desired color
          cursorColor: Colors.blue, // Change this to your desired cursor color
          selectionHandleColor: Colors.blue, // Change this to your desired handle color
        ),
      ),
      child: Scaffold(
         
        appBar: AppBar(
          backgroundColor:colorScheme.background,
          automaticallyImplyLeading: false,
          title: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(),
            child: Row(
           
          
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child:  Icon(CupertinoIcons.chevron_back,size: 35,
                        color: colorScheme.onBackground,)),
            
               
                if(true)//widget.conversation!['name'] != null)
                GestureDetector(
                  onTap: (){
                         //  _showConfirmDelete();
                         
                  },
                  child: Container(
                                             height: 35,
                                             width: 35,
                                              decoration: BoxDecoration(
                                              color: Color(0xFF2D3748),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Center(child:(widget.pic == null || !widget.pic!.contains('.jpg'))?Icon((widget.phone != 'Group')?CupertinoIcons.person_fill:Icons.groups,size: 20,color: Colors.white,):ClipOval(
                                          child:Image.network(
              widget.pic!,
              fit: BoxFit.cover,
              width: 60,
              height: 60,
              errorBuilder: (context, error, stackTrace) {
                return Icon(CupertinoIcons.person_fill, size: 45, color: Colors.white);
              },
            ), 
            )),
                                          ),
                ),
                                    const SizedBox(
                  width: 5,
                ),
                 GestureDetector(
                  onTap: (){
                 
                          // _showConfirmDelete();
                  },
                  child:  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 160,
                        child: Text(widget.name!,style: TextStyle(fontSize: 15),)),
                       if (tags.isNotEmpty)
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: tags.map<Widget>((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: colorScheme.onBackground,
                            fontSize: 8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                    ],
                  )
                ),
              
               
                
                GestureDetector(
                  onTap: (){
                  
                    _launchURL("tel:${widget.phone}");
                  },
                  child:  Icon(CupertinoIcons.phone_fill,size: 25,color:colorScheme.onBackground,)),
      
              Transform.scale(
                scale: 0.7,
                    child: Switch(
                      
                      activeColor: CupertinoColors.systemBlue ,
                      
                      value: !stopBot,
                     onChanged: (value){
                               
                     
                         if (mounted) {
                        
                           setState(() {
                               stopBot = !stopBot;
                           });
                             updateStopBotStatus(widget.companyId!,widget.contactId!,stopBot);
                         }
                    }),
                  ),
                    
              ],
            ),
          ),
      
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() {
              typing = false;
            });
          },
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
             
                  child: ListView.builder(
                     key: ValueKey<int>(widget.messages.length), // Add this key
                       controller: _scrollController, 
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.messages.length,
                    reverse: true, // To display messages from the bottom
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      if(message['chat_id'] != null) {
                        final type = message['type'];
                        final isSent = message['from_me'];
                        DateTime parsedDateTime;
                        if (message['timestamp'] is int) {
                          parsedDateTime = DateTime.fromMillisecondsSinceEpoch(message['timestamp'] * 1000).toLocal();
                        } else if (message['timestamp'] is Timestamp) {
                          parsedDateTime = message['timestamp'].toDate().toLocal();
                        } else {
                          parsedDateTime = DateTime.now().toLocal();
                        }

                        String formattedTime = DateFormat('h:mm a').format(parsedDateTime);

                        if (type == 'document' && message['document'] != null && message['document']['link'] != null) {
                          return Align(
                            alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                            child: _buildPdfMessageBubble(isSent, message['document']['link'], formattedTime, colorScheme),
                          );
                        } else if (type == 'document') {
                          return Align(
                            alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                            child: _buildMessageBubble(isSent, "Document unavailable", [], formattedTime, colorScheme, message),
                          );
                        } else if (type == 'text') {
                          final messageText = message['text']['body'];
                          return Draggable<Map<String, dynamic>>(
                            // Data is the message map
                            data: message,
                            // Specify the axis as horizontal to limit dragging to left/right
                            axis: Axis.horizontal,
                            // The child is your existing message bubble
                            child: Align(
                              alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
                              child: _buildMessageBubble(isSent, messageText, [], formattedTime, colorScheme,message),
                            ),
                            // The feedback widget is what appears under the user's finger while dragging
                            feedback: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.7,
                                child: _buildMessageBubble(isSent, messageText, [], formattedTime, colorScheme,message),
                              ),
                            ),
                            // onDragEnd is called when the user lifts their finger
                            onDragEnd: (details) {
                              if (details.offset.dx < -50 && isSent) {  // Dragged left
                                setState(() {
                                                                    replyToMessage = message;
                                });
                              }else if (!isSent && details.offset.dx > 50) {  // Received message dragged right
                                setState(() {
                                  replyToMessage = message;
                                });
                              }
                            },
                            // childWhenDragging is the widget that stays in place while dragging
                            childWhenDragging: Opacity(
                              opacity: 0.0,
                              child: _buildMessageBubble(isSent, messageText, [], formattedTime, colorScheme,message),
                            ),
                          );
                        } else if (type == 'image' && message['image']['data'] != null) {
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSent ? CupertinoColors.systemBlue  : const Color.fromARGB(255, 224, 224, 224),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Builder(
                                          builder: (context) {
                                            if (message['image'] != null && message['image']['data'] != null) {
                                              try {
                                                return GestureDetector(
                                                  onTap: () => _openImageFullScreen(context, base64Decode(message['image']['data'])),
                                                  child: Image.memory(
                                                    base64Decode(message['image']['data']),
                                                    height: 250,
                                                    width: 250,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, isSent),
                                                  ),
                                                );
                                              } catch (e) {
                                                                                                return _buildErrorWidget(context, isSent);
                                              }
                                            } else if (message['image'] != null && message['image']['link'] != null) {
                                              return GestureDetector(
                                                onTap: () => _openImageFullScreen(context, null, message['image']['link']),
                                                child: Image.network(
                                                  message['image']['link'],
                                                  height: 250,
                                                  width: 250,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(child: CircularProgressIndicator());
                                                  },
                                                  errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, isSent),
                                                ),
                                              );
                                            } else {
                                              return _buildErrorWidget(context, isSent);
                                            }
                                          },
                                        ),
                                      ),
                                      if (message['caption'] != null && message['caption'].isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 5, left: 8, right: 8, bottom: 20),
                                          child: Text(message['caption']),
                                        ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    right: 15,
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (type == 'document' &&  message['document'] != null) {
                          return GestureDetector(
                            onTap: () => _openDocument(context, message['document']),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.description, size: 40),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message['document']['filename'] ?? 'Document',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (message['document']['fileSize'] != null)
                                          Text(
                                            '${(message['document']['fileSize'] / 1024).toStringAsFixed(1)} KB',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (type == 'image' && message['image']['url'] != null) {
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSent ? CupertinoColors.systemBlue  : const Color.fromARGB(255, 224, 224, 224),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Builder(
                                          builder: (context) {
                                            if (message['image'] != null && message['image']['data'] != null) {
                                              try {
                                                return GestureDetector(
                                                  onTap: () => _openImageFullScreen(context, base64Decode(message['image']['data'])),
                                                  child: Image.memory(
                                                    base64Decode(message['image']['data']),
                                                    height: 250,
                                                    width: 250,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, isSent),
                                                  ),
                                                );
                                              } catch (e) {
                                                                                                return _buildErrorWidget(context, isSent);
                                              }
                                            } else if (message['image'] != null && message['image']['link'] != null) {
                                              return GestureDetector(
                                                onTap: () => _openImageFullScreen(context, null, message['image']['link']),
                                                child: Image.network(
                                                  message['image']['link'],
                                                  height: 250,
                                                  width: 250,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null) return child;
                                                    return Center(child: CircularProgressIndicator());
                                                  },
                                                  errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, isSent),
                                                ),
                                              );
                                            } else {
                                              return _buildErrorWidget(context, isSent);
                                            }
                                          },
                                        ),
                                      ),
                                      if (message['caption'] != null && message['caption'].isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 5, left: 8, right: 8, bottom: 20),
                                          child: Text(message['caption']),
                                        ),
                                    ],
                                  ),
                                  Positioned(
                                    bottom: 5,
                                    right: 15,
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (type == 'video' && message['video'] != null && message['video']['link'] != null) {
                          return VideoMessageBubble(
                            videoUrl: message['video']['link'],
                            caption: message['video']['caption'],
                            isSent: isSent, // Pass the isSent value
                            time: formattedTime, // Pass the formatted time
                          );
                        } else if (type == 'poll') {
                          final messageText = message['poll']['title'];
                          return Align(
                            alignment: isSent
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: _buildMessageBubble(
                              isSent, messageText, message['poll']['options'],formattedTime,colorScheme,message
                            ),
                          );
                        } else {
                          final type = 'text';
                         final messageText = message['body'] ?? message['text']?['body'] ?? '';
                          final isSent = (message['direction'] != 'inbound');
                         DateTime? parsedDateTime;
if (message['dateAdded'] != null) {
  parsedDateTime = DateTime.parse(message['dateAdded']).toLocal();
} else {
  parsedDateTime = DateTime.now().toLocal(); // fallback to current time
}
                          String formattedTime = DateFormat('h:mm a').format(parsedDateTime);
                          return Align(
                            alignment: isSent
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: _buildMessageBubble(isSent, messageText, [],formattedTime,colorScheme,message),
                          );
                        }
                      }
                      return const SizedBox
                          .shrink(); // Hide if type is not recognized
                    },
                  ),
                ),
              ),
         Container(
        child: Column(
      children: [
        if (pickedFile != null)
          Stack(
            children: [
          ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: SizedBox(
    height: 200,
    child: (pickedFile!.extension?.toLowerCase() == 'mp4' || pickedFile!.extension?.toLowerCase() == 'mov')
        ? (_controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : Center(child: CircularProgressIndicator())) // Show a loading indicator while the video is initializing
        : Image.file(
            File(pickedFile!.path!),
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Text('Failed to load image'));
            },
          ),
  ),
),
              GestureDetector(
                onTap: () {
                  setState(() {
                    pickedFile = null;
                    _controller?.dispose();
                    _controller = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onBackground,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        Container(
        child: Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          if (replyToMessage != null)
              Container(
              
                             color: const Color.fromARGB(255, 57, 57, 57),
                child: Row(
                  children: [
                    Container(
                     width: 10,
                     height: 50,
                      decoration: BoxDecoration(
                        color: replyToMessage!['from_me']
                              ? const Color(0xFFDCF8C6) : colorScheme.onBackground,
                       
                      ),
                    ),
                    SizedBox(width: 5,),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                            replyToMessage!['from_me']
                              ?'You':widget.name!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: replyToMessage!['from_me']
                              ? const Color(0xFFDCF8C6) : colorScheme.onBackground,
                              fontSize: 15,
                              fontFamily: 'SF',
                            ),
                          ),
                          Text(
                            '${replyToMessage!['text']['body']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'SF',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          replyToMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
          Container(
           
            child: Row(
              children:[
              IconButton(
  icon: const Icon(Icons.quickreply),
  onPressed: () => _showQuickRepliesOverlay(), // or just _showQuickRepliesOverlay
  color: colorScheme.onBackground,
),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _showImageDialog,
                  color: colorScheme.onBackground,
                ),
                 IconButton(
                  icon: const Icon(Icons.video_camera_back),
                  onPressed: _showImageDialog,
                  color: colorScheme.onBackground,
                ),
                Expanded(
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color.fromARGB(255, 187, 194, 206)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: TextField(
                        
                        onSubmitted: (value) async {
                          if (pickedFile == null) {
                           // Create the new message object
  final newMessage = {
    'type': 'text',
    'from_me': true,
    'text': {'body':  _messageController.text},
    'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'chat_id': widget.chatId,
    'direction': 'outgoing',
  };

  // Update UI first (optimistic update)
  setState(() {
    widget.messages = [newMessage, ...widget.messages]; // Create new list reference
  
    replyToMessage = null;
  });

                            await sendTextMessage(
                                widget.chatId!, _messageController.text);
                              _messageController.clear();    
                          } else {
                            print('image');
                            await sendImageMessage(
                                widget.conversation['id'],
                                pickedFile!,
                                _messageController.text);
                          }
                        },
                        onTap: () {
                          setState(() {
                            typing = true;
                          });
                        },
                        onTapOutside: (event) {
                          setState(() {
                            typing = false;
                          });
                        },
                        maxLines: null,
                        expands: true,
                        cursorColor: Colors.black,
                        style:  TextStyle(
                          color: colorScheme.onBackground,
                          fontSize: 15,
                          fontFamily: 'SF',
                        ),
                        controller: _messageController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Color(0xFF2D3748),
                  ),
                  child: IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      if (pickedFile == null) {
                       var newMessage = {
    'type': 'text',
    'direction': 'outgoing',
    'text': {'body': _messageController.text},
    'dateAdded': DateTime.now().toUtc().toIso8601String(),
    'from_me': true, // Add this to match your message bubble logic
    'chat_id': widget.chatId, // Add this to match your message filtering
    'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000, // Add this for consistent timestamp handling
  };

  // Create a new list reference to ensure setState triggers properly
  setState(() {
    widget.messages = [newMessage, ...widget.messages];

    pickedFile = null;
  });
      print(widget.messages.length);
                        await sendTextMessage(
                            widget.chatId!, _messageController.text);
                      } else {
                          // Create a new message object
    
                         // Update the UI
                        if (widget.chatId != null) {
                          await (
                              widget.chatId!,
                              pickedFile!,
                              _messageController.text);
                        }
                           print('image');
                                   await sendImageMessage(
                                widget.conversation['id'],
                                pickedFile!,
                                _messageController.text);
                    
                      }
                       
                    },
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 25,)
        ],
      ),
        ),
      ),
      
      ],
        ),
      ),
      
            ],
          ),
        ),
      ),
    );
  }


void _openDocument(BuildContext context, Map<String, dynamic> document) async {
  try {
    final String? base64Data = document['data'];
    final String filename = document['filename'] ?? 'document.pdf';
    
    if (base64Data == null) {
      throw 'Document data not found';
    }

    // Convert base64 to bytes
    final bytes = base64Decode(base64Data.trim());
    
    // Get temporary directory
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    
    // Write to temporary file
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    // Navigate to PDF viewer screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(filename),
          ),
          body: PDFView(
            filePath: filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            onError: (error) {
                          },
            onPageError: (page, error) {
                          },
          ),
        ),
      ),
    );
    
  } catch (e) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text('Error opening document: $e'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
Future<void> sendTextMessage(String to, String messageText) async {
  setState(() {
    _messageController.clear();  
  });

  try {
    // Fetch the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated");
      return;
    }

    // Fetch user document from Firestore
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(user.email)
        .get();

    if (!userSnapshot.exists) {
      print('No such user document!');
      return;
    }

    // Extract companyId from user data
    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
    String companyId = userData['companyId'];

    // Fetch company document from Firestore
    DocumentSnapshot companySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    if (!companySnapshot.exists) {
      print('No such company document!');
      return;
    }

    // Extract apiUrl from company data
    Map<String, dynamic> companyData = companySnapshot.data() as Map<String, dynamic>;
    String baseUrl = companyData['apiUrl'] ?? 'https://mighty-dane-newly.ngrok-free.app';

    // Construct the request URL
    String url = '$baseUrl/api/v2/messages/text/${widget.companyId}/${widget.chatId}';
    var body = json.encode({
      'message': messageText,
      'quotedMessageId': replyToMessage?['id'], // Add logic for reply if needed
      'phoneIndex': widget.phoneIndex,
      'userName': widget.userName,
    });

    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
      },
      body: body,
    );

    print(response.body);
    if (response.statusCode == 200) {
      // Message sent successfully
      setState(() {
        replyToMessage = null;
      });
    } else {
      // Handle error
    }
  } catch (e) {
    // Handle exception
  }
}

  _launchURL(String url) async {
    await launch(Uri.parse(url).toString());
  }

  void _launchWhatsapp(String number) async {
        String url = 'https://wa.me/$number';
    try {
      await launch(url);
    } catch (e) {
      throw 'Could not launch $url';
    }
  }
   _showOptions(String message) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
     
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
           
            Container(
                color: Colors.white,
                height: 200,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {
                             ProgressDialog.show(context, progressDialogKey);
                   
                            ProgressDialog.hide(progressDialogKey);
                            Navigator.of(context)
                              .push(CupertinoPageRoute(builder: (context) {
                            return ForwardScreen(opp: opp,message:message,whapi: widget.whapi!,);
                          }));
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 100,
                              child: Text(
                                'Forward',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 16,
                                           fontFamily: 'SF',
                                    fontWeight: FontWeight.bold,
                                    color:  Color(0xFF2D3748)),
                              ),
                            ),
                            Icon(Icons.forward,color: Color(0xFF2D3748)),
                          ],
                        ),
                      ),
                      Divider(
                        color: Color(0xFF2D3748),
                      ),
                      GestureDetector(
                        onTap: () {
                         Clipboard.setData(ClipboardData(text: message));
    Navigator.pop(context); // Close the modal
    showToast('Message copied to clipboard');
                        
                        },
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                width: 100,
                                child: Text(
                                  'Copy',
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                        color:  Color(0xFF2D3748)),
                                ),
                              ),
                              Icon(Icons.copy,    color: Color(0xFF2D3748)),
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
  Widget _buildPdfMessageBubble(bool isSent, String pdfUrl, String formattedTime,ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: isSent ? const Color(0xFFDCF8C6) : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            height: 300,
            child: FutureBuilder<Uint8List?>(
              future: _downloadPdfFile(pdfUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return PdfView(
                      controller: PdfController(
                        document: PdfDocument.openData(snapshot.data!),
                      ),
                    );
                  } else {
                    return Center(child: Text('Failed to load PDF'));
                  }
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              formattedTime,
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _downloadPdfFile(String url) async {
    if (_pdfCache.containsKey(url)) {
      return _pdfCache[url];
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final pdfData = response.bodyBytes;
      _pdfCache[url] = pdfData;
      return pdfData;
    } else {
      throw Exception('Failed to load PDF');
    }
  }
Widget _buildMessageBubble(
    bool isSent, String message, List<dynamic>? options, String time,ColorScheme colorScheme,Map<String, dynamic> messageData) {
  return GestureDetector(
    onLongPress: () {
      _showOptions(message);
    },
    child: Container(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      width: MediaQuery.of(context).size.width * 70 / 100,
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5),
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isSent ? CupertinoColors.systemBlue : colorScheme.onBackground,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 50.0, top: 8.0, bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(messageData['text']['context'] != null)
                         Container(
          
                         decoration: BoxDecoration(
                         color: const Color.fromARGB(255, 206, 206, 206),
                          borderRadius: BorderRadius.circular(8.0),
                         ),
                           child: Row(
                             children: [
                               Container(
                     width: 10,
                     height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
      topLeft: Radius.circular(5),
      bottomLeft: Radius.circular(5),
    ),
                        color: messageData!['from_me']
                              ? const Color.fromARGB(255, 147, 147, 147) : colorScheme.background,
                       
                      ),
                    ),
                    SizedBox(width: 5,),
                               Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                            messageData!['text']['context']['quoted_author'] != widget.name
                              ?'You':widget.name!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSent
                              ? const  Color.fromARGB(255, 147, 147, 147) : colorScheme.background,
                              fontSize: 14,
                              fontFamily: 'SF',
                            ),
                          ),
                                   Container(
                                          width: MediaQuery.of(context).size.width * 40 / 100,
                                     child: Text(
                                      messageData['text']['context']['quoted_content']['body'],
                                      style:  TextStyle(
                                        fontSize: 12.0,
                                        color: isSent ? Color.fromARGB(255, 0, 0, 0) :colorScheme.background,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'SF',
                                      ),
                                        maxLines: 1,
                                                       overflow: TextOverflow.ellipsis,
                                                             ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                        Text(
                          message,
                          style:  TextStyle(
                            fontSize: 15.0,
                            color: isSent ? Color.fromARGB(255, 255, 255, 255) :colorScheme.background,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'SF',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Text(
                      time,
                      style:  TextStyle(
                        fontSize: 9.0,
                        color:  isSent ? Color.fromARGB(255, 255, 255, 255) :colorScheme.background,
                        fontFamily: 'SF',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (options!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  child: ListView.builder(
                    itemCount: options.length,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(141, 124, 124, 124),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            options[index]['label'].toString(),
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Color(0xFF0D85FF),
                              fontFamily: 'SF',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}
Widget _buildErrorWidget(BuildContext context, bool isSent) {
  return Container(
    width: 200,
    height: 200,
    decoration: BoxDecoration(
      color: isSent ? const Color(0xFF0D85FF) : Color.fromARGB(141, 217, 0, 0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Center(
      child: Text(
        "Image failed to load",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.white,
          fontFamily: 'SF',
        ),
      ),
    ),
  );
}

void _openImageFullScreen(BuildContext context, Uint8List? imageData, [String? imageUrl]) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text('Image Viewer')),
      body: Center(
        child: PhotoView(
          imageProvider: imageData != null
              ? MemoryImage(imageData)
              : NetworkImage(imageUrl!) as ImageProvider,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    ),
  ));
}

void _openPdfFullScreen(BuildContext context, String pdfUrl) async {
  // Download the PDF file
  final response = await http.get(Uri.parse(pdfUrl));
  final bytes = response.bodyBytes;

  // Get a temporary directory on the device
  final dir = await getTemporaryDirectory();
  
  // Create a temporary file
  final file = File('${dir.path}/temp.pdf');
  
  // Write the PDF to the temporary file
  await file.writeAsBytes(bytes);

  // Open the PDF viewer
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => Scaffold(
      appBar: AppBar(title: Text('PDF Viewer')),
      body: PDFView(
        filePath: file.path,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: false,
        pageFling: false,
      ),
    ),
  ));
}

Future<void> fetchQuickReplies() async {
  try {
    // Get the current user's email
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    // Fetch company quick replies
    var companySnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('quickReplies')
        .orderBy('createdAt', descending: true)
        .get();

    // Fetch user's personal quick replies
    var userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(userEmail)
        .collection('quickReplies')
        .orderBy('createdAt', descending: true)
        .get();

    List<Map<String, dynamic>> replies = [
      ...companySnapshot.docs.map((doc) => {
            'id': doc.id,
            'keyword': doc.data()['keyword'] ?? '',
            'text': doc.data()['text'] ?? '',
            'type': 'all',
            'document': doc.data()['document'],
            'image': doc.data()['image'],
          }),
      ...userSnapshot.docs.map((doc) => {
            'id': doc.id,
            'keyword': doc.data()['keyword'] ?? '',
            'text': doc.data()['text'] ?? '',
            'type': 'self',
            'document': doc.data()['document'],
            'image': doc.data()['image'],
          }),
    ];

    setState(() {
      quickReplies = replies;
    });
  } catch (e) {
      }
}

void _showQuickRepliesOverlay() {
  _hideQuickRepliesOverlay();

  _overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Add a transparent GestureDetector that covers the whole screen
        Positioned.fill(
          child: GestureDetector(
            onTap: _hideQuickRepliesOverlay,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // Your existing overlay content
        Positioned(
          bottom: MediaQuery.of(context).viewInsets.bottom + 60,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {}, // Prevent taps on the overlay from closing it
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 200,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListView.builder(
                  itemCount: quickReplies.length,
                  itemBuilder: (context, index) {
                    final reply = quickReplies[index];
                    return ListTile(
                      title: Text(reply['keyword'] ?? ''),
                      subtitle: Text(reply['text'] ?? ''),
                      onTap: () => _handleQuickReplySelection(reply),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Overlay.of(context).insert(_overlayEntry!);
  setState(() {
    showQuickReplies = true;
  });
}

void _hideQuickRepliesOverlay() {
  _overlayEntry?.remove();
  _overlayEntry = null;
  setState(() {
    showQuickReplies = false;
  }); 
}

void _handleQuickReplySelection(Map<String, dynamic> reply) async {
  if (reply['image'] != null) {
    // Handle image quick reply
    try {
      // Download the image from the URL
      final response = await http.get(Uri.parse(reply['image']));
      if (response.statusCode == 200) {
        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/temp_image.jpg');
        await file.writeAsBytes(response.bodyBytes);

        // Set the downloaded file as pickedFile
        setState(() {
          pickedFile = PlatformFile(
            name: 'temp_image.jpg',
            path: file.path,
            size: response.bodyBytes.length,
            bytes: response.bodyBytes,
          );
        });
      }
    } catch (e) {
          }
  }

  setState(() {
    _messageController.text = reply['text'] ?? '';
  });

  _hideQuickRepliesOverlay();
}
}