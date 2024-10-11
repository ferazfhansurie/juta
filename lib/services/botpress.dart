import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class BotpressConversationService {
  final String botpressServerUrl;
  final String botId;
   final String baseUrl;
    final String accessToken;
     final String integrationId;
    final String companyId;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  BotpressConversationService({required this.companyId,required this.botpressServerUrl, required this.botId,required this.baseUrl,required this.accessToken,required this.integrationId});

    Future<void> syncConversationWithFirestore(String conversationId, String phoneNumber,String name) async {
    // Step 2: Fetch messages from Botpress
    var messages = await listMessages3(conversationId);

    if (messages.isNotEmpty) {
      var latestMessage = messages.last;
      var messagesCollection = firestore.collection('companies')
      .doc(companyId)
      .collection('conversations')
      .doc(phoneNumber).collection('messages');

      // Add each message to Firestore under this conversation
      for (var message in messages) {
        await messagesCollection.add(message);
      }

      // Step 1: Check for existing conversation and Step 3: Update or create conversation
      var conversationDoc = firestore.collection('companies').doc(companyId).collection('conversations')
      .doc(phoneNumber);
      var docSnapshot = await conversationDoc.get();
      if (docSnapshot.exists) {
        // If exists, update the latest message and timestamp
        await conversationDoc.update({
          'latestMessage': await getLatestMessage(conversationId), // Customize based on your data structure
          'latestMessageTimestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // If not exists, create a new conversation with details
        await conversationDoc.set({
          'name':name,
          'phone': phoneNumber,
          'convoId': conversationId,
          'latestMessage':await getLatestMessage(conversationId), // Customize based on your data structure
          'latestMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }
 Future<String> getLatestMessage(String conversationId) async {
    String url = '$baseUrl/v1/chat/messages?conversationId=$conversationId';

    http.Response response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'x-bot-id': botId,
        'x-integration-id': integrationId,
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      List<dynamic> messages = responseBody['messages'];

      if (messages.isNotEmpty) {
        String latestMessage = "";
        for (var i = messages.length - 1; i >= 0; i--) {
          latestMessage = messages[i]['payload']['text']??"";
        }

        return latestMessage;
      } else {
        return ""; // Return a default value if no messages found
      }
    } else {
     return ""; // Return a default value if no messages found
    }
  }
  Future<List<Map<String, dynamic>>> listMessages3(String conversationId) async {
    String url = '$baseUrl/v1/chat/messages?conversationId=$conversationId';
    var response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'x-bot-id': botId,
        'x-integration-id': integrationId,
      },
    );
  print(response.body);
    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      List<dynamic> messages = responseBody['messages'];
      return messages.cast<Map<String, dynamic>>();
    } else {
      print("Failed to fetch messages from Botpress: ${response.statusCode}");
      return [];
    }
  }
}
