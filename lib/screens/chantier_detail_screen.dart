import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chantier_model.dart';
import '../models/ouvrier_model.dart';
import '../models/journal_model.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChantierData();
  }

  // Chargement des données spécifiques au chantier (Journal et Équipe)
  Future<void> _loadChantierData() async {
    final savedJournal = await DataStorage.loadJournal(widget.chantier.id);
    final savedTeam = await DataStorage.loadTeam(widget.chantier.id);
    
    setState(() {
      _journalEntries = savedJournal;
      _equipe = savedTeam;
      _isLoading = false;
    });
  }

  // Sauvegarde du journal
  Future<void> _persistJournal() async {
    await DataStorage.saveJournal(widget.chantier.id, _journalEntries);
  }

  // Sauvegarde de l'équipe
  Future<void> _persistTeam() async {
    await DataStorage.saveTeam(widget.chantier.id, _equipe);
  }

  void _onNewJournalEntry(JournalEntry entry) {
    setState(() {
      _journalEntries.insert(0, entry);
    });
    _persistJournal();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 4,
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
              Tab(icon: Icon(Icons.history), text: "Journal"),
              Tab(icon: Icon(Icons.photo_library), text: "Galerie"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context),
            _buildTeamTab(),
            JournalTab(onEntryAdded: _onNewJournalEntry, entries: _journalEntries),
            GalleryTab(entries: _journalEntries),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kpiCard("Ouvriers", "${_equipe.length}", Icons.people, Colors.blue),
              _kpiCard("Photos", "${_journalEntries.where((e) => e.imagePath != null).length}", Icons.photo, Colors.orange),
              _kpiCard("Jours", "24", Icons.timer, Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Météo sur site", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Ensoleillé - 24°C", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  ],
                ),
              ],
            ),
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 5)],
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

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: StatutChantier.values.map((s) => ListTile(
            leading: Icon(Icons.circle, color: _getStatusColor(s)),
            title: Text(s.name.toUpperCase()),
            onTap: () {
              setState(() => widget.chantier.statut = s);
              Navigator.pop(context);
            },
          )).toList(),
        ),
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

  Widget _buildTeamTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: const Color(0xFF1A334D),
        onPressed: () => _showAddWorkerDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _equipe.isEmpty 
        ? Center(child: Text("Aucun ouvrier assigné", style: TextStyle(color: Theme.of(context).hintColor)))
        : ListView.builder(
            itemCount: _equipe.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: Colors.blue)
              ),
              title: Text(_equipe[index].nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_equipe[index].specialite),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  setState(() => _equipe.removeAt(index));
                  _persistTeam();
                },
              ),
            ),
          ),
    );
  }

  void _showAddWorkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Assigner un ouvrier"),
        content: DropdownButtonFormField<Ouvrier>(
          dropdownColor: Theme.of(context).cardColor,
          hint: const Text("Choisir"),
          items: globalOuvriers.map((o) => DropdownMenuItem(value: o, child: Text(o.nom))).toList(),
          onChanged: (val) {
            if (val != null && !_equipe.any((o) => o.id == val.id)) {
              setState(() => _equipe.add(val));
              _persistTeam();
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// --- JOURNAL ---
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
      setState(() {
        _textController.clear();
        _selectedImage = null;
      });
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
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.imagePath != null) 
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.file(File(note.imagePath!), fit: BoxFit.cover, width: double.infinity, height: 200)
                      ),
                    ListTile(
                      title: Text(note.contenu), 
                      subtitle: Text(note.date, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11))
                    ),
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

// --- GALERIE ---
class GalleryTab extends StatelessWidget {
    final List<JournalEntry> entries; 
    const GalleryTab({super.key, required this.entries});

    @override
    Widget build(BuildContext context) {
      final imgs = entries.where((e) => e.imagePath != null).toList();
      if (imgs.isEmpty) return Center(child: Text("Aucune photo disponible", style: TextStyle(color: Theme.of(context).hintColor)));

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
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: Image.file(File(entry.imagePath!), fit: BoxFit.contain)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.date, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(entry.contenu.isEmpty ? "(Sans commentaire)" : entry.contenu, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))
            ],
          ),
        ),
      );
    }
}