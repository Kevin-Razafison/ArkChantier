import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../widgets/weather_banner.dart';
import '../../widgets/incident_widget.dart';
import '../../widgets/info_card.dart';
import 'foreman_sidebar.dart';
import 'foreman_attendance_view.dart';
import 'foreman_report_view.dart';
import '../../services/pdf_service.dart';
import '../../services/data_storage.dart';

class ForemanShell extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const ForemanShell({super.key, required this.user, required this.projet});

  @override
  State<ForemanShell> createState() => _ForemanShellState();
}

class _ForemanShellState extends State<ForemanShell> {
  int _currentIndex = 0;
  // Nécessaire pour ouvrir le Drawer via un bouton personnalisé si besoin
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _generateDailyReport(Chantier chantier) async {
    // Petit feedback visuel immédiat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Préparation du rapport PDF..."),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final equipe = await DataStorage.loadTeam(chantier.id);

      await PdfService.generateChantierFullReport(
        chantier: chantier,
        incidents: [], // Tu passeras ta liste ici plus tard
        equipage: equipe,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la génération : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monChantier = widget.projet.chantiers.firstWhere(
      (c) => c.id == widget.user.chantierId,
      orElse: () => widget.projet.chantiers.first,
    );

    // Liste des pages étendue pour correspondre à la Sidebar
    final List<Widget> pages = [
      _buildHomeTab(monChantier), // 0: Tableau de bord
      ForemanAttendanceView(chantier: monChantier), // 1: Pointage
      const Center(
        child: Text(
          "Gestion des Stocks",
          style: TextStyle(color: Colors.white),
        ),
      ), // 2: Matériel
      ForemanReportView(chantier: monChantier), // 3: Rapports Photos
      const Center(
        child: Text(
          "Journal d'Incidents",
          style: TextStyle(color: Colors.white),
        ),
      ), // 4: Incidents
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: ForemanSidebar(
        user: widget.user,
        onDestinationSelected: (index) {
          if (index == -1) {
            // Déconnexion
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            setState(() => _currentIndex = index);
            Navigator.pop(context); // Ferme le Drawer
          }
        },
      ),
      // On utilise un AppBar pour avoir le bouton menu (Hamburger)
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A334D),
        elevation: 0,
        title: Text(
          _getTitle(_currentIndex),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.orangeAccent),
            tooltip: "Générer Rapport PDF",
            onPressed: () => _generateDailyReport(monChantier),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 2
            ? 0
            : _currentIndex, // Reset si on est hors index
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF1A334D),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Mon Site',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Pointage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Rapports',
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "TABLEAU DE BORD";
      case 1:
        return "POINTAGE PERSONNEL";
      case 2:
        return "STOCKS & MATÉRIEL";
      case 3:
        return "RAPPORTS PHOTOS";
      case 4:
        return "JOURNAL D'INCIDENTS";
      default:
        return "CHANTIER";
    }
  }

  Widget _buildHomeTab(Chantier chantier) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: WeatherBanner(
            city: chantier.lieu,
            lat: chantier.latitude,
            lon: chantier.longitude,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildActionGrid(),
              const SizedBox(height: 20),
              InfoCard(
                title: "PROGRESSION RÉELLE",
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: chantier.progression,
                      minHeight: 15,
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${(chantier.progression * 100).toInt()}% achevé",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              InfoCard(
                title: "DERNIERS INCIDENTS",
                child: IncidentList(incidents: []),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: [
        _quickActionBtn("MATÉRIEL", Icons.inventory, Colors.blue),
        _quickActionBtn("BESOIN AIDE", Icons.help_outline, Colors.red),
      ],
    );
  }

  Widget _quickActionBtn(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
