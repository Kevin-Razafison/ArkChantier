import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final ChatRoomType chatRoomType;
  final UserModel currentUser;
  final String? customTitle; // ✅ NOUVEAU paramètre

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatRoomType,
    required this.currentUser,
    this.customTitle, // ✅ NOUVEAU
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;

  /// Sélectionner une image depuis la galerie ou la caméra
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur sélection image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      setState(() => _isUploading = true);

      final String fileName =
          'chat_${widget.chatRoomId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'chat_images/$fileName',
      );

      await storageRef.putFile(image);
      final String downloadUrl = await storageRef.getDownloadURL();

      setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      debugPrint('❌ Erreur upload image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur upload image'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _send({MessageType type = MessageType.text}) async {
    if (type == MessageType.text && _controller.text.trim().isEmpty) {
      return;
    }
    if (type == MessageType.photo && _selectedImage == null) {
      return;
    }

    String? photoUrl;
    String messageText = _controller.text.trim();

    if (_selectedImage != null) {
      photoUrl = await _uploadImage(_selectedImage!);
      if (photoUrl == null) return;
    }

    final msg = Message(
      id: '',
      senderId: widget.currentUser.id,
      senderName: widget.currentUser.nom,
      text: messageText.isEmpty ? '📷 Photo' : messageText,
      timestamp: DateTime.now(),
      chatRoomId: widget.chatRoomId,
      chatRoomType: widget.chatRoomType,
      type: type,
      photoUrl: photoUrl,
      photoPath: _selectedImage?.path,
      isRead: false,
    );

    await _chatService.sendMessage(msg);

    setState(() {
      _controller.clear();
      _selectedImage = null;
    });
  }

  /// Dialog pour choisir la source de l'image
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override // CORRECTION: @override au lieu de @@override
  Widget build(BuildContext context) {
    final bool isClient = widget.currentUser.role == UserRole.client;

    String roomTitle =
        widget.customTitle ??
        (widget.chatRoomType == ChatRoomType.projet
            ? "Discussion Projet"
            : "Discussion Chantier");
    return Scaffold(
      appBar: AppBar(
        title: Text(roomTitle),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_selectedImage != null) _buildImagePreview(),

          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(
                widget.chatRoomId,
                widget.chatRoomType,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message pour le moment',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
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

          _buildInputArea(isClient),
        ],
      ),
    );
  }

  /// Prévisualisation de l'image sélectionnée
  Widget _buildImagePreview() {
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: CircleAvatar(
              backgroundColor: Colors.red,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () => setState(() => _selectedImage = null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bulle de message
  Widget _buildMessageBubble(Message m, bool isMe) {
    Color bubbleColor;
    Color textColor;

    // Couleurs selon le type de message
    if (m.type == MessageType.question) {
      bubbleColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    } else if (isMe) {
      bubbleColor = Colors.orange;
      textColor = Colors.white;
    } else {
      bubbleColor = Colors.blueGrey.shade100;
      textColor = Colors.black;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(15),
          border: m.type == MessageType.question
              ? Border.all(color: Colors.red.shade300, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom de l'expéditeur
            if (!isMe)
              Row(
                children: [
                  Text(
                    m.senderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  if (m.type == MessageType.question) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.priority_high,
                      size: 14,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            if (!isMe) const SizedBox(height: 5),

            // Photo si présente
            if (m.photoUrl != null && m.photoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  m.photoUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: 200,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              ),
              if (m.text.isNotEmpty && m.text != '📷 Photo')
                const SizedBox(height: 8),
            ],

            // Texte du message
            if (m.text.isNotEmpty && m.text != '📷 Photo')
              Text(m.text, style: TextStyle(color: textColor, fontSize: 14)),

            // Heure
            const SizedBox(height: 5),
            Text(
              _formatTime(m.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zone de saisie avec boutons
  Widget _buildInputArea(bool isClient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton photo
          IconButton(
            icon: const Icon(Icons.photo, color: Colors.blue),
            onPressed: _isUploading ? null : _showImageSourceDialog,
          ),

          // Champ de texte
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: _selectedImage != null
                    ? 'Légende (optionnel)...'
                    : 'Écrire un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
            ),
          ),

          const SizedBox(width: 8),

          // Bouton question (client uniquement)
          if (isClient)
            IconButton(
              icon: const Icon(Icons.priority_high, color: Colors.red),
              tooltip: 'Question urgente',
              onPressed: _isUploading
                  ? null
                  : () => _send(type: MessageType.question),
            ),

          // Bouton envoi
          _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(
                    _selectedImage != null ? Icons.send : Icons.send,
                    color: Colors.orange,
                  ),
                  onPressed: () => _send(
                    type: _selectedImage != null
                        ? MessageType.photo
                        : MessageType.text,
                  ),
                ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
