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
    try {
      final all = await DataStorage.loadReports(widget.chantier.id);
      if (mounted) {
        setState(() {
          _incidents = all.where((r) => r.isIncident).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement incidents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ FIX MAJEUR: Modal sans overflow
  void _showAddIncidentDialog(bool isDark) {
    final TextEditingController descController = TextEditingController();
    String priority = "Moyenne";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ CRITIQUE
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A334D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // ✅ FIX: Padding dynamique
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          // ✅ Hauteur maximum dynamique
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  "SIGNALER UN INCIDENT",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark
                        ? Colors.orangeAccent
                        : const Color(0xFF1A334D),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Description du problème",
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // Dropdown priorité
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Priorité : ",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: priority,
                        underline: const SizedBox(),
                        dropdownColor: isDark
                            ? const Color(0xFF1A334D)
                            : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.orangeAccent : Colors.orange,
                          fontWeight: FontWeight.bold,
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
                ),
                const SizedBox(height: 16),

                Text(
                  "Prenez une photo du problème :",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ PhotoReporter avec hauteur fixe
                SizedBox(
                  height: 200,
                  child: PhotoReporter(
                    onImageSaved: (path) async {
                      // ✅ Validation
                      if (descController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La description est obligatoire'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final rep = Report(
                        id: const Uuid().v4(),
                        chantierId: widget.chantier.id,
                        comment: descController.text.trim(),
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

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incident signalé'),
                          backgroundColor: Colors.green,
                        ),
                      );
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(incident.imagePath),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 15),
              Text(incident.comment, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text(
                "Date: ${incident.date.day}/${incident.date.month}/${incident.date.year}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 80,
                                color: Colors.green.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Aucun incident signalé",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
