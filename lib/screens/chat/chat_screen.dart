import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String targetUserId;
  final bool isEmergency;

  const ChatScreen({super.key, required this.targetUserId, this.isEmergency = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  String _targetName = "Vehicle Owner";
  String _targetPlate = "Unknown Plate";

  @override
  void initState() {
    super.initState();
    _fetchTargetUser();
  }

  String get _chatId {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.uid ?? 'unknown';
    List<String> ids = [currentUserId, widget.targetUserId];
    ids.sort();
    return ids.join('_');
  }

  void _fetchTargetUser() async {
    if (widget.isEmergency) {
      setState(() {
        _isLoading = false;
        _targetName = "Security & Management";
        _targetPlate = "SOS";
      });
      return;
    }

    try {
      // Changed to read from publicVehicles per security rules feedback
      final doc = await FirebaseFirestore.instance.collection('publicVehicles').doc(widget.targetUserId).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        final name = data['ownerName'] as String? ?? "Vehicle Owner";
        final plate = data['plateNumber'] as String? ?? "Unknown Plate";

        setState(() {
          _isLoading = false;
          _targetName = name;
          _targetPlate = plate;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          // Fallback if publicVehicles document does not exist yet
          _targetName = "Vehicle Owner";
          _targetPlate = "Unknown Plate";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _targetName = "Vehicle Owner";
          _targetPlate = "Unknown Plate";
        });
      }
    }
  }

  String _formatTime(DateTime time) {
    int hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    String period = time.hour >= 12 ? 'PM' : 'AM';
    String min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (currentUserId == null) return;

    final messageText = text.trim();
    _messageController.clear();
    
    final chatId = _chatId;
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    final now = FieldValue.serverTimestamp();

    List<String> sortedParticipants = [currentUserId, widget.targetUserId];
    sortedParticipants.sort();

    final chatData = <String, dynamic>{
      'participants': sortedParticipants,
      'lastMessage': messageText,
      'lastMessageAt': now,
      'updatedAt': now,
      'status': 'active',
      'deletedFor': {
        currentUserId: FieldValue.delete(),
      },
      'createdAt': FieldValue.serverTimestamp(), // Will be merged if it doesn't exist
    };

    if (widget.isEmergency) {
      chatData['type'] = 'emergency';
    } else {
      chatData['blockedDriverId'] = currentUserId;
      chatData['vehicleOwnerId'] = widget.targetUserId;
      chatData['type'] = 'blocked';
    }

    await chatRef.set(chatData, SetOptions(merge: true));

    await messageRef.set({
      'senderId': currentUserId,
      'receiverId': widget.targetUserId,
      'messageText': messageText,
      'createdAt': now,
      'isRead': false,
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isLoading 
          ? const SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)
            )
          : Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                  child: const Icon(Icons.directions_car_rounded, color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _targetName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _targetPlate,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.blueAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E),
                  title: const Text('Parking Issue Resolved?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Do you want to delete this chat now that the issue is solved?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteChat();
                      },
                      child: const Text('Delete Chat', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.greenAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Initiating secure call...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Quick Replies
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickReply('Please move your car'),
                _buildQuickReply('I am blocked'),
                _buildQuickReply('Are you coming?'),
                _buildQuickReply('I need to leave now'),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages.', style: TextStyle(color: Colors.white54)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                final messages = snapshot.data?.docs ?? [];
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + 1, // +1 for the system message
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildSystemMessage('You are now connected securely. Your number remains hidden. Use this chat to request the driver to move their vehicle.');
                    }

                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final text = data['messageText'] as String? ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeStr = createdAt != null ? _formatTime(createdAt.toDate()) : '';

                    return _buildMessageBubble(doc.id, text, isMe, timeStr);
                  },
                );
              },
            ),
          ),
          
          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 14),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final chatRef = firestore.collection('chats').doc(_chatId);
      final messageRef = chatRef.collection('messages').doc(messageId);

      final deletedLatestMessage = await firestore.runTransaction<bool>((transaction) async {
        final chatSnapshot = await transaction.get(chatRef);
        final messageSnapshot = await transaction.get(messageRef);

        if (!messageSnapshot.exists) return false;

        final chatData = chatSnapshot.data();
        final messageData = messageSnapshot.data()!;
        final wasLatestMessage = chatSnapshot.exists
            && chatData?['lastMessage'] == messageData['messageText']
            && chatData?['lastMessageAt'] == messageData['createdAt'];

        transaction.delete(messageRef);

        if (wasLatestMessage) {
          transaction.update(chatRef, {
            'lastMessage': '',
            'lastMessageAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        return wasLatestMessage;
      });

      if (!deletedLatestMessage) return;

      final remainingMessages = await chatRef
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) return;

      final latestMessageRef = remainingMessages.docs.first.reference;
      await firestore.runTransaction((transaction) async {
        final chatSnapshot = await transaction.get(chatRef);
        final latestMessageSnapshot = await transaction.get(latestMessageRef);

        if (!chatSnapshot.exists || !latestMessageSnapshot.exists) return;

        final chatData = chatSnapshot.data();
        if (chatData?['lastMessage'] != '' || chatData?['lastMessageAt'] != null) {
          return;
        }

        final latestMessageData = latestMessageSnapshot.data()!;
        final latestMessageAt = latestMessageData['createdAt'];
        transaction.update(chatRef, {
          'lastMessage': latestMessageData['messageText'],
          'lastMessageAt': latestMessageAt,
          'updatedAt': latestMessageAt,
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteChat() async {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (currentUserId == null) return;
    try {
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'deletedFor.$currentUserId': true,
      });
      if (mounted) {
        Navigator.pop(context); // Go back to chat list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete chat.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(String messageId, String text, bool isMe, String time) {
    Widget bubble = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: Colors.blueAccent, size: 14),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blueAccent : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            const Icon(Icons.check_circle_rounded, color: Colors.blueAccent, size: 14),
        ],
      ),
    );

    if (isMe) {
      return Dismissible(
        key: Key(messageId),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          _deleteMessage(messageId);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20, bottom: 16),
          color: Colors.transparent,
          child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
        ),
        child: bubble,
      );
    }

    return bubble;
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 12, 
        bottom: MediaQuery.of(context).padding.bottom > 0 
            ? MediaQuery.of(context).padding.bottom 
            : 16
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.blueAccent,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
