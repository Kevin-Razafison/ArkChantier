import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import 'dart:io';

class IncidentList extends StatelessWidget {
  final List<Incident> incidents;

  const IncidentList({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return const Center(
        child: Text(
          "RAS - Aucun incident",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return Column(
      children: incidents
          .map((incident) => _buildIncidentTile(incident))
          .toList(),
    );
  }

  Widget _buildIncidentTile(Incident incident) {
    Color priorityColor = Colors.green;
    if (incident.priorite == Priorite.haute) priorityColor = Colors.orange;
    if (incident.priorite == Priorite.critique) priorityColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  incident.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "${incident.date.day}/${incident.date.month}",
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
          if (incident.imagePath != null && incident.imagePath!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(incident.imagePath!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
