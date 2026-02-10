import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../widgets/info_card.dart';
import '../../widgets/weather_banner.dart';

class ClientDashboardView extends StatelessWidget {
  final UserModel user;
  final Projet projet;

  const ClientDashboardView({
    super.key,
    required this.user,
    required this.projet,
  });

  @override
  Widget build(BuildContext context) {
    Chantier? chantier;

    if (projet.chantiers.isNotEmpty) {
      // Chercher le chantier assigné au client
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

    // Si pas de chantier disponible, afficher un message
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
          // 1. Bienvenue & Météo (avec gestion d'erreur)
          // ✅ CORRECTION : Météo désactivée si pas de coordonnées valides
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

          // 2. Jauge de progression (Visuelle et rassurante)
          _buildProgressCard(chantier),

          const SizedBox(height: 20),

          // 3. Section Infos & Contact
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  context,
                  Icons.chat_bubble_outline,
                  "Poser une\nquestion",
                  Colors.blue,
                  () {
                    // Navigation vers le chat
                    // La navigation sera gérée par le parent Shell
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickAction(
                  context,
                  Icons.photo_library_outlined,
                  "Voir les\nphotos",
                  Colors.orange,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Fonctionnalité bientôt disponible"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4. Budget (Transparence)
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
                // ✅ CORRECTION : Protection contre division par zéro
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
                  // ✅ CORRECTION : Clamp la progression entre 0 et 1
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
