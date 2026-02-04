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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SANTÉ FINANCIÈRE",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCircle("Progrès", chantier.progression, Colors.blue),
                _buildStatCircle(
                  "Budget",
                  chantier.budgetConsommePercent,
                  chantier.healthColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLinearInfo(
              "Dépenses",
              "${chantier.depensesActuelles} ${projet.devise} / ${chantier.budgetInitial}${projet.devise}",
            ),
          ],
        ),
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
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              "${(value * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildLinearInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
