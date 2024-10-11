class Conversation {
  String convoId;
  String name;
  String phone;
  DateTime latestMessageTimestamp;
  String latestMessage;
  // Add other fields as necessary

  Conversation({required this.convoId, required this.name, required this.phone,required this.latestMessageTimestamp,required this.latestMessage});

  Map<String, dynamic> toFirestore() {
    return {
      'convoId':convoId,
      'name':name,
      'phone': phone,
      'latestMessageTimestamp':latestMessageTimestamp,
      'latestMessage':latestMessage,
      // Include other fields here
    };
  }

  static Conversation fromMap(Map<String, dynamic> map, String convoId,String name) {
    return Conversation(
      convoId: convoId,
      name:name,
      phone: map['tags']['userPhone'],
      latestMessageTimestamp:map['latestMessageTimestamp'],
      latestMessage:map['latestMessage'],
      // Initialize other fields here
    );
  }
}
