import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String chantierId;
  final String? imageUrl; // Optionnel : pour envoyer des photos de chantier

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.chantierId,
    this.imageUrl,
  });

  // Convertit un document Firestore en objet Message
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    final dynamic timestamp = data['timestamp'];
    DateTime dateValue = DateTime.now();

    if (timestamp != null && timestamp is Timestamp) {
      dateValue = timestamp.toDate();
    }

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonyme',
      text: data['text'] ?? '',
      timestamp: dateValue,
      chantierId: data['chantierId'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }
  // Convertit l'objet Message en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp':
          FieldValue.serverTimestamp(), // Heure du serveur pour éviter les triches
      'chantierId': chantierId,
      'imageUrl': imageUrl,
    };
  }
}
