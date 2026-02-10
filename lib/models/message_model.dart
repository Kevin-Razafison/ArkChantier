import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, photo, question }

enum ChatRoomType { projet, chantier }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String chatRoomId; // Remplace chantierId
  final ChatRoomType chatRoomType;
  final MessageType type;
  final String? photoUrl;
  final String? photoPath;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.chatRoomId, // Changé
    required this.chatRoomType,
    this.type = MessageType.text,
    this.photoUrl,
    this.photoPath,
    this.isRead = false,
  });

  // Pour compatibilité avec l'ancien code
  String get chantierId {
    if (chatRoomType == ChatRoomType.chantier) {
      return chatRoomId;
    }
    return ''; // Retourne vide pour les salons projet
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'chatRoomId': chatRoomId,
      'chatRoomType': chatRoomType.name,
      'type': type.name,
      'photoUrl': photoUrl,
      'photoPath': photoPath,
      'isRead': isRead,
    };
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Résolution du type de message
    MessageType messageType = MessageType.text;
    if (data['type'] != null) {
      try {
        messageType = MessageType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => MessageType.text,
        );
      } catch (e) {
        messageType = MessageType.text;
      }
    }

    // Résolution du type de salon
    ChatRoomType roomType = ChatRoomType.chantier;
    if (data['chatRoomType'] != null) {
      try {
        roomType = ChatRoomType.values.firstWhere(
          (e) => e.name == data['chatRoomType'],
          orElse: () => ChatRoomType.chantier,
        );
      } catch (e) {
        roomType = ChatRoomType.chantier;
      }
    }

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Inconnu',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      chatRoomId:
          data['chatRoomId'] ??
          (data['chantierId'] ?? ''), // Support ancien format
      chatRoomType: roomType,
      type: messageType,
      photoUrl: data['photoUrl'],
      photoPath: data['photoPath'],
      isRead: data['isRead'] ?? false,
    );
  }

  // Copie avec modifications
  Message copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    String? chatRoomId,
    ChatRoomType? chatRoomType,
    MessageType? type,
    String? photoUrl,
    String? photoPath,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      chatRoomType: chatRoomType ?? this.chatRoomType,
      type: type ?? this.type,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      isRead: isRead ?? this.isRead,
    );
  }
}
