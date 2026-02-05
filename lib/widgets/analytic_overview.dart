import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../models/projet_model.dart';

class AnalyticsOverview extends StatelessWidget {
  final Chantier chantier;
  final Projet projet;

  const AnalyticsOverview({
    super.key,
    required this.chantier,
    required this.projet,
  });

  @override
  Widget build(BuildContext context) {
    // ANALYTICS : Calcul de la santé réelle
    // Si progrès < budget consommé = on dépasse le budget prévu pour cet état d'avancement
    double performanceIndex =
        chantier.progression - chantier.budgetConsommePercent;
    bool isOverBudget = performanceIndex < -0.05; // Marge de 5% tolérée

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "SANTÉ FINANCIÈRE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                // Badge Analytics
                _buildHealthBadge(performanceIndex),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCircle(
                  "Travaux réalisés",
                  chantier.progression,
                  Colors.blue,
                ),
                _buildStatCircle(
                  "Budget consommé",
                  chantier.budgetConsommePercent,
                  isOverBudget ? Colors.red : Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            _buildLinearInfo(
              "Dépenses réelles",
              "${chantier.depensesActuelles.toInt()} ${projet.devise}",
              color: isOverBudget ? Colors.red : null,
            ),
            _buildLinearInfo(
              "Reste à dépenser",
              "${(chantier.budgetInitial - chantier.depensesActuelles).toInt()} ${projet.devise}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBadge(double index) {
    String text = index >= 0 ? "OPTIMISÉ" : "DÉRIVE";
    Color color = index >= 0 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ... tes méthodes _buildStatCircle et _buildLinearInfo (ajoute un paramètre color optionnel)
  Widget _buildLinearInfo(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 65,
              width: 65,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
        ),
      ],
    );
  }
}
