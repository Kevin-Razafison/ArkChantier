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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savedOuvriers = await DataStorage.loadTeam("annuaire_global");
    setState(() {
      if (savedOuvriers.isNotEmpty) {
        globalOuvriers = savedOuvriers;
      }
      _filteredOuvriers = globalOuvriers;
    });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Règle de gestion des droits : seul un non-client peut modifier
    final bool canEdit = widget.user.role != UserRole.client;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Annuaire des Ouvriers"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // BARRE DE RECHERCHE
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOuvriers,
              decoration: InputDecoration(
                hintText: "Rechercher un nom ou un métier...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100],
              ),
            ),
          ),

          // LISTE DES OUVRIERS
          Expanded(
            child: _filteredOuvriers.isEmpty
                ? const Center(child: Text("Aucun ouvrier trouvé"))
                : ListView.builder(
                    itemCount: _filteredOuvriers.length,
                    itemBuilder: (context, index) {
                      final worker = _filteredOuvriers[index];

                      // Si l'utilisateur est un client, on retire la possibilité de supprimer au swipe
                      if (!canEdit) {
                        return _buildWorkerCard(worker, isDark);
                      }

                      return Dismissible(
                        key: Key(worker.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          setState(() {
                            globalOuvriers.removeWhere(
                              (o) => o.id == worker.id,
                            );
                            _filterOuvriers(_searchController.text);
                          });
                          await DataStorage.saveTeam(
                            "annuaire_global",
                            globalOuvriers,
                          );

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${worker.nom} supprimé")),
                          );
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _buildWorkerCard(worker, isDark),
                      );
                    },
                  ),
          ),
        ],
      ),
      // BOUTON FLOTTANT : Masqué pour le client
      floatingActionButton: canEdit
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1A334D),
              onPressed: () => _showAddWorkerDialog(),
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  // WIDGET DE LA CARTE (SANS DISMISSIBLE À L'INTÉRIEUR)
  Widget _buildWorkerCard(Ouvrier worker, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Hero(
          tag: "avatar-${worker.id}",
          child: CircleAvatar(
            backgroundColor: isDark
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.blue[50],
            child: Text(
              worker.nom[0],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue[200] : Colors.blue[800],
              ),
            ),
          ),
        ),
        title: Text(
          worker.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(worker.specialite),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OuvrierDetailScreen(worker: worker),
          ),
        ),
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nomController = TextEditingController();
    final specialiteController = TextEditingController();
    final telephoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvel Ouvrier"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: specialiteController,
              decoration: const InputDecoration(labelText: "Spécialité"),
            ),
            TextField(
              controller: telephoneController,
              decoration: const InputDecoration(labelText: "Téléphone"),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                final newWorker = Ouvrier(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nom: nomController.text,
                  specialite: specialiteController.text,
                  telephone: telephoneController.text,
                  salaireJournalier: 50.0,
                  joursPointes: [],
                );
                setState(() {
                  globalOuvriers.add(newWorker);
                  _filterOuvriers(_searchController.text);
                });
                await DataStorage.saveTeam("annuaire_global", globalOuvriers);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }
}
