import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FinancialPieChart extends StatelessWidget {
  final double montantMO; // Main d'œuvre
  final double montantMat; // Matériel

  const FinancialPieChart({
    super.key, 
    required this.montantMO, 
    required this.montantMat
  });

  @override
  Widget build(BuildContext context) {
    double total = montantMO + montantMat;
    
    // Cas où il n'y a pas encore de dépenses
    if (total == 0) {
      return const Center(child: Text("Aucune dépense enregistrée"));
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: Colors.blue,
                  value: montantMO,
                  title: '${((montantMO / total) * 100).toInt()}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                PieChartSectionData(
                  color: Colors.orange,
                  value: montantMat,
                  title: '${((montantMat / total) * 100).toInt()}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Légende simple
        _buildLegend("Main d'œuvre", Colors.blue),
        _buildLegend("Matériel", Colors.orange),
      ],
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}