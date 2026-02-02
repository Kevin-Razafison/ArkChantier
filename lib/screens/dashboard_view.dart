import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/info_card.dart';

class DashboardView extends StatelessWidget {
  final UserModel user;

  const DashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BIENVENUE, ${user.nom.toUpperCase()}",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            "ESPACE ${user.role.name.toUpperCase()}",
            style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            childAspectRatio: isMobile ? 1.2 : 1.5,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              InfoCard(title: "PROGRÈS DES CHANTIERS", child: _listProgres()),
              
              if (user.role != UserRole.client)
                InfoCard(
                  title: "ALERTES & NOTIFICATIONS", 
                  borderColor: Colors.orange,
                  child: _listAlertes(),
                ),

              InfoCard(title: "TÂCHES À FAIRE AUJ.", child: const Center(child: Text("Flux de tâches"))),
              
              if (user.role == UserRole.chefProjet)
                InfoCard(
                  title: "STATISTIQUES FINANCIÈRES", 
                  child: const Center(child: Icon(Icons.analytics, size: 40, color: Colors.blue)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthodes d'aide (Helpers) pour le contenu
  Widget _listProgres() {
    return Column(
      children: [
        _progresItem("Chantier A", 0.7, Colors.green),
        _progresItem("Chantier C", 0.3, Colors.blue),
      ],
    );
  }

  Widget _progresItem(String t, double v, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: const TextStyle(fontSize: 12)),
          LinearProgressIndicator(value: v, color: c, backgroundColor: Colors.grey[200]),
        ],
      ),
    );
  }

  Widget _listAlertes() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.warning, color: Colors.orange, size: 20),
          title: Text("Bétonnière HS - Site B", style: TextStyle(fontSize: 12)),
          dense: true,
        ),
        ListTile(
          leading: Icon(Icons.timer, color: Colors.red, size: 20),
          title: Text("Retard Livraison Acier", style: TextStyle(fontSize: 12)),
          dense: true,
        ),
      ],
    );
  }
}