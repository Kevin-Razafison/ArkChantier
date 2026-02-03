import 'package:flutter/material.dart';
import '../models/ouvrier_model.dart';
import '../models/projet_model.dart';
import '../models/user_model.dart';
import '../data/mock_data.dart';
import '../services/data_storage.dart';
import 'ouvrier_detail_screen.dart';

class OuvriersScreen extends StatefulWidget {
  final Projet projet;
  final UserModel user;

  const OuvriersScreen({super.key, required this.projet, required this.user});

  @override
  State<OuvriersScreen> createState() => _OuvriersScreenState();
}

class _OuvriersScreenState extends State<OuvriersScreen> {
  List<Ouvrier> _filteredOuvriers = [];
  final TextEditingController _searchController = TextEditingController();
  final String _today = DateTime.now().toIso8601String().split('T')[0];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // On charge l'équipe spécifique au projet actuel
    final savedOuvriers = await DataStorage.loadTeam("annuaire_global");
    if (mounted) {
      setState(() {
        if (savedOuvriers.isNotEmpty) {
          globalOuvriers = savedOuvriers;
        }
        _filteredOuvriers = globalOuvriers;
      });
    }
  }

  void _filterOuvriers(String query) {
    setState(() {
      _filteredOuvriers = globalOuvriers
          .where(
            (o) =>
                o.nom.toLowerCase().contains(query.toLowerCase()) ||
                o.specialite.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // FONCTION DE POINTAGE RAPIDE
  Future<void> _togglePointage(Ouvrier worker) async {
    setState(() {
      if (worker.joursPointes.contains(_today)) {
        worker.joursPointes.remove(_today);
      } else {
        worker.joursPointes.add(_today);
      }
    });
    await DataStorage.saveTeam("annuaire_global", globalOuvriers);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool canEdit = widget.user.role != UserRole.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion de l'Équipe"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeaderInfo(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOuvriers,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: _filteredOuvriers.isEmpty
                ? const Center(child: Text("Aucun ouvrier sur ce projet"))
                : ListView.builder(
                    itemCount: _filteredOuvriers.length,
                    itemBuilder: (context, index) {
                      final worker = _filteredOuvriers[index];
                      if (!canEdit)
                        return _buildWorkerCard(worker, isDark, false);

                      return Dismissible(
                        key: Key(worker.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          globalOuvriers.remove(worker);
                          await DataStorage.saveTeam(
                            "annuaire_global",
                            globalOuvriers,
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _buildWorkerCard(worker, isDark, true),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: _showAddWorkerDialog,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            "Pointage du : $_today",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Ouvrier worker, bool isDark, bool canEdit) {
    bool isPresent = worker.joursPointes.contains(_today);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Hero(
          tag: "avatar-${worker.id}",
          child: CircleAvatar(
            backgroundColor: isPresent ? Colors.green : Colors.blueGrey,
            child: isPresent
                ? const Icon(Icons.check, color: Colors.white)
                : Text(
                    worker.nom[0],
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ),
        title: Text(
          worker.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(worker.specialite),
        trailing: canEdit
            ? IconButton(
                icon: Icon(
                  isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isPresent ? Colors.green : Colors.grey,
                ),
                onPressed: () => _togglePointage(worker),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OuvrierDetailScreen(worker: worker),
          ),
        ),
      ),
    );
  }

  // --- TON CODE DE DIALOGUE RESTE LE MÊME ---
  void _showAddWorkerDialog() {
    final nomController = TextEditingController();
    final specController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ajouter un ouvrier"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: specController,
              decoration: const InputDecoration(labelText: "Métier"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                final n = Ouvrier(
                  id: DateTime.now().toString(),
                  nom: nomController.text,
                  specialite: specController.text,
                  telephone: "",
                  salaireJournalier: 50.0,
                  joursPointes: [],
                );
                setState(() => globalOuvriers.add(n));
                await DataStorage.saveTeam("annuaire_global", globalOuvriers);
                Navigator.pop(ctx);
              }
            },
            child: const Text("AJOUTER"),
          ),
        ],
      ),
    );
  }
}
