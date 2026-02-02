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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9), // Fond gris clair du design
      body: Row(
        children: [
          // 1. Menu Latéral (Sidebar)
          Container(
            width: 200,
            color: const Color(0xFF1A334D), // Bleu foncé du design
            child: Column(
              children: [
                const DrawerHeader(child: Text("ArkBTPManager", style: TextStyle(color: Colors.white))),
                _buildSidebarItem(Icons.dashboard, "Dashboard", isSelected: true),
                _buildSidebarItem(Icons.location_city, "Chantiers"),
                _buildSidebarItem(Icons.people, "Ouvriers"),
                _buildSidebarItem(Icons.inventory, "Matériel"),
                _buildSidebarItem(Icons.settings, "Paramètres"),
              ],
            ),
          ),
          
          // 2. Contenu Principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("GESTION DE CHANTIERS BTP", 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A334D))),
                  const SizedBox(height: 20),
                  
                  // Grille des Widgets
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: [
                        _buildInfoCard("PROGRÈS DES CHANTIERS", Colors.white),
                        _buildInfoCard("ALERTES & NOTIFICATIONS", Colors.white, borderColor: Colors.orange),
                        _buildInfoCard("TÂCHES À FAIRE AUJ.", Colors.white),
                        _buildInfoCard("STATISTIQUES RAPIDES", Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les items du menu
  Widget _buildSidebarItem(IconData icon, String title, {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      tileColor: isSelected ? Colors.orange : Colors.transparent,
    );
  }

  // Widget générique pour les cartes du Dashboard
  Widget _buildInfoCard(String title, Color color, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }
}