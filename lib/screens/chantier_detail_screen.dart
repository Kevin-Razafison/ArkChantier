import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chantier_model.dart';
import '../models/ouvrier_model.dart';
import '../models/journal_model.dart';
import '../data/mock_data.dart';

class ChantierDetailScreen extends StatefulWidget {
  final Chantier chantier;
  const ChantierDetailScreen({super.key, required this.chantier});

  @override
  State<ChantierDetailScreen> createState() => _ChantierDetailScreenState();
}

class _ChantierDetailScreenState extends State<ChantierDetailScreen> {
  // On stocke désormais les objets JournalEntry complets
  final List<JournalEntry> _journalEntries = [];
  final List<Ouvrier> _equipe = []; 

  // Cette fonction est le "pont" entre le Journal et la Galerie
  void _onNewJournalEntry(JournalEntry entry) {
    setState(() {
      _journalEntries.insert(0, entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
            JournalTab(onEntryAdded: _onNewJournalEntry), // Mis à jour
            GalleryTab(entries: _journalEntries),          // Mis à jour
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _kpiCard("Ouvriers", "${_equipe.length}", Icons.people, Colors.blue),
              // On compte uniquement les entrées du journal qui ont une image
              _kpiCard("Photos", "${_journalEntries.where((e) => e.imagePath != null).length}", Icons.photo, Colors.orange),
              _kpiCard("Jours", "24", Icons.timer, Colors.green),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.orange, size: 40),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Météo sur site", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Ensoleillé - 24°C", style: TextStyle(fontSize: 12)),
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
          ),
          const SizedBox(height: 30),
          _infoTile(Icons.location_on, "Localisation", widget.chantier.lieu),
          ListTile(
            leading: const Icon(Icons.assignment, color: Color(0xFF1A334D)),
            title: const Text("Statut (Cliquer pour modifier)", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTeamTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _showAddWorkerDialog(),
        child: const Icon(Icons.add),
      ),
      body: _equipe.isEmpty 
        ? const Center(child: Text("Aucun ouvrier assigné"))
        : ListView.builder(
            itemCount: _equipe.length,
            itemBuilder: (context, index) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_equipe[index].nom),
              subtitle: Text(_equipe[index].specialite),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _equipe.removeAt(index)),
              ),
            ),
          ),
    );
  }

  void _showAddWorkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Assigner un ouvrier"),
        content: DropdownButtonFormField<Ouvrier>(
          hint: const Text("Choisir"),
          items: globalOuvriers.map((o) => DropdownMenuItem(value: o, child: Text(o.nom))).toList(),
          onChanged: (val) {
            if (val != null && !_equipe.contains(val)) {
              setState(() => _equipe.add(val));
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// --- 3. JOURNAL MODIFIÉ ---
class JournalTab extends StatefulWidget {
  final Function(JournalEntry) onEntryAdded; // Reçoit l'objet complet
  const JournalTab({super.key, required this.onEntryAdded});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  final List<JournalEntry> _notes = [];
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
          id: DateTime.now().toString(),
          date: "Le ${DateTime.now().day}/${DateTime.now().month} à ${DateTime.now().hour}:${DateTime.now().minute}",
          contenu: _textController.text,
          auteur: "Chef de chantier",
          imagePath: _selectedImage?.path,
      );

      widget.onEntryAdded(newEntry); // Envoie l'objet au parent pour la Galerie

      setState(() {
        _notes.insert(0, newEntry);
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
          color: Colors.white,
          child: Column(
            children: [
              if (_selectedImage != null) Image.file(_selectedImage!, height: 80),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.camera_alt, color: Colors.orange), onPressed: _takePhoto),
                  Expanded(child: TextField(controller: _textController, decoration: const InputDecoration(hintText: "Rapport de situation..."))),
                  IconButton(icon: const Icon(Icons.send, color: Color(0xFF1A334D)), onPressed: _addEntry),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (note.imagePath != null) Image.file(File(note.imagePath!), fit: BoxFit.cover),
                    ListTile(title: Text(note.contenu), subtitle: Text(note.date)),
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

// --- 4. GALERIE ---
class GalleryTab extends StatelessWidget {
    final List<JournalEntry> entries; 

    const GalleryTab({super.key, required this.entries});

    @override
    Widget build(BuildContext context) {
      final entriesWithImages = entries.where((e) => e.imagePath != null).toList();

      if (entriesWithImages.isEmpty) {
        return const Center(child: Text("Aucune photo disponible"));
      }

      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: entriesWithImages.length,
        itemBuilder: (context, index) {
          final entry = entriesWithImages[index];
          return GestureDetector(
            onTap: () => _showPhotoDetail(context, entry),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(entry.imagePath!), fit: BoxFit.cover),
            ),
          );
        },
      );
    }

    void _showPhotoDetail(BuildContext context, JournalEntry entry) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.file(File(entry.imagePath!), fit: BoxFit.contain),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      entry.contenu.isEmpty ? "(Sans commentaire)" : entry.contenu,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text("Rapporté par : ${entry.auteur}", 
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              )
            ],
          ),
        ),
      );
    }
}