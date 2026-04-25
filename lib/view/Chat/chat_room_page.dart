import 'dart:async';

import 'package:chatapp/model/chat_room.dart';
import 'package:chatapp/model/widgets/MessageBubble.dart';
import 'package:chatapp/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomPage({super.key, required this.chatRoom});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _listenToReadStatus();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _listenToReadStatus() {
    final user = _auth.currentUser;
    if (user == null) return;
    _messagesSubscription = _firestore
        .collection('chatRooms')
        .doc(widget.chatRoom.id)
        .collection('messages')
        .where('senderId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          if (mounted) setState(() {});
        });
  }

  Future<void> _markMessagesAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final otherUserId = widget.chatRoom.participants.firstWhere(
      (id) => id != user.uid,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return;

    try {
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .collection('messages')
          .where('senderId', isEqualTo: otherUserId)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        final readBy = doc.data()['readBy'] as Map<String, dynamic>?;
        if (readBy == null || readBy[user.uid] != true) {
          batch.update(doc.reference, {'readBy.${user.uid}': true});
        }
      }
      await batch.commit();

      await _firestore.collection('chatRooms').doc(widget.chatRoom.id).update({
        'readStatus.${user.uid}': true,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chatRooms')
                      .doc(widget.chatRoom.id)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final message = ChatMessage.fromMap(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        );
                        final isMe = message.senderId == _auth.currentUser?.uid;
                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          currentUserId: _auth.currentUser?.uid,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Center(
              child: Text(
                widget.chatRoom.name.isNotEmpty
                    ? widget.chatRoom.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatRoom.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          _buildAppBarAction(Icons.call, _startVoiceCall),
          const SizedBox(width: 8),
          _buildAppBarAction(Icons.videocam, _startVideoCall),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.message_outlined,
              size: 48,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the conversation!',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildAttachButton(Icons.image_outlined, _pickImage),
            const SizedBox(width: 8),
            _buildAttachButton(Icons.attach_file, _pickFile),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.chatBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final messageText = _messageController.text.trim();
      final otherUserId = widget.chatRoom.participants.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );

      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderEmail': user.email ?? 'Unknown',
            'message': messageText,
            'messageType': 'text',
            'timestamp': Timestamp.now(),
            'readBy': {user.uid: true, otherUserId: false},
          });

      await _firestore.collection('chatRooms').doc(widget.chatRoom.id).update({
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': user.uid,
        'readStatus': {user.uid: true, otherUserId: false},
      });

      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) await _uploadImage(image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null)
        await _uploadFile(result.files.single);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = _storage.ref().child(
        'chat_images/${widget.chatRoom.id}/$fileName',
      );
      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      final otherUserId = widget.chatRoom.participants.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );

      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderEmail': user.email ?? 'Unknown',
            'message': 'Sent an image',
            'messageType': 'image',
            'imageUrl': downloadUrl,
            'timestamp': Timestamp.now(),
            'readBy': {user.uid: true, otherUserId: false},
          });

      await _firestore.collection('chatRooms').doc(widget.chatRoom.id).update({
        'lastMessage': '📷 Image',
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': user.uid,
        'readStatus': {user.uid: true, otherUserId: false},
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref().child(
        'chat_files/${widget.chatRoom.id}/$fileName',
      );
      await ref.putFile(File(file.path!));
      final downloadUrl = await ref.getDownloadURL();

      final otherUserId = widget.chatRoom.participants.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );

      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderEmail': user.email ?? 'Unknown',
            'message': 'Sent a file',
            'messageType': 'file',
            'fileUrl': downloadUrl,
            'fileName': file.name,
            'timestamp': Timestamp.now(),
            'readBy': {user.uid: true, otherUserId: false},
          });

      await _firestore.collection('chatRooms').doc(widget.chatRoom.id).update({
        'lastMessage': '📎 File: ${file.name}',
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': user.uid,
        'readStatus': {user.uid: true, otherUserId: false},
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }

  void _startVoiceCall() => _initiateCall('voice');
  void _startVideoCall() => _initiateCall('video');

  Future<void> _initiateCall(String callType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final callRef = await _firestore.collection('calls').add({
        'callerId': user.uid,
        'callerEmail': user.email ?? 'Unknown',
        'callerName': user.email?.split('@')[0] ?? 'User',
        'receiverId': widget.chatRoom.participants.firstWhere(
          (id) => id != user.uid,
          orElse: () => '',
        ),
        'callType': callType,
        'status': 'ringing',
        'roomId': widget.chatRoom.id,
        'timestamp': Timestamp.now(),
      });

      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderEmail': user.email ?? 'Unknown',
            'message': callType == 'voice' ? '📞 Voice call' : '📹 Video call',
            'messageType': 'call',
            'callType': callType,
            'callId': callRef.id,
            'timestamp': Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$callType call initiated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting call: $e'),
          backgroundColor: AppColors.rose,
        ),
      );
    }
  }
}
