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

class _ChantiersScreenState extends State<ChantiersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StatutChantier? _filterStatut;
  String _searchQuery = "";
  bool _isSaving = false;

  Future<void> _saveAndRefresh() async {
    if (!mounted || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      await DataStorage.saveSingleProject(widget.projet);
    } catch (e) {
      debugPrint("Erreur de sauvegarde: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // CORRECTION : Méthode manquante réajoutée
  void _addNewChantier(Chantier nouveauChantier) {
    setState(() {
      widget.projet.chantiers.add(nouveauChantier);
    });
    _saveAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchQuery.trim().toLowerCase();

    final List<Chantier> chantiers = List.from(widget.projet.chantiers);

    final filteredList = chantiers.where((c) {
      return c.nom.toLowerCase().contains(query) ||
          c.lieu.toLowerCase().contains(query);
    }).toList();

    final actives = filteredList
        .where((c) => c.statut != StatutChantier.termine)
        .where((c) => _filterStatut == null || c.statut == _filterStatut)
        .toList();

    final termines = filteredList
        .where((c) => c.statut == StatutChantier.termine)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Chantiers : ${widget.projet.nom}"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _isSaving,
            child: CustomScrollView(
              slivers: [
                // CORRECTION : Appel de la méthode définie plus bas
                _buildSearchAndFilters(context, isDark),

                _buildSliverHeader(
                  "EN COURS",
                  Icons.engineering,
                  Colors.orange,
                ),

                actives.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("Aucun chantier trouvé"),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          // CORRECTION : Passage de isDark
                          (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildChantierCard(actives[index], isDark),
                          ),
                          childCount: actives.length,
                        ),
                      ),

                if (_filterStatut == null && termines.isNotEmpty) ...[
                  _buildSliverHeader("ARCHIVES", Icons.history, Colors.grey),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Opacity(
                          opacity: 0.6,
                          child: _buildChantierCard(termines[index], isDark),
                        ),
                      ),
                      childCount: termines.length,
                    ),
                  ),
                ],
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSaving
          ? null
          : FloatingActionButton(
              heroTag: "fab_chantiers_screen",
              backgroundColor: Colors.orange,
              onPressed: () => _showAddForm(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  // CORRECTION : Méthode manquante définie ici
  Widget _buildSearchAndFilters(BuildContext context, bool isDark) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Rechercher...",
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
          _buildFilterBar(),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(child: _buildSectionHeader(title, icon, color));
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChantierDetailScreen(chantier: c, projet: widget.projet),
              ),
            );
            if (!mounted) return;
            setState(() {}); // Rafraîchit l'affichage au retour sans bloquer
          },
          child: ListTile(
            title: Text(
              c.nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.lieu),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: c.progression,
                  color: _getStatusColor(c.statut),
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                ),
              ],
            ),
            trailing: _buildStatusBadge(c.statut),
          ),
        ),
      ),
    );
  }

  // Les autres widgets (_buildSectionHeader, _buildStatusBadge, etc.)
  // restent identiques à ta version précédente.
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StatutChantier statut) {
    Color color = _getStatusColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

  Color _getStatusColor(StatutChantier statut) {
    if (statut == StatutChantier.enRetard) return Colors.red;
    if (statut == StatutChantier.termine) return Colors.green;
    return Colors.blue;
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  void _showAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddChantierForm(onAdd: _addNewChantier),
      ),
    );
  }

  Future<bool?> _confirmDeletion(BuildContext context, String nom) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous supprimer le chantier $nom ?"),
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
