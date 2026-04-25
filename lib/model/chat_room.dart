import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final List<String> participants;
  final String? lastMessageSenderId;
  final Map<String, bool> readStatus; 

  ChatRoom({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.participants,
    this.lastMessageSenderId,
    Map<String, bool>? readStatus,
  }) : readStatus = readStatus ?? {};

  // هل توجد رسائل غير مقروءة للمستخدم الحالي؟
  bool hasUnreadMessages(String currentUserId) {
    return readStatus[currentUserId] == false;
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      name: map['name'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participants: List<String>.from(map['participants'] ?? []),
      lastMessageSenderId: map['lastMessageSenderId'],
      readStatus: Map<String, bool>.from(map['readStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'participants': participants,
      'lastMessageSenderId': lastMessageSenderId,
      'readStatus': readStatus,
    };
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderEmail;
  final String message;
  final DateTime timestamp;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String messageType; 
  final Map<String, bool> readBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.message,
    required this.timestamp,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.messageType = 'text',
    Map<String, bool>? readBy,
  }) : readBy = readBy ?? {};

  // تحديد نوع الرسالة بشكل سريع للتلوين أو اختيار الـ Widget
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isText => messageType == 'text';

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      messageType: map['messageType'] ?? 'text',
      readBy: Map<String, bool>.from(map['readBy'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(), // استخدام وقت السيرفر أفضل للدقة
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'messageType': messageType,
      'readBy': readBy,
    };
  }
}