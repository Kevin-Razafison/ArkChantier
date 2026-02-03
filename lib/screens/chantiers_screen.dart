import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../models/projet_model.dart';
import '../widgets/add_chantier_form.dart';
import '../services/data_storage.dart';
import 'chantier_detail_screen.dart';

class ChantiersScreen extends StatefulWidget {
  final Projet projet;

  const ChantiersScreen({super.key, required this.projet});

  @override
  State<ChantiersScreen> createState() => _ChantiersScreenState();
}

class _ChantiersScreenState extends State<ChantiersScreen> {
  StatutChantier? _filterStatut;
  String _searchQuery = "";
  bool _isLoading = false;

  Future<void> _saveAndRefresh() async {
    await DataStorage.saveSingleProject(widget.projet);
    if (mounted) setState(() {});
  }

  void _addNewChantier(Chantier nouveauChantier) {
    setState(() => widget.projet.chantiers.add(nouveauChantier));
    _saveAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // LOGIQUE DE FILTRAGE
    final filteredList = widget.projet.chantiers.where((c) {
      final matchesSearch =
          c.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.lieu.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    final actives = filteredList
        .where((c) => c.statut != StatutChantier.termine)
        .toList();
    final termines = filteredList
        .where((c) => c.statut == StatutChantier.termine)
        .toList();

    List<Chantier> displayedActive = _filterStatut == null
        ? actives
        : actives.where((c) => c.statut == _filterStatut).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chantiers : ${widget.projet.nom}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Rechercher un chantier...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildFilterBar()),

          SliverToBoxAdapter(
            child: _buildSectionHeader(
              "EN COURS DANS CE PROJET",
              Icons.engineering,
              Colors.orange,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildChantierCard(displayedActive[index], isDark),
              ),
              childCount: displayedActive.length,
            ),
          ),

          if (_filterStatut == null && termines.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                "ARCHIVES DU PROJET",
                Icons.history,
                Colors.grey,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Opacity(
                    opacity: 0.7,
                    child: _buildChantierCard(termines[index], isDark),
                  ),
                ),
                childCount: termines.length,
              ),
            ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
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
          ...StatutChantier.values
              .where((s) => s != StatutChantier.termine)
              .map(
                (statut) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: FilterChip(
                    label: Text(statut.name),
                    selected: _filterStatut == statut,
                    onSelected: (selected) => setState(
                      () => _filterStatut = selected ? statut : null,
                    ),
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
        setState(
          () => widget.projet.chantiers.removeWhere((item) => item.id == c.id),
        );
        _saveAndRefresh();
      },
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () async {
            // CORRECTION ICI : Ajout du paramètre 'projet' requis par ChantierDetailScreen
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChantierDetailScreen(chantier: c, projet: widget.projet),
              ),
            );
            _saveAndRefresh();
          },
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  c.nom,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(c.lieu, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: c.progression,
                      color: _getStatusColor(c.statut),
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey[100],
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
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

  Widget _buildStatusBadge(StatutChantier statut) {
    Color color = _getStatusColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        statut.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
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

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
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

  Future<bool?> _confirmDeletion(BuildContext context, String nom) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer le chantier ?"),
        content: Text("Supprimer $nom de ce projet ?"),
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
