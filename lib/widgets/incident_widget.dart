import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

class IncidentList extends StatelessWidget {
  final List<Incident> incidents;

  const IncidentList({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            "Aucun incident signalé",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true, // ← CRITICAL FIX: Let ListView size itself
      physics:
          const NeverScrollableScrollPhysics(), // ← Disable internal scrolling
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: incidents.length > 3 ? 3 : incidents.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return ListTile(
          dense: true,
          leading: Icon(
            Icons.warning_amber_rounded,
            color: _getPriorityColor(incident.priorite),
            size: 20,
          ),
          title: Text(
            incident.titre,
            style: const TextStyle(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            incident.description,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor(
                incident.priorite,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              incident.priorite.name.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _getPriorityColor(incident.priorite),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(Priorite priorite) {
    switch (priorite) {
      case Priorite.critique:
        return Colors.red;
      case Priorite.haute:
        return Colors.orange;
      case Priorite.moyenne:
        return Colors.amber;
      case Priorite.basse:
        return Colors.blue;
    }
  }
}

// Alternative simpler widget if you just want a summary
class IncidentSummary extends StatelessWidget {
  final List<Incident> incidents;

  const IncidentSummary({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    final critiques = incidents
        .where((i) => i.priorite == Priorite.critique)
        .length;
    final hautes = incidents.where((i) => i.priorite == Priorite.haute).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat("Critiques", critiques, Colors.red),
        _buildStat("Hautes", hautes, Colors.orange),
        _buildStat("Total", incidents.length, Colors.blueGrey),
      ],
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
