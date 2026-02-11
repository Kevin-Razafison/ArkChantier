import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../models/message_model.dart';
import '../../widgets/info_card.dart';
import '../../widgets/weather_banner.dart';
import '../../services/chat_service.dart';
import '../chat_screen.dart';

class ClientDashboardView extends StatefulWidget {
  final UserModel user;
  final Projet projet;
  final Function(int)? onNavigate;

  const ClientDashboardView({
    super.key,
    required this.user,
    required this.projet,
    this.onNavigate,
  });

  @override
  State<ClientDashboardView> createState() => _ClientDashboardViewState();
}

class _ClientDashboardViewState extends State<ClientDashboardView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Chantier? chantier;

    if (widget.projet.chantiers.isNotEmpty) {
      try {
        chantier = widget.projet.chantiers.firstWhere(
          (c) => c.id == widget.user.assignedId,
          orElse: () => widget.projet.chantiers.first,
        );
      } catch (e) {
        debugPrint('⚠️ Erreur récupération chantier: $e');
        chantier = widget.projet.chantiers.first;
      }
    }

    if (chantier == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 100, color: Colors.grey[300]),
              const SizedBox(height: 24),
              const Text(
                "Aucun chantier assigné",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Contactez votre chef de projet",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(1);
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contacter l\'admin'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Météo
              if (chantier.latitude != 0.0 && chantier.longitude != 0.0)
                WeatherBanner(
                  city: chantier.lieu,
                  lat: chantier.latitude,
                  lon: chantier.longitude,
                ),
              if (chantier.latitude != 0.0 && chantier.longitude != 0.0)
                const SizedBox(height: 20),

              // En-tête avec nom utilisateur
              _buildHeader(),
              const SizedBox(height: 24),

              // Carte de progression
              _buildProgressCard(chantier),
              const SizedBox(height: 20),

              // Actions rapides
              _buildQuickActions(chantier),
              const SizedBox(height: 20),

              // Informations du projet
              _buildProjectInfo(chantier),
              const SizedBox(height: 20),

              // Budget
              _buildBudgetCard(chantier),
              const SizedBox(height: 20),

              // Statut du chantier
              _buildStatusCard(chantier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              radius: 28,
              child: const Icon(Icons.person, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour ${widget.user.nom} 👋",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Voici l'état d'avancement de votre projet",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(Chantier c) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A334D), const Color(0xFF2A4A6D)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              "PROGRESSION DU CHANTIER",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: c.progression.clamp(0.0, 1.0),
                    strokeWidth: 12,
                    color: _getProgressColor(c.progression),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${(c.progression * 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Réalisé",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(c.statut).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(c.statut).withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _getStatutLabel(c.statut),
                style: TextStyle(
                  color: _getStatusColor(c.statut),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Chantier chantier) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            context,
            Icons.chat_bubble_outline,
            "Poser une\nquestion",
            Colors.blue,
            () => _askQuestion(context, chantier),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            context,
            Icons.forum_outlined,
            "Voir la\ndiscussion",
            Colors.green,
            () => _openChat(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            context,
            Icons.notifications_outlined,
            "Notifications",
            Colors.orange,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aucune nouvelle notification'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectInfo(Chantier chantier) {
    return InfoCard(
      title: "INFORMATIONS DU PROJET",
      child: Column(
        children: [
          _buildInfoRow(Icons.construction, "Chantier", chantier.nom),
          const Divider(),
          _buildInfoRow(Icons.location_on, "Localisation", chantier.lieu),
          if (chantier.budgetInitial > 0) ...[
            const Divider(),
            _buildInfoRow(Icons.calendar_today, "Date de début", "En cours"),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Chantier chantier) {
    final budgetRatio = chantier.budgetInitial > 0
        ? (chantier.depensesActuelles / chantier.budgetInitial).clamp(0.0, 1.0)
        : 0.0;
    final reste = chantier.budgetInitial - chantier.depensesActuelles;

    return InfoCard(
      title: "RÉSUMÉ FINANCIER",
      child: Column(
        children: [
          _buildFinanceRow(
            "Budget Total",
            "${_formatMoney(chantier.budgetInitial)} ${widget.projet.devise}",
            Colors.black,
          ),
          const SizedBox(height: 8),
          _buildFinanceRow(
            "Consommé",
            "${_formatMoney(chantier.depensesActuelles)} ${widget.projet.devise}",
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildFinanceRow(
            "Reste",
            "${_formatMoney(reste)} ${widget.projet.devise}",
            reste > 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Consommation",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    "${(budgetRatio * 100).toInt()}%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getBudgetColor(budgetRatio),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: budgetRatio,
                  minHeight: 10,
                  color: _getBudgetColor(budgetRatio),
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Chantier chantier) {
    return InfoCard(
      title: "ÉTAT DU CHANTIER",
      child: Column(
        children: [
          _buildStatusItem(
            Icons.engineering,
            "Équipe sur site",
            "Active",
            Colors.green,
          ),
          const Divider(),
          _buildStatusItem(
            Icons.inventory_2,
            "Matériel",
            "Disponible",
            Colors.blue,
          ),
          const Divider(),
          _buildStatusItem(
            Icons.warning_amber_rounded,
            "Incidents",
            "${chantier.incidents.length} signalé(s)",
            chantier.incidents.isEmpty ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
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
        content: SingleChildScrollView(
          child: Column(
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
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              final msg = Message(
                id: '',
                senderId: widget.user.id,
                senderName: widget.user.nom,
                text: questionController.text.trim(),
                timestamp: DateTime.now(),
                chatRoomId: widget.projet.id,
                chatRoomType: ChatRoomType.projet,
                type: MessageType.question,
                isRead: false,
              );

              try {
                final chatService = ChatService();
                await chatService.sendMessage(msg);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Question envoyée au chef de projet'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
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
    if (widget.onNavigate != null) {
      widget.onNavigate!(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: widget.projet.id,
            chatRoomType: ChatRoomType.projet,
            currentUser: widget.user,
          ),
        ),
      );
    }
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
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
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
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

  String _getStatutLabel(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enCours:
        return "EN COURS";
      case StatutChantier.termine:
        return "TERMINÉ";
      case StatutChantier.enRetard:
        return "EN RETARD";
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.blue;
  }

  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enCours:
        return Colors.green;
      case StatutChantier.termine:
        return Colors.blue;
      case StatutChantier.enRetard:
        return Colors.orange;
    }
  }

  Color _getBudgetColor(double ratio) {
    if (ratio >= 1.0) return Colors.red;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.green;
  }
}
