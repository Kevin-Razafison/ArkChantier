import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/chantier_model.dart';
import '../../models/report_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/photo_reporter.dart';
import 'dart:io';

class ForemanIncidentView extends StatefulWidget {
  final Chantier chantier;
  const ForemanIncidentView({super.key, required this.chantier});

  @override
  State<ForemanIncidentView> createState() => _ForemanIncidentViewState();
}

class _ForemanIncidentViewState extends State<ForemanIncidentView> {
  List<Report> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    final all = await DataStorage.loadReports(widget.chantier.id);
    if (mounted) {
      setState(() {
        _incidents = all.where((r) => r.isIncident).toList();
        _isLoading = false;
      });
    }
  }

  void _showAddIncidentDialog(bool isDark) {
    final TextEditingController descController = TextEditingController();
    String priority = "Moyenne";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A334D) : Colors.white,
      builder: (context) => StatefulBuilder(
        // Ajout de StatefulBuilder pour le dropdown
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SizedBox(
            height: 550,
            child: Column(
              children: [
                Text(
                  "SIGNALER UN INCIDENT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.orangeAccent
                        : const Color(0xFF1A334D),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Description du problème",
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "Priorité : ",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                      value: priority,
                      dropdownColor: isDark
                          ? const Color(0xFF1A334D)
                          : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.orangeAccent : Colors.orange,
                      ),
                      items: ["Basse", "Moyenne", "Haute"]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setModalState(() => priority = v!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Prenez une photo du problème :",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PhotoReporter(
                    onImageSaved: (path) async {
                      final rep = Report(
                        id: const Uuid().v4(),
                        chantierId: widget.chantier.id,
                        comment: descController.text,
                        imagePath: path,
                        date: DateTime.now(),
                        isIncident: true,
                        priority: priority,
                      );

                      List<Report> all = await DataStorage.loadReports(
                        widget.chantier.id,
                      );
                      all.add(rep);
                      await DataStorage.saveReports(widget.chantier.id, all);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _loadIncidents();
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIncidentDetail(Report incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Détail Incident - ${incident.priority}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(incident.imagePath),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
            Text(incident.comment, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FERMER"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.orange.withValues(alpha: 0.05),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    title: Text(
                      "JOURNAL DES INCIDENTS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A334D),
                      ),
                    ),
                    subtitle: Text(
                      "Signalez tout retard ou problème technique.",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _incidents.isEmpty
                      ? const Center(child: Text("Aucun incident signalé"))
                      : ListView.separated(
                          itemCount: _incidents.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) =>
                              _buildIncidentTile(_incidents[i], isDark),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddIncidentDialog(isDark),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildIncidentTile(Report incident, bool isDark) {
    // Couleur d'icône selon la priorité
    Color priorityColor;
    switch (incident.priority) {
      case "Haute":
        priorityColor = Colors.red;
        break;
      case "Moyenne":
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return ListTile(
      leading: Icon(Icons.error_outline, color: priorityColor),
      title: Text(
        incident.comment,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        "Priorité: ${incident.priority} • ${incident.date.day}/${incident.date.month}/${incident.date.year}",
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: () {
        _showIncidentDetail(incident);
      },
    );
  }
}
