import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

class FinancialStatsCard extends StatelessWidget {
  /// L'objet chantier est désormais requis pour afficher des données réelles
  final Chantier chantier; 

  const FinancialStatsCard({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calcul dynamique du ratio (Dépenses / Budget)
    double ratio = chantier.budgetInitial > 0 
        ? (chantier.depensesActuelles / chantier.budgetInitial) 
        : 0.0;
    
    // Calcul du pourcentage pour l'affichage textuel
    int pourcentage = (ratio * 100).toInt();

    // Calcul du reste à dépenser (peut être négatif en cas de dépassement)
    double reste = chantier.budgetInitial - chantier.depensesActuelles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne Budget Total
        _buildStatRow(
          context, 
          "Budget Total", 
          "${chantier.budgetInitial.toStringAsFixed(0)} €", 
          Colors.blue
        ),
        const SizedBox(height: 15),
        
        // Ligne Dépenses Actuelles (la couleur change si on dépasse)
        _buildStatRow(
          context, 
          "Dépenses Actuelles", 
          "${chantier.depensesActuelles.toStringAsFixed(0)} €", 
          _getBudgetColor(ratio)
        ),
        const SizedBox(height: 20),
        
        // Label de pourcentage
        Text(
          "Utilisation du budget : $pourcentage%",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Barre de progression visuelle
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio > 1.0 ? 1.0 : ratio, // On sature à 1 pour éviter les erreurs graphiques
            minHeight: 12,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_getBudgetColor(ratio)),
          ),
        ),
        
        const Spacer(),
        
        // Pied de carte avec les indicateurs rapides
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat(
              context, 
              "Reste à dépenser", 
              "${reste.toStringAsFixed(0)} €", 
              reste < 0 ? Colors.red : (isDark ? Colors.white70 : Colors.black54)
            ),
            _miniStat(
              context, 
              "État du budget", 
              ratio > 1.0 ? "Dépassement" : (ratio > 0.8 ? "Alerte" : "Correct"), 
              _getBudgetColor(ratio)
            ),
          ],
        )
      ],
    );
  }

  /// Détermine la couleur en fonction de la consommation du budget
  /// Vert < 80% | Orange 80-100% | Rouge > 100%
  Color _getBudgetColor(double ratio) {
    if (ratio >= 1.0) return Colors.red;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.green;
  }

  /// Helper pour les lignes principales (Label : Valeur)
  Widget _buildStatRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  /// Helper pour les petites statistiques en bas de carte
  Widget _miniStat(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}