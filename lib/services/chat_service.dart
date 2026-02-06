import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupérer les messages d'un chantier en temps réel
  Stream<List<Message>> getMessages(String chantierId) {
    return _db
        .collection('chats')
        .doc(chantierId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Plus récent en bas
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  // Envoyer un message
  Future<void> sendMessage(String chantierId, Message message) async {
    await _db
        .collection('chats')
        .doc(chantierId)
        .collection('messages')
        .add(message.toMap());
  }
}
