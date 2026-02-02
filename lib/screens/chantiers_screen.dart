import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../widgets/add_chantier_form.dart';
import 'chantier_detail_screen.dart';

class ChantiersScreen extends StatefulWidget {
  const ChantiersScreen({super.key});

  @override
  State<ChantiersScreen> createState() => _ChantiersScreenState();
}

class _ChantiersScreenState extends State<ChantiersScreen> {
  final List<Chantier> _listChantiers = [
    Chantier(id: '1', nom: "Résidence Horizon", lieu: "Paris", progression: 0.65, statut: StatutChantier.enCours),
    Chantier(id: '2', nom: "Extension École B", lieu: "Lyon", progression: 0.15, statut: StatutChantier.enRetard),
  ];

  StatutChantier? _filterStatut; // Null = "Tous"

  void _addNewChantier(Chantier nouveauChantier) {
    setState(() {
      _listChantiers.add(nouveauChantier);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Application du filtre sur la liste
    final filteredChantiers = _filterStatut == null 
      ? _listChantiers 
      : _listChantiers.where((c) => c.statut == _filterStatut).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("Mes Chantiers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- BARRE DE FILTRES (CHIPS) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text("Tous"),
                  selected: _filterStatut == null,
                  onSelected: (_) => setState(() => _filterStatut = null),
                ),
                ...StatutChantier.values.map((statut) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: FilterChip(
                    label: Text(statut.name),
                    selected: _filterStatut == statut,
                    onSelected: (selected) => setState(() => _filterStatut = selected ? statut : null),
                  ),
                )),
              ],
            ),
          ),
          
          // --- LISTE DES CHANTIERS ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredChantiers.length,
              itemBuilder: (context, index) {
                final c = filteredChantiers[index];
                
                return Dismissible(
                  key: Key(c.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 20), 
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  confirmDismiss: (_) => _confirmDeletion(context, c.nom),
                  onDismissed: (_) {
                    setState(() => _listChantiers.removeWhere((item) => item.id == c.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${c.nom} supprimé"), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: () => _goToDetail(context, c),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Icon(Icons.apartment, color: Colors.white, size: 50),
                          ),
                          ListTile(
                            title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.lieu),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: c.progression, 
                                  color: _getStatusColor(c.statut),
                                  backgroundColor: Colors.grey[200],
                                ),
                              ],
                            ),
                            trailing: _buildStatusBadge(c.statut),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AddChantierForm(onAdd: _addNewChantier),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- HELPERS ---
  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enRetard: return Colors.red;
      case StatutChantier.termine: return Colors.green;
      default: return Colors.blue;
    }
  }

  Widget _buildStatusBadge(StatutChantier statut) {
    Color color = _getStatusColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(statut.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _goToDetail(BuildContext context, Chantier chantier) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChantierDetailScreen(chantier: chantier)));
  }

  Future<bool?> _confirmDeletion(BuildContext context, String nom) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Voulez-vous vraiment supprimer le chantier $nom ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ANNULER")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}