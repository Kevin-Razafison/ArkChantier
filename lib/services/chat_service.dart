import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Récupérer les messages d'un salon spécifique
  Stream<List<Message>> getMessages(String chatRoomId, ChatRoomType roomType) {
    return _db
        .collection('chats')
        .doc(
          '${roomType.name}_$chatRoomId',
        ) // Format: "projet_XXX" ou "chantier_XXX"
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  // Envoyer un message
  Future<void> sendMessage(Message message) async {
    await _db
        .collection('chats')
        .doc('${message.chatRoomType.name}_${message.chatRoomId}')
        .collection('messages')
        .add(message.toMap());
  }

  // NOUVEAU: Vérifier les messages non lus (pour notifications)
  Stream<int> getUnreadCount(
    String userId,
    String chatRoomId,
    ChatRoomType roomType,
  ) {
    return _db
        .collection('chats')
        .doc('${roomType.name}_$chatRoomId')
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
