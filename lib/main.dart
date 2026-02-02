import 'package:flutter/material.dart';

void main() {
  runApp(const ChantierApp());
}

class ChantierApp extends StatelessWidget {
  const ChantierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Détection de la largeur de l'écran
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      // Menu latéral escamotable sur mobile
      drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
      appBar: isMobile ? AppBar(title: const Text("ArkChantier"), backgroundColor: const Color(0xFF1A334D), foregroundColor: Colors.white) : null,
      body: Row(
        children: [
          // Sidebar fixe sur Desktop
          if (!isMobile)
            Container(
              width: 250,
              color: const Color(0xFF1A334D),
              child: _buildSidebarContent(),
            ),
          
          // Contenu Principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile) 
                    const Text("GESTION DE CHANTIERS BTP", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A334D))),
                  const SizedBox(height: 20),
                  
                  // Grille adaptative (1 colonne sur mobile, 2 sur desktop)
                  GridView.count(
                    shrinkWrap: true, // Important pour SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 1 : 2,
                    childAspectRatio: isMobile ? 1.2 : 1.5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    children: [
                      _buildInfoCard("PROGRÈS DES CHANTIERS", Colors.white, child: _listProgres()),
                      _buildInfoCard("ALERTES & NOTIFICATIONS", Colors.white, 
                          borderColor: Colors.orange, 
                          child: _listAlertes()),
                      _buildInfoCard("TÂCHES À FAIRE AUJ.", Colors.white),
                      _buildInfoCard("STATISTIQUES RAPIDES", Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CONTENU DES WIDGETS ---

  Widget _buildSidebarContent() {
    return Container(
      color: const Color(0xFF1A334D), 
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text("ArkChantier", style: TextStyle(color: Colors.white, fontSize: 20))
            )
          ),
                 _buildSidebarItem(Icons.dashboard, "Dashboard", isSelected: true),
        _buildSidebarItem(Icons.location_city, "Chantiers"),
        _buildSidebarItem(Icons.people, "Ouvriers"),
        _buildSidebarItem(Icons.inventory, "Matériel"),
        _buildSidebarItem(Icons.settings, "Paramètres"),
          const Expanded(child: SizedBox.expand()), 
        ],
      ),
    );
  }

  Widget _listAlertes() {
    // Simulation de données
    final alertes = [
      {"icon": Icons.warning, "color": Colors.orange, "text": "Matériel manquant : Bétonnière - Chantier B"},
      {"icon": Icons.error_outline, "color": Colors.red, "text": "Tâche en retard : Pose des murs A"},
      {"icon": Icons.info_outline, "color": Colors.blue, "text": "Nouvelle affectation : Jean Dupont"},
    ];

    return ListView.builder(
      itemCount: alertes.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Icon(alertes[index]['icon'] as IconData, color: alertes[index]['color'] as Color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(alertes[index]['text'] as String, style: const TextStyle(fontSize: 13))),
            ],
          ),
        );
      },
    );
  }

  Widget _listProgres() {
    return Column(
      children: [
        _progresItem("Chantier A: Fondation", 0.7, Colors.green),
        _progresItem("Chantier C: Gros Oeuvre", 0.3, Colors.blue),
      ],
    );
  }

  Widget _progresItem(String titre, double valeur, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontSize: 12)),
          LinearProgressIndicator(value: valeur, backgroundColor: Colors.grey[200], color: color),
        ],
      ),
    );
  }


  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      tileColor: isSelected ? Colors.orange.withOpacity(0.8) : Colors.transparent,
    );
  }

  Widget _buildInfoCard(String title, Color color, {Color? borderColor, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
          const Divider(),
          if (child != null) Expanded(child: child),
        ],
      ),
    );
  }
}