import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/chantier_model.dart';
import '../../models/report_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/photo_reporter.dart';

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

  void _showAddIncidentDialog() {
    final TextEditingController descController = TextEditingController();
    String priority = "Moyenne";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 500,
          child: Column(
            children: [
              const Text(
                "SIGNALER UN INCIDENT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: "Description du problème",
                ),
              ),
              DropdownButton<String>(
                value: priority,
                items: ["Basse", "Moyenne", "Haute"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => priority = v!,
              ),
              const Text(
                "Prenez une photo du problème :",
                style: TextStyle(fontSize: 12),
              ),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ListTile(
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  title: Text(
                    "JOURNAL DES INCIDENTS",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Signalez tout retard ou problème technique."),
                ),
                const Divider(),
                Expanded(
                  child: _incidents.isEmpty
                      ? const Center(child: Text("Aucun incident signalé"))
                      : ListView.builder(
                          itemCount: _incidents.length,
                          itemBuilder: (context, i) => ListTile(
                            leading: const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            title: Text(_incidents[i].comment),
                            subtitle: Text(
                              "Priorité: ${_incidents[i].priority} - ${_incidents[i].date.toString().substring(0, 10)}",
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _showAddIncidentDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
