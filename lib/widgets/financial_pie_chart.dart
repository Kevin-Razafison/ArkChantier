import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FinancialPieChart extends StatefulWidget {
  final double montantMO; // Main d'œuvre
  final double montantMat; // Matériel
  final String devise;

  const FinancialPieChart({
    super.key,
    required this.montantMO,
    required this.montantMat,
    this.devise = '€',
  });

  @override
  State<FinancialPieChart> createState() => _FinancialPieChartState();
}

class _FinancialPieChartState extends State<FinancialPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    double total = widget.montantMO + widget.montantMat;

    // Cas où il n'y a pas encore de dépenses
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Aucune dépense enregistrée",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Les dépenses apparaîtront ici",
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                "Répartition des dépenses",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Graphique
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: _buildSections(total),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Légendes enrichies
        _buildEnhancedLegends(total),

        const SizedBox(height: 10),

        // Total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL DES DÉPENSES",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                "${total.toStringAsFixed(2)} ${widget.devise}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A334D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final moPercentage = (widget.montantMO / total) * 100;
    final matPercentage = (widget.montantMat / total) * 100;

    return [
      PieChartSectionData(
        color: Colors.blue,
        value: widget.montantMO,
        title: touchedIndex == 0
            ? '${moPercentage.toStringAsFixed(1)}%'
            : '${moPercentage.toInt()}%',
        radius: touchedIndex == 0 ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 0 ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: touchedIndex == 0
            ? _buildBadge(Icons.people, Colors.blue)
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: widget.montantMat,
        title: touchedIndex == 1
            ? '${matPercentage.toStringAsFixed(1)}%'
            : '${matPercentage.toInt()}%',
        radius: touchedIndex == 1 ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: touchedIndex == 1 ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: touchedIndex == 1
            ? _buildBadge(Icons.build, Colors.orange)
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
    ];
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEnhancedLegends(double total) {
    return Column(
      children: [
        _buildLegendItem(
          "Main d'œuvre",
          Colors.blue,
          widget.montantMO,
          total,
          Icons.people,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          "Matériel",
          Colors.orange,
          widget.montantMat,
          total,
          Icons.build,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    String text,
    Color color,
    double montant,
    double total,
    IconData icon,
  ) {
    final percentage = total > 0 ? (montant / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${montant.toStringAsFixed(2)} ${widget.devise}",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${percentage.toStringAsFixed(1)}%",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
