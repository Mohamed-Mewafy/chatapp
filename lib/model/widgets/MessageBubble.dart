import 'package:chatapp/model/chat_room.dart';
import 'package:chatapp/theme/theme.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl!,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.white),
                      ),
                    )
                  else if (message.messageType == 'file')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.15)
                            : AppColors.chatBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMe ? Colors.white : AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.fileName ?? "File",
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.75)
                              : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildReadIndicator(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          isMe
              ? "M"
              : (message.senderEmail.isNotEmpty
                    ? message.senderEmail[0].toUpperCase()
                    : "U"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildReadIndicator() {
    final otherUserId = currentUserId;
    if (otherUserId == null) {
      return const Icon(Icons.check, size: 14, color: Colors.white54);
    }

    final otherUserRead = message.readBy.entries
        .where((entry) => entry.key != otherUserId)
        .any((entry) => entry.value == true);

    if (otherUserRead) {
      return const Icon(Icons.done_all, size: 14, color: Colors.white);
    } else if (message.readBy.length > 1) {
      return const Icon(Icons.done_all, size: 14, color: Colors.white54);
    } else {
      return const Icon(Icons.check, size: 14, color: Colors.white54);
    }
  }
}
