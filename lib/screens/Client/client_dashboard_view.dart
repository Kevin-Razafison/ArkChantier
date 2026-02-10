import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../models/message_model.dart';
import '../../widgets/info_card.dart';
import '../../widgets/weather_banner.dart';
import '../../services/chat_service.dart';
import '../chat_screen.dart';

class ClientDashboardView extends StatelessWidget {
  final UserModel user;
  final Projet projet;
  final Function(int)? onNavigate; // Callback pour naviguer

  const ClientDashboardView({
    super.key,
    required this.user,
    required this.projet,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    Chantier? chantier;

    if (projet.chantiers.isNotEmpty) {
      try {
        chantier = projet.chantiers.firstWhere(
          (c) => c.id == user.assignedId,
          orElse: () => projet.chantiers.first,
        );
      } catch (e) {
        debugPrint('⚠️ Erreur récupération chantier: $e');
        chantier = projet.chantiers.first;
      }
    }

    if (chantier == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                "Aucun chantier assigné",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Contactez votre chef de projet",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Météo
          if (chantier.latitude != 0.0 && chantier.longitude != 0.0)
            WeatherBanner(
              city: chantier.lieu,
              lat: chantier.latitude,
              lon: chantier.longitude,
            ),
          if (chantier.latitude != 0.0 && chantier.longitude != 0.0)
            const SizedBox(height: 25),

          Text(
            "Bonjour ${user.nom},",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text("Voici l'état d'avancement de votre projet."),
          const SizedBox(height: 25),

          // Progression
          _buildProgressCard(chantier),
          const SizedBox(height: 20),

          // Actions rapides - FONCTIONNELLES
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  context,
                  Icons.chat_bubble_outline,
                  "Poser une\nquestion",
                  Colors.blue,
                  () => _askQuestion(context, chantier!),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickAction(
                  context,
                  Icons.forum_outlined,
                  "Voir la\ndiscussion",
                  Colors.green,
                  () => _openChat(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Budget
          InfoCard(
            title: "RÉSUMÉ FINANCIER",
            child: Column(
              children: [
                _buildFinanceRow(
                  "Budget Total",
                  "${_formatMoney(chantier.budgetInitial)} ${projet.devise}",
                  Colors.black,
                ),
                const Divider(),
                _buildFinanceRow(
                  "Consommé",
                  "${_formatMoney(chantier.depensesActuelles)} ${projet.devise}",
                  Colors.red,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: chantier.budgetInitial > 0
                      ? (chantier.depensesActuelles / chantier.budgetInitial)
                            .clamp(0.0, 1.0)
                      : 0.0,
                  color: Colors.redAccent,
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ FONCTION : Poser une question urgente
  void _askQuestion(BuildContext context, Chantier chantier) {
    final TextEditingController questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.priority_high, color: Colors.red),
            SizedBox(width: 10),
            Text('Question Urgente'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre question sera marquée comme prioritaire et le chef de projet sera notifié.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: questionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tapez votre question ici...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ANNULER'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (questionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez écrire une question'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // CORRECTION : Créer le message avec les nouveaux paramètres
              final msg = Message(
                id: '',
                senderId: user.id,
                senderName: user.nom,
                text: questionController.text.trim(),
                timestamp: DateTime.now(),
                chatRoomId: projet.id, // ID du projet pour le chat projet
                chatRoomType: ChatRoomType.projet, // Type de salon projet
                type: MessageType.question,
                isRead: false,
              );

              try {
                // CORRECTION : Utiliser la nouvelle méthode sendMessage
                final chatService = ChatService();
                await chatService.sendMessage(msg);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Question envoyée au chef de projet'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text('ENVOYER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ✅ FONCTION : Ouvrir le chat
  void _openChat(BuildContext context) {
    // Si callback fourni, naviguer vers l'index du chat (1)
    if (onNavigate != null) {
      onNavigate!(1);
    } else {
      // Sinon, ouvrir directement le chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: projet.id,
            chatRoomType: ChatRoomType.projet,
            currentUser: user,
          ),
        ),
      );
    }
  }

  Widget _buildProgressCard(Chantier c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A334D),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            "PROGRESSION",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: c.progression.clamp(0.0, 1.0),
                  strokeWidth: 10,
                  color: Colors.orange,
                  backgroundColor: Colors.white10,
                ),
              ),
              Text(
                "${(c.progression * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            c.statut.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    }
    return amount.toStringAsFixed(0);
  }
}
