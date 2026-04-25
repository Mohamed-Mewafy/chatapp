import 'package:chatapp/view/Chat/chat_room_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/chat_room.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // خلفية فاتحة ومريحة
      appBar: AppBar(
        title: const Text(
          'بدء محادثة جديدة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // جلب المستخدمين مع استثناء المستخدم الحالي من البداية لو أردت (اختياري)
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('حدث خطأ في تحميل البيانات'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمون حالياً'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: users.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final String userId = users[index].id;
              final String userName = userData['name'] ?? 'مستخدم مجهول';
              final String userEmail = userData['email'] ?? '';

              // منع ظهور اسمك في القائمة
              if (userId == myUid) return const SizedBox.shrink();

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  userEmail,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
                onTap: () => _startChat(context, userId, userName, userEmail),
              );
            },
          );
        },
      ),
    );
  }

  void _startChat(
    BuildContext context,
    String otherUserId,
    String otherUserName,
    String otherUserEmail,
  ) async {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    // 1. تكوين ID الغرفة (الترتيب الأبجدي يضمن ثبات الـ ID للطرفين)
    List<String> ids = [myUid, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");

    try {
      // 2. تحديث أو إنشاء الغرفة في Firestore
      // استخدمنا set مع merge: true عشان نحافظ على البيانات القديمة ونحدث بس الـ lastMessageTime
      await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).set({
        'id': chatRoomId,
        'participants': ids,
        'name':
            otherUserName, // ملحوظة: الأفضل تخزين أسماء الطرفين كـ Map للمستقبل
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. الانتقال لصفحة الشات مع تمرير بيانات كاملة
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomPage(
            chatRoom: ChatRoom(
              id: chatRoomId,
              name: otherUserName,
              lastMessage: '',
              lastMessageTime:
                  DateTime.now(), // قيمة افتراضية حتى يأتي التحديث من Firebase
              participants: ids,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل بدء المحادثة: $e')));
    }
  }
}
