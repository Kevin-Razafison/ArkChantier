import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chantier_model.dart';
import '../models/ouvrier_model.dart';
import '../models/journal_model.dart';
import '../models/materiel_model.dart'; // Assure-toi que ce modèle existe
import '../data/mock_data.dart';
import '../services/data_storage.dart';

class ChantierDetailScreen extends StatefulWidget {
  final Chantier chantier;
  const ChantierDetailScreen({super.key, required this.chantier});

  @override
  State<ChantierDetailScreen> createState() => _ChantierDetailScreenState();
}

class _ChantierDetailScreenState extends State<ChantierDetailScreen> {
  List<JournalEntry> _journalEntries = [];
  List<Ouvrier> _equipe = [];
  List<Materiel> _materiels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChantierData();
  }

  Future<void> _loadChantierData() async {
    final savedJournal = await DataStorage.loadJournal(widget.chantier.id);
    final savedTeam = await DataStorage.loadTeam(widget.chantier.id);
    final savedMat = await DataStorage.loadMateriels(widget.chantier.id);
    
    setState(() {
      _journalEntries = savedJournal;
      _equipe = savedTeam;
      _materiels = savedMat;
      _isLoading = false;
    });
  }

  Future<void> _persistAll() async {
    await DataStorage.saveJournal(widget.chantier.id, _journalEntries);
    await DataStorage.saveTeam(widget.chantier.id, _equipe);
    await DataStorage.saveMateriels(widget.chantier.id, _materiels);
    
    // Mise à jour du chantier global (pour le budget et statut)
    final list = await DataStorage.loadChantiers();
    final index = list.indexWhere((c) => c.id == widget.chantier.id);
    if (index != -1) {
      list[index] = widget.chantier;
      await DataStorage.saveChantiers(list);
    }
  }

  void _onNewJournalEntry(JournalEntry entry) {
    setState(() => _journalEntries.insert(0, entry));
    _persistAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(widget.chantier.nom),
          backgroundColor: const Color(0xFF1A334D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFFFFD700),
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFFFD700),
            tabs: [
              Tab(icon: Icon(Icons.info), text: "Infos"),
              Tab(icon: Icon(Icons.group), text: "Équipe"),
              Tab(icon: Icon(Icons.build), text: "Matériels"),
              Tab(icon: Icon(Icons.history), text: "Journal"),
              Tab(icon: Icon(Icons.photo_library), text: "Galerie"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context),
            _buildTeamTab(),
            _buildMaterialsTab(),
            JournalTab(onEntryAdded: _onNewJournalEntry, entries: _journalEntries),
            GalleryTab(entries: _journalEntries),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double ratio = widget.chantier.budgetInitial > 0 
        ? widget.chantier.depensesActuelles / widget.chantier.budgetInitial 
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- DASHBOARD BUDGET ---
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Suivi Budgétaire", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ratio > 1.0 ? 1.0 : ratio,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  color: ratio > 0.9 ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${widget.chantier.depensesActuelles.toStringAsFixed(0)} €", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: ratio > 1.0 ? Colors.red : Colors.green)),
                    Text("Budget: ${widget.chantier.budgetInitial.toStringAsFixed(0)} €"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kpiCard("Ouvriers", "${_equipe.length}", Icons.people, Colors.blue),
              _kpiCard("Photos", "${_journalEntries.where((e) => e.imagePath != null).length}", Icons.photo, Colors.orange),
              _kpiCard("Matériel", "${_materiels.length}", Icons.inventory, Colors.purple),
            ],
          ),
          const SizedBox(height: 25),
          Text("Progression : ${(widget.chantier.progression * 100).toInt()}%",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: widget.chantier.progression,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
            color: Colors.green,
            backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
          ),
          const SizedBox(height: 30),
          _infoTile(Icons.location_on, "Localisation", widget.chantier.lieu),
          ListTile(
            leading: const Icon(Icons.assignment, color: Color(0xFF1A334D)),
            title: Text("Statut (Cliquer pour modifier)", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
            subtitle: Text(widget.chantier.statut.name.toUpperCase(), 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showStatusPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor)),
          ],
        ),
      );
  }

  // --- ONGLET EQUIPE ---
  Widget _buildTeamTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true, backgroundColor: const Color(0xFF1A334D),
        onPressed: () => _showAddWorkerDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _equipe.isEmpty 
        ? Center(child: Text("Aucun ouvrier", style: TextStyle(color: Theme.of(context).hintColor)))
        : ListView.builder(
            itemCount: _equipe.length,
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_equipe[index].nom),
              subtitle: Text("${_equipe[index].specialite} • ${_equipe[index].salaireJournalier}€/j"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() => _equipe.removeAt(index));
                  _persistAll();
                },
              ),
            ),
          ),
    );
  }

  // --- ONGLET MATERIELS ---
  Widget _buildMaterialsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true, backgroundColor: Colors.orange,
        onPressed: () => _showAddMaterialDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _materiels.isEmpty 
        ? Center(child: Text("Aucun matériel", style: TextStyle(color: Theme.of(context).hintColor)))
        : ListView.builder(
            itemCount: _materiels.length,
            itemBuilder: (context, index) {
              final m = _materiels[index];
              return ListTile(
                leading: const Icon(Icons.category, color: Colors.blue),
                title: Text(m.nom),
                subtitle: Text("${m.quantite} ${m.unite} x ${m.prixUnitaire}€"),
                trailing: Text("${(m.quantite * m.prixUnitaire).toStringAsFixed(0)} €", style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
    );
  }

  void _showAddWorkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter à l'équipe"),
        content: DropdownButtonFormField<Ouvrier>(
          hint: const Text("Choisir un ouvrier"),
          items: globalOuvriers.map((o) => DropdownMenuItem(value: o, child: Text("${o.nom} (${o.salaireJournalier}€/j)"))).toList(),
          onChanged: (val) {
            if (val != null && !_equipe.any((o) => o.id == val.id)) {
              setState(() {
                _equipe.add(val);
                widget.chantier.depensesActuelles += val.salaireJournalier;
              });
              _persistAll();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showAddMaterialDialog() {
    final nomCtrl = TextEditingController();
    final qteCtrl = TextEditingController();
    final prixCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter Matériel"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: "Nom du matériel")),
            TextField(controller: qteCtrl, decoration: const InputDecoration(labelText: "Quantité"), keyboardType: TextInputType.number),
            TextField(controller: prixCtrl, decoration: const InputDecoration(labelText: "Prix Unitaire (€)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final qte = int.tryParse(qteCtrl.text) ?? 0;
              final prix = double.tryParse(prixCtrl.text) ?? 0;
              final nouveauMat = Materiel(
                id: DateTime.now().toString(),
                nom: nomCtrl.text,
                quantite: qte,
                prixUnitaire: prix,
                unite: "Unités",
                categorie: CategorieMateriel.consommable
              );
              setState(() {
                _materiels.add(nouveauMat);
                widget.chantier.depensesActuelles += (qte * prix);
              });
              _persistAll();
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }

  // --- LOGIQUE STATUT & UI HELPERS ---
  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: StatutChantier.values.map((s) => ListTile(
          leading: Icon(Icons.circle, color: _getStatusColor(s)),
          title: Text(s.name.toUpperCase()),
          onTap: () {
            setState(() => widget.chantier.statut = s);
            _persistAll();
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enRetard: return Colors.red;
      case StatutChantier.termine: return Colors.green;
      default: return Colors.blue;
    }
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A334D)),
      title: Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

// --- LES CLASSES JOURNAL & GALERIE RESTENT IDENTIQUES À TON CODE ---

class JournalTab extends StatefulWidget {
  final Function(JournalEntry) onEntryAdded;
  final List<JournalEntry> entries;
  const JournalTab({super.key, required this.onEntryAdded, required this.entries});
  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) setState(() => _selectedImage = File(photo.path));
  }

  void _addEntry() {
    if (_textController.text.isNotEmpty || _selectedImage != null) {
      final newEntry = JournalEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: "Le ${DateTime.now().day}/${DateTime.now().month} à ${DateTime.now().hour}:${DateTime.now().minute}",
          contenu: _textController.text,
          auteur: "Chef de chantier",
          imagePath: _selectedImage?.path,
      );
      widget.onEntryAdded(newEntry);
      setState(() { _textController.clear(); _selectedImage = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              if (_selectedImage != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, height: 100)),
                ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.camera_alt, color: Colors.orange), onPressed: _takePhoto),
                  Expanded(child: TextField(controller: _textController, decoration: const InputDecoration(hintText: "Rapport...", border: InputBorder.none))),
                  IconButton(icon: const Icon(Icons.send, color: Color(0xFF1A334D)), onPressed: _addEntry),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: widget.entries.length,
            itemBuilder: (context, index) {
              final note = widget.entries[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.imagePath != null) 
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.file(File(note.imagePath!), fit: BoxFit.cover, width: double.infinity, height: 200)
                      ),
                    ListTile(title: Text(note.contenu), subtitle: Text(note.date, style: const TextStyle(fontSize: 11))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class GalleryTab extends StatelessWidget {
    final List<JournalEntry> entries; 
    const GalleryTab({super.key, required this.entries});

    @override
    Widget build(BuildContext context) {
      final imgs = entries.where((e) => e.imagePath != null).toList();
      if (imgs.isEmpty) return const Center(child: Text("Aucune photo"));

      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: imgs.length,
        itemBuilder: (context, index) {
          final entry = imgs[index];
          return GestureDetector(
            onTap: () => _showPhotoDetail(context, entry),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(entry.imagePath!), fit: BoxFit.cover)),
          );
        },
      );
    }

    void _showPhotoDetail(BuildContext context, JournalEntry entry) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(File(entry.imagePath!)),
              Padding(padding: const EdgeInsets.all(16), child: Text(entry.contenu)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))
            ],
          ),
        ),
      );
    }
}