import 'package:chatapp/theme/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/chat_room.dart';
import '../Chat/chat_room_page.dart';
import '../../services/message_notification_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  final MessageNotificationService _notificationService =
      MessageNotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.startListeningForNewMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'LenChat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.accent,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _showUserSearchDialog,
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, "Setting"),
                child: Container(
                  margin: const EdgeInsets.only(right: 16, left: 4),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Messages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Recent',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildChatList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUserSearchDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_search, color: Colors.white, size: 22),
        label: const Text(
          'New Chat',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: _auth.currentUser?.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Check Firestore Index:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        final docs = snapshot.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final doc = docs[index];
              final chatRoom = ChatRoom.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return ChatRoomTile(
                chatRoom: chatRoom,
                currentUserId: _auth.currentUser?.uid ?? '',
                onTap: () => _openChat(chatRoom),
              );
            }, childCount: docs.length),
          ),
        );
      },
    );
  }

  void _openChat(ChatRoom chatRoom) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('chatRooms').doc(chatRoom.id).update({
        'readStatus.$uid': true,
      });
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(chatRoom: chatRoom),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 56,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a new chat to begin messaging',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _showUserSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Start Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter email...',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                Navigator.pop(context);
                _showAllUsersDialog();
              },
              child: const Text('Show all users instead'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _searchUserAndCreateChat,
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAllUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'All Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('users').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No users found');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final email = userData['email'] ?? 'Unknown';
                    final name = userData['name'] ?? email.split('@')[0];
                    final userId = userDoc.id;
                    final currentUserId = _auth.currentUser?.uid;
                    if (userId == currentUserId) return const SizedBox.shrink();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        email,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _createChatWithUser(userId, name);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _createChatWithUser(String otherUserId, String name) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final existingChatQuery = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: currentUserId)
          .get();

      final existingChatDoc = existingChatQuery.docs.where((doc) {
        final participants = doc.data()['participants'] as List;
        return participants.contains(otherUserId);
      }).firstOrNull;

      ChatRoom chatRoom;
      if (existingChatDoc != null) {
        chatRoom = ChatRoom.fromMap(
          existingChatDoc.data() as Map<String, dynamic>,
          existingChatDoc.id,
        );
      } else {
        final newChatRef = await _firestore.collection('chatRooms').add({
          'name': name,
          'lastMessage': 'Chat started',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'participants': [currentUserId, otherUserId],
          'lastMessageSenderId': currentUserId,
          'readStatus': {currentUserId: true, otherUserId: false},
        });

        chatRoom = ChatRoom(
          id: newChatRef.id,
          name: name,
          lastMessage: 'Chat started',
          lastMessageTime: DateTime.now(),
          participants: [currentUserId, otherUserId],
          lastMessageSenderId: currentUserId,
          readStatus: {currentUserId: true, otherUserId: false},
        );
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(chatRoom: chatRoom),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  Future<void> _searchUserAndCreateChat() async {
    final email = _searchController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final userData = userQuery.docs.first.data();
      final otherUserId = userQuery.docs.first.id;
      final otherName = userData['name'] ?? email.split('@')[0];

      if (otherUserId == _auth.currentUser?.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot chat with yourself')),
          );
        }
        return;
      }

      Navigator.pop(context);
      _searchController.clear();
      await _createChatWithUser(otherUserId, otherName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose),
        );
      }
    }
  }
}

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatRoomTile({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamic userReadStatus = chatRoom.readStatus[currentUserId];
    final bool isUnread =
        (userReadStatus == false) &&
        (chatRoom.lastMessageSenderId != currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: _buildAvatar(),
        title: Text(
          chatRoom.name,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            chatRoom.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(chatRoom.lastMessageTime),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            if (isUnread)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.rose,
                  shape: BoxShape.circle,
                ),
              )
            else
              _buildReadStatusIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Center(
        child: Text(
          chatRoom.name.isNotEmpty ? chatRoom.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildReadStatusIcon() {
    if (chatRoom.lastMessageSenderId != currentUserId)
      return const SizedBox.shrink();
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return const SizedBox.shrink();
    final isReadByOther =
        chatRoom.readStatus.containsKey(otherUserId) &&
        chatRoom.readStatus[otherUserId] == true;
    return Icon(
      isReadByOther ? Icons.done_all : Icons.done_all,
      size: 16,
      color: isReadByOther ? AppColors.primary : AppColors.textMuted,
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month}";
  }
}
