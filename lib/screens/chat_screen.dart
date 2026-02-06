import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chantierId;
  final UserModel currentUser;

  const ChatScreen({
    super.key,
    required this.chantierId,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  void _send() {
    if (_controller.text.trim().isEmpty) return;

    final msg = Message(
      id: '', // Firestore génèrera l'ID
      senderId: widget.currentUser.id,
      senderName: widget.currentUser.nom,
      text: _controller.text,
      timestamp: DateTime.now(),
      chantierId: widget.chantierId,
    );

    _chatService.sendMessage(widget.chantierId, msg);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discussion Chantier")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chantierId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // Pour que les derniers messages soient en bas
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    bool isMe = m.senderId == widget.currentUser.id;
                    return _buildMessageBubble(m, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message m, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.orange : Colors.blueGrey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                m.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            Text(
              m.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Ecrire..."),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.orange),
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}
