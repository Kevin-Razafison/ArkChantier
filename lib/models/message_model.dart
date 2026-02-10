import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text, // Message texte normal
  photo, // Message avec photo
  question, // Question du client (prioritaire)
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String chantierId;
  final MessageType type;
  final String? photoUrl; // URL Firebase Storage
  final String? photoPath; // Chemin local
  final bool isRead; // Pour marquer les questions comme lues

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.chantierId,
    this.type = MessageType.text,
    this.photoUrl,
    this.photoPath,
    this.isRead = false,
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'chantierId': chantierId,
      'type': type.name,
      'photoUrl': photoUrl,
      'photoPath': photoPath,
      'isRead': isRead,
    };
  }

  // Création depuis Firestore
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

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Inconnu',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      chantierId: data['chantierId'] ?? '',
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
    String? chantierId,
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
      chantierId: chantierId ?? this.chantierId,
      type: type ?? this.type,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      isRead: isRead ?? this.isRead,
    );
  }
}
