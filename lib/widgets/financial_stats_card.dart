import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

class FinancialStatsCard extends StatelessWidget {
  final Chantier chantier;

  const FinancialStatsCard({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calcul du ratio Budget / Dépenses
    double ratio = chantier.budgetInitial > 0
        ? (chantier.depensesActuelles / chantier.budgetInitial)
        : 0.0;

    int pourcentage = (ratio * 100).toInt();
    double reste = chantier.budgetInitial - chantier.depensesActuelles;
    Color budgetColor = _getBudgetColor(ratio);

    return SizedBox(
      height: 300, // On définit une limite
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec Nom du Chantier et Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  chantier.nom.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(ratio),
            ],
          ),
          const SizedBox(height: 15),

          // Valeurs principales
          _buildStatRow(
            context,
            "Budget Initial",
            "${chantier.budgetInitial.toStringAsFixed(0)} €",
            isDark ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            "Dépenses Réelles",
            "${chantier.depensesActuelles.toStringAsFixed(0)} €",
            budgetColor,
          ),
          const SizedBox(height: 15),

          // Consommation et Icône d'alerte
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Consommation du budget : $pourcentage%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: budgetColor,
                ),
              ),
              if (ratio >= 0.8)
                Icon(
                  ratio >= 1.0
                      ? Icons.error_outline
                      : Icons.warning_amber_rounded,
                  color: budgetColor,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Barre de progression visuelle
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio.clamp(
                0.0,
                1.0,
              ), // On bloque à 1.0 pour l'affichage visuel
              minHeight: 12,
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
            ),
          ),

          const Spacer(),

          // Pied de carte : Reste à investir / Santé
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat(
                  context,
                  reste < 0 ? "Dépassement" : "Reste à investir",
                  "${reste.abs().toStringAsFixed(0)} €",
                  reste < 0 ? Colors.red : Colors.green,
                ),
                _miniStat(
                  context,
                  "Santé Financière",
                  _getHealthLabel(ratio),
                  budgetColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE DE COULEUR ---
  Color _getBudgetColor(double ratio) {
    if (ratio >= 1.0) return Colors.red;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.green;
  }

  // --- ÉTIQUETTE DE SANTÉ ---
  String _getHealthLabel(double ratio) {
    if (ratio >= 1.0) return "CRITIQUE";
    if (ratio >= 0.8) return "VIGILANCE";
    return "OPTIMALE";
  }

  // --- BADGE DE STATUT ---
  Widget _buildStatusBadge(double ratio) {
    Color color = _getBudgetColor(ratio);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        ratio >= 1.0 ? "OVER-BUDGET" : (ratio >= 0.8 ? "WARNING" : "OK"),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
