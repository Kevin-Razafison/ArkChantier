import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/chantier_model.dart';
import '../models/ouvrier_model.dart';
import '../models/journal_model.dart';

class ChantierDetailScreen extends StatelessWidget {
  final Chantier chantier;

  const ChantierDetailScreen({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(chantier.nom),
          backgroundColor: const Color(0xFF1A334D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Color(0xFFFFD700),
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFFFD700),
            tabs: [
              Tab(icon: Icon(Icons.info), text: "Infos"),
              Tab(icon: Icon(Icons.group), text: "Équipe"),
              Tab(icon: Icon(Icons.folder), text: "Documents"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            const TeamTab(), 
            const JournalTab()
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Progression actuelle : ${(chantier.progression * 100).toInt()}%", 
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: chantier.progression,
            minHeight: 15,
            borderRadius: BorderRadius.circular(10),
            color: Colors.green,
          ),
          const SizedBox(height: 30),
          _infoTile(Icons.location_on, "Localisation", chantier.lieu),
          _infoTile(Icons.calendar_today, "Début des travaux", "12 Janvier 2024"),
          _infoTile(Icons.assignment, "Statut", chantier.statut.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A334D)),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
  
}

class JournalTab extends StatefulWidget {
  const JournalTab({super.key});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  final List<JournalEntry> _notes = [];
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  // Fonction pour prendre une photo
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  void _addEntry() {
    if (_textController.text.isNotEmpty || _selectedImage != null) {
      setState(() {
        _notes.insert(0, JournalEntry(
          id: DateTime.now().toString(),
          date: "Aujourd'hui à ${DateTime.now().hour}:${DateTime.now().minute}",
          contenu: _textController.text,
          auteur: "Chef de chantier",
          imagePath: _selectedImage?.path,
        ));
        _textController.clear();
        _selectedImage = null; // Reset l'image après envoi
      });
    }
  }
  @override
  void dispose() {
    _textController.dispose(); // Libère la mémoire quand on quitte l'écran
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- ZONE DE SAISIE ---
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Column(
            children: [
              if (_selectedImage != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Image.file(_selectedImage!, height: 100, fit: BoxFit.cover),
                ),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.camera_alt, color: Colors.orange), onPressed: _takePhoto),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: "Rapport de situation...", border: InputBorder.none),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send, color: Color(0xFF1A334D)), onPressed: _addEntry),
                ],
              ),
            ],
          ),
        ),
        // --- FIL D'ACTUALITÉ ---
        Expanded(
          child: ListView.builder(
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.imagePath != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.file(File(note.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(note.date, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                              Text(note.auteur, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(note.contenu, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
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
class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  // Liste gérée dans le State pour permettre la modification visuelle
  final List<Ouvrier> _equipe = [
    Ouvrier(id: '1', nom: "Jean Dupont", specialite: "Maçon Expert"),
    Ouvrier(id: '2', nom: "Marc Vasseur", specialite: "Électricien"),
    Ouvrier(id: '3', nom: "Amine Sadek", specialite: "Conducteur d'engins"),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _equipe.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final worker = _equipe[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(worker.photoUrl),
          ),
          title: Text(worker.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(worker.specialite),
          trailing: GestureDetector(
            onTap: () {
              setState(() {
                worker.estPresent = !worker.estPresent;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: worker.estPresent ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: worker.estPresent ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                worker.estPresent ? "PRÉSENT" : "ABSENT",
                style: TextStyle(
                  color: worker.estPresent ? Colors.green[800] : Colors.red[800],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}