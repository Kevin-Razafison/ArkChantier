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
    // On récupère le chantier lié au client
    final chantier = projet.chantiers.firstWhere(
      (c) => c.id == user.assignedId,
      orElse: () => projet.chantiers.first,
    );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Bienvenue & Météo
          WeatherBanner(
            city: chantier.lieu,
            lat: chantier.latitude,
            lon: chantier.longitude,
          ),
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
                    /* La logique de navigation vers le chat sera gérée par le Shell */
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
                    /* Navigation vers galerie photos */
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
                  "${chantier.budgetInitial} €",
                  Colors.black,
                ),
                const Divider(),
                _buildFinanceRow(
                  "Consommé",
                  "${chantier.depensesActuelles} €",
                  Colors.red,
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: chantier.depensesActuelles / chantier.budgetInitial,
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
                  value: c.progression,
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
}
