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
import 'foreman_incident_view.dart';
import 'foreman_stock_view.dart';
import 'foreman_expense_view.dart';
import 'foreman_setting_screen.dart';
import 'foreman_profile_view.dart';
import '../../services/pdf_service.dart';
import '../../services/data_storage.dart';
import '../../widgets/chantier_map_preview.dart';
import '../../models/depense_model.dart' as dm;
import 'dart:io';
import '../chat_screen.dart';

class ForemanShell extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const ForemanShell({super.key, required this.user, required this.projet});

  @override
  State<ForemanShell> createState() => _ForemanShellState();
}

class _ForemanShellState extends State<ForemanShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  File? _profileImage;

  Future<void> _generateDailyReport(Chantier chantier) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Préparation du rapport PDF..."),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final equipe = await DataStorage.loadTeam(chantier.id);
      final stocks = await DataStorage.loadStocks(chantier.id);
      // 1. Charger les dépenses depuis le stockage local
      final List<dm.Depense> depenses = await DataStorage.loadDepenses(
        chantier.id,
      );
      await PdfService.generateChantierFullReport(
        chantier: chantier,
        incidents: chantier.incidents,
        equipage: equipe,
        stocks: stocks,
        depenses: depenses, // 2. Ajouter l'argument manquant ici
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

  void _updateProfileImage(File newImage) {
    setState(() {
      _profileImage = newImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final monChantier = widget.projet.chantiers.firstWhere(
      (c) => c.id == widget.user.assignedId,
      orElse: () => widget.projet.chantiers.first,
    );

    final List<Widget> pages = [
      _buildDashboard(monChantier),
      ForemanAttendanceView(chantier: monChantier),
      ForemanReportView(chantier: monChantier),
      ForemanStockView(chantier: monChantier),
      ForemanIncidentView(chantier: monChantier),
      ForemanExpenseView(chantier: monChantier, devise: widget.projet.devise),
      ForemanSettingsView(user: widget.user),
      ForemanProfileView(
        user: widget.user,
        currentImage: _profileImage,
        onImageChanged: _updateProfileImage,
      ),
      ChatScreen(chantierId: monChantier.id, currentUser: widget.user),
    ];

    // On définit le seuil de bascule
    bool isLargeScreen = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      key: _scaffoldKey,
      // Le Drawer n'apparaît que sur petit écran
      drawer: isLargeScreen
          ? null
          : ForemanSidebar(
              user: widget.user,
              profileImage: _profileImage,
              onDestinationSelected: (index) {
                if (index == -1) {
                  Navigator.pushReplacementNamed(context, '/login');
                } else {
                  setState(() => _currentIndex = index);
                  Navigator.pop(context); // Ferme le drawer sur mobile
                }
              },
            ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A334D),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: isLargeScreen
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Text(_getTitle(_currentIndex)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.orangeAccent),
            onPressed: () => _generateDailyReport(monChantier),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // LOGIQUE RESPONSIVE ICI
      body: Row(
        children: [
          if (isLargeScreen)
            SizedBox(
              width: 280, // Largeur fixe identique au Drawer standard
              child: ForemanSidebar(
                user: widget.user,
                profileImage: _profileImage,
                onDestinationSelected: (index) {
                  if (index == -1) {
                    Navigator.pushReplacementNamed(context, '/login');
                  } else {
                    setState(() => _currentIndex = index);
                    // Pas de Navigator.pop ici car ce n'est pas un Drawer coulissant
                  }
                },
              ),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: pages[_currentIndex],
            ),
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
      case 5:
        return "DÉPENSES & REÇUS";
      case 6:
        return "PARAMÈTRES";
      case 7:
        return "MON PROFIL";
      case 8:
        return "DISCUSSION CHANTIER";
      default:
        return "CHANTIER";
    }
  }

  Widget _buildDashboard(Chantier chantier) {
    // Détecter si on est en mode sombre pour ajuster certains textes
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WeatherBanner(
          city: chantier.lieu,
          lat: chantier.latitude,
          lon: chantier.longitude,
        ),
        const SizedBox(height: 20),
        Text(
          "EMPLACEMENT DU CHANTIER",
          style: TextStyle(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            // Bordure plus visible en mode clair
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: ChantierMapPreview(
            chantiers: [chantier],
            chantierActuel: chantier,
          ),
        ),
        const SizedBox(height: 20), // Ajout d'un espace
        // CARTE DE PROGRESSION
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Utilise la couleur de carte du thème (Blanche en clair, Bleue en sombre)
            color: isDark ? const Color(0xFF1A334D) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: Column(
            children: [
              Text(
                "PROGRESSION GLOBALE",
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: chantier.progression,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                color: Colors.orange,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 10),
              Text(
                "${(chantier.progression * 100).toInt()}% achevé",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildActionGrid(),
        const SizedBox(height: 20),

        InfoCard(
          title: "DERNIERS INCIDENTS",
          // L'InfoCard devrait déjà s'adapter si elle utilise le thème
          child: IncidentList(incidents: chantier.incidents),
        ),
        const SizedBox(height: 80),
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
        _quickActionBtn("MATÉRIEL", Icons.inventory, Colors.blue, () {
          setState(() => _currentIndex = 2);
        }),
        _quickActionBtn("DÉPENSES", Icons.receipt_long, Colors.orange, () {
          setState(() => _currentIndex = 5);
        }),
        _quickActionBtn(
          "INCIDENTS",
          Icons.warning_amber_rounded,
          Colors.red,
          () {
            setState(() => _currentIndex = 4);
          },
        ),
        _quickActionBtn(
          "CHAT",
          Icons.chat_bubble,
          Colors.green,
          () => setState(() => _currentIndex = 8),
        ),
      ],
    );
  }

  Widget _quickActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
