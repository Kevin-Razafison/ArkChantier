import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../chat_screen.dart';

/// 🎯 HUB DE CHAT POUR L'ADMIN
/// Permet de choisir entre :
/// - Room Projet (Admin ↔️ Client)
/// - Rooms Chantier (Admin ↔️ Chef ↔️ Ouvriers) - une par chantier
class AdminChatHub extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const AdminChatHub({super.key, required this.user, required this.projet});

  @override
  State<AdminChatHub> createState() => _AdminChatHubState();
}

class _AdminChatHubState extends State<AdminChatHub> {
  final ChatService _chatService = ChatService();
  String? _selectedRoomId;
  ChatRoomType? _selectedRoomType;

  @override
  Widget build(BuildContext context) {
    // Si une room est sélectionnée, afficher le chat
    if (_selectedRoomId != null && _selectedRoomType != null) {
      return _buildChatScreen();
    }

    // Sinon, afficher le sélecteur de rooms
    return _buildRoomSelector();
  }

  /// 💬 Écran de chat avec bouton retour
  Widget _buildChatScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoomTitle()),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedRoomId = null;
              _selectedRoomType = null;
            });
          },
        ),
      ),
      body: ChatScreen(
        chatRoomId: _selectedRoomId!,
        chatRoomType: _selectedRoomType!,
        currentUser: widget.user,
      ),
    );
  }

  /// 📋 Sélecteur de rooms
  Widget _buildRoomSelector() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DISCUSSIONS'),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Sélectionnez une conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // 🟢 ROOM PROJET - Admin ↔️ Client
          _buildRoomCard(
            title: '💼 Discussion Client',
            subtitle: 'Communication avec le client du projet',
            icon: Icons.business_center,
            color: Colors.blue,
            roomId: widget.projet.id,
            roomType: ChatRoomType.projet,
            participants: 'Vous ↔️ Client',
          ),

          const SizedBox(height: 16),

          // 📌 Section Chantiers
          if (widget.projet.chantiers.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '🏗️ DISCUSSIONS PAR CHANTIER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            // 🟠 ROOMS CHANTIER - Admin ↔️ Chef ↔️ Ouvriers
            ...widget.projet.chantiers.map((chantier) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRoomCard(
                  title: chantier.nom,
                  subtitle: chantier.lieu,
                  icon: Icons.construction,
                  color: Colors.orange,
                  roomId: chantier.id,
                  roomType: ChatRoomType.chantier,
                  participants: 'Vous ↔️ Chef de chantier ↔️ Ouvriers',
                ),
              );
            }),
          ],

          // Message si aucun chantier
          if (widget.projet.chantiers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Aucun chantier créé pour ce projet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 🎴 Carte de room avec badge de messages non lus
  Widget _buildRoomCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String roomId,
    required ChatRoomType roomType,
    required String participants,
  }) {
    return StreamBuilder<int>(
      stream: _chatService.getUnreadCount(widget.user.id, roomId, roomType),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedRoomId = roomId;
                _selectedRoomType = roomType;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),

                  const SizedBox(width: 16),

                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Badge non lus
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          participants,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flèche
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Titre de la room actuellement ouverte
  String _getRoomTitle() {
    if (_selectedRoomType == ChatRoomType.projet) {
      return '💼 Discussion Client';
    } else {
      // Trouver le chantier correspondant
      final chantier = widget.projet.chantiers.firstWhere(
        (c) => c.id == _selectedRoomId,
        orElse: () => Chantier(
          id: '',
          nom: 'Chantier',
          lieu: '',
          progression: 0,
          statut: StatutChantier.enCours,
        ),
      );
      return '🏗️ ${chantier.nom}';
    }
  }
}
