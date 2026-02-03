import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../widgets/add_chantier_form.dart';
import '../services/data_storage.dart';
import 'chantier_detail_screen.dart';

class ChantiersScreen extends StatefulWidget {
  const ChantiersScreen({super.key});

  @override
  State<ChantiersScreen> createState() => _ChantiersScreenState();
}

class _ChantiersScreenState extends State<ChantiersScreen> {
  List<Chantier> _listChantiers = [];
  StatutChantier? _filterStatut;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final savedChantiers = await DataStorage.loadChantiers();
    setState(() {
      if (savedChantiers.isNotEmpty) {
        _listChantiers = savedChantiers;
      } else {
        _listChantiers = [
          Chantier(
            id: '1',
            nom: "Résidence Horizon",
            lieu: "Paris",
            progression: 0.65,
            statut: StatutChantier.enCours,
            latitude: 48.8566,
            longitude: 2.3522,
            budgetInitial: 500000,
          ),
          Chantier(
            id: '2',
            nom: "Extension École B",
            lieu: "Lyon",
            progression: 0.15,
            statut: StatutChantier.enRetard,
            latitude: 45.7640,
            longitude: 4.8357,
            budgetInitial: 250000,
          ),
        ];
      }
      _isLoading = false;
    });
  }

  Future<void> _saveAndRefresh() async {
    await DataStorage.saveChantiers(_listChantiers);
    setState(() {});
  }

  void _addNewChantier(Chantier nouveauChantier) {
    setState(() {
      _listChantiers.add(nouveauChantier);
    });
    _saveAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredChantiers = _filterStatut == null
        ? _listChantiers
        : _listChantiers.where((c) => c.statut == _filterStatut).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mes Chantiers",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredChantiers.length,
              itemBuilder: (context, index) {
                final c = filteredChantiers[index];
                return _buildChantierCard(c, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FilterChip(
            label: const Text("Tous"),
            selected: _filterStatut == null,
            onSelected: (_) => setState(() => _filterStatut = null),
          ),
          ...StatutChantier.values.map(
            (statut) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FilterChip(
                label: Text(statut.name),
                selected: _filterStatut == statut,
                onSelected: (selected) =>
                    setState(() => _filterStatut = selected ? statut : null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChantierCard(Chantier c, bool isDark) {
    return Dismissible(
      key: Key(c.id),
      direction: DismissDirection.endToStart,
      background: _buildDeleteBackground(),
      confirmDismiss: (_) => _confirmDeletion(context, c.nom),
      onDismissed: (_) {
        setState(() => _listChantiers.removeWhere((item) => item.id == c.id));
        _saveAndRefresh();
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChantierDetailScreen(chantier: c),
              ),
            );
            _saveAndRefresh();
          },
          child: Column(
            children: [
              Container(
                height: 100,
                width: double.infinity,
                color: isDark ? Colors.white10 : Colors.grey[200],
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.orange.withOpacity(0.5),
                  size: 40,
                ),
              ),
              ListTile(
                title: Text(
                  c.nom,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${c.lieu} (Lat: ${c.latitude.toStringAsFixed(2)})"),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: c.progression,
                      color: _getStatusColor(c.statut),
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey[200],
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
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(Icons.delete, color: Colors.white, size: 30),
    );
  }

  void _showAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AddChantierForm(onAdd: _addNewChantier),
        ),
      ),
    );
  }

  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enRetard:
        return Colors.red;
      case StatutChantier.termine:
        return Colors.green;
      default:
        return Colors.blue;
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
      child: Text(
        statut.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, String nom) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: Text("Voulez-vous vraiment supprimer le chantier $nom ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ANNULER"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
