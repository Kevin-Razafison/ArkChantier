import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../models/message_model.dart';
import '../../widgets/weather_banner.dart';
import '../../widgets/incident_widget.dart';
import '../../widgets/info_card.dart';
import '../../widgets/simple_chantier_map.dart';
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

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() {});
    });
  }

  // ✅ AMÉLIORATION: Gestion d'erreur dans la génération PDF
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
      final List<dm.Depense> depenses = await DataStorage.loadDepenses(
        chantier.id,
      );

      await PdfService.generateChantierFullReport(
        chantier: chantier,
        incidents: chantier.incidents,
        equipage: equipe,
        stocks: stocks,
        depenses: depenses,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rapport PDF généré avec succès"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur génération PDF: $e');
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
    Chantier monChantier;
    if (widget.projet.chantiers.isEmpty) {
      monChantier = Chantier(
        id: 'chantier_default_${widget.user.id}',
        nom: 'Chantier Principal',
        lieu: 'Localisation non définie',
        progression: 0.0,
        statut: StatutChantier.enCours,
        budgetInitial: 0,
        depensesActuelles: 0,
        latitude: 0.0,
        longitude: 0.0,
      );
    } else {
      monChantier = widget.projet.chantiers.firstWhere(
        (c) => c.id == widget.user.assignedId,
        orElse: () => widget.projet.chantiers.first,
      );
    }

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
      ChatScreen(
        chatRoomId: monChantier.id,
        chatRoomType: ChatRoomType.chantier,
        currentUser: widget.user,
      ),
    ];

    bool isLargeScreen = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      key: _scaffoldKey,
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
                  Navigator.pop(context);
                }
              },
            ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A334D),
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
            tooltip: "Générer rapport PDF",
            onPressed: () => _generateDailyReport(monChantier),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isLargeScreen)
            SizedBox(
              width: 280,
              child: ForemanSidebar(
                user: widget.user,
                profileImage: _profileImage,
                onDestinationSelected: (index) {
                  if (index == -1) {
                    Navigator.pushReplacementNamed(context, '/login');
                  } else {
                    setState(() => _currentIndex = index);
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
        return "RAPPORTS PHOTOS";
      case 3:
        return "MATÉRIEL & STOCKS";
      case 4:
        return "JOURNAL D'INCIDENTS";
      case 5:
        return "DÉPENSES & REÇUS";
      case 6:
        return "PARAMÈTRES";
      case 7:
        return "MON PROFIL";
      case 8:
        return "DISCUSSION ÉQUIPE";
      default:
        return "CHANTIER";
    }
  }

  Widget _buildDashboard(Chantier chantier) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WeatherBanner(
                city: chantier.lieu,
                lat: chantier.latitude,
                lon: chantier.longitude,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoCard(
                title: "VUE D'ENSEMBLE",
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        "BUDGET",
                        "${(chantier.budgetInitial / 1000000).toStringAsFixed(1)}M",
                        Icons.account_balance_wallet,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        "DÉPENSES",
                        "${(chantier.depensesActuelles / 1000000).toStringAsFixed(1)}M",
                        Icons.trending_down,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        "PROGRESSION",
                        "${(chantier.progression * 100).toInt()}%",
                        Icons.analytics,
                        Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoCard(
                title: "LOCALISATION DU CHANTIER",
                padding: const EdgeInsets.all(12),
                child: SimpleChantierMap(
                  latitude: chantier.latitude,
                  longitude: chantier.longitude,
                  nomChantier: chantier.nom,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (chantier.incidents.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InfoCard(
                  title: "INCIDENTS PAR PRIORITÉ",
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 80,
                    child: IncidentSummary(incidents: chantier.incidents),
                  ),
                ),
              ),
            ),

          if (chantier.incidents.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoCard(
                title: "ACTIONS RAPIDES",
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _simpleActionBtn(
                            "MATÉRIEL",
                            Icons.inventory,
                            Colors.blue,
                            () => setState(() => _currentIndex = 3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _simpleActionBtn(
                            "DÉPENSES",
                            Icons.receipt_long,
                            Colors.orange,
                            () => setState(() => _currentIndex = 5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _simpleActionBtn(
                            "INCIDENTS",
                            Icons.warning_amber_rounded,
                            Colors.red,
                            () => setState(() => _currentIndex = 4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _simpleActionBtn(
                            "CHAT",
                            Icons.chat_bubble,
                            Colors.green,
                            () => setState(() => _currentIndex = 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoCard(
                title: "DERNIERS INCIDENTS",
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: IncidentList(incidents: chantier.incidents),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 26),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _simpleActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 26),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
