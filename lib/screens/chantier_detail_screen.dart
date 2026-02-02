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
  // Liste qui centralise les photos pour la Galerie
  final List<String> _galleryImages = [];

  // Fonction pour ajouter une photo à la galerie depuis le Journal
  void _onNewPhoto(String path) {
    setState(() {
      _galleryImages.insert(0, path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Passage à 4 onglets pour tout avoir
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
            const TeamTab(),
            JournalTab(onPhotoAdded: _onNewPhoto), // On passe la fonction de rappel
            GalleryTab(images: _galleryImages),
          ],
        ),
      ),
    );
  }

  // --- 1. MÉTÉO ET STATUT ---
  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
}

// --- 2. JOURNAL (AVEC CALLBACK PHOTO) ---
class JournalTab extends StatefulWidget {
  final Function(String) onPhotoAdded;
  const JournalTab({super.key, required this.onPhotoAdded});

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
    if (photo != null) {
      setState(() => _selectedImage = File(photo.path));
    }
  }

  void _addEntry() {
    if (_textController.text.isNotEmpty || _selectedImage != null) {
      if (_selectedImage != null) {
        widget.onPhotoAdded(_selectedImage!.path); // Envoi à la Galerie
      }
      setState(() {
        _notes.insert(0, JournalEntry(
          id: DateTime.now().toString(),
          date: "Aujourd'hui à ${DateTime.now().hour}:${DateTime.now().minute}",
          contenu: _textController.text,
          auteur: "Chef de chantier",
          imagePath: _selectedImage?.path,
        ));
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
                  Expanded(child: TextField(controller: _textController, decoration: const InputDecoration(hintText: "Rapport..."))),
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

// --- 3. GALERIE ---
class GalleryTab extends StatelessWidget {
  final List<String> images;
  const GalleryTab({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return images.isEmpty 
      ? const Center(child: Text("Aucune photo")) 
      : GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 5, mainAxisSpacing: 5),
          itemCount: images.length,
          itemBuilder: (context, index) => Image.file(File(images[index]), fit: BoxFit.cover),
        );
  }
}

// --- 4. ÉQUIPE ---
class TeamTab extends StatefulWidget {
  const TeamTab({super.key});
  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  final List<Ouvrier> _equipe = []; // Liste locale au chantier

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _showAddWorkerDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _equipe.length,
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(_equipe[index].nom),
          subtitle: Text(_equipe[index].specialite),
        ),
      ),
    );
  }

  void _showAddWorkerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un ouvrier"),
        content: DropdownButtonFormField<Ouvrier>(
          items: globalOuvriers.map((o) => DropdownMenuItem(value: o, child: Text(o.nom))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _equipe.add(val));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}