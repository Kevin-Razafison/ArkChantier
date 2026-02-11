import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/chantier_model.dart';
import '../../models/ouvrier_model.dart';
import '../../services/data_storage.dart';

class ForemanAttendanceView extends StatefulWidget {
  final Chantier chantier;
  const ForemanAttendanceView({super.key, required this.chantier});

  @override
  State<ForemanAttendanceView> createState() => _ForemanAttendanceViewState();
}

class _ForemanAttendanceViewState extends State<ForemanAttendanceView> {
  List<Ouvrier> _equipe = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEquipe();
  }

  Future<void> _fetchEquipe() async {
    try {
      debugPrint('🔍 Loading team for chantier: ${widget.chantier.id}');
      debugPrint('🔍 Chantier name: ${widget.chantier.nom}');

      final data = await DataStorage.loadTeam(widget.chantier.id);

      debugPrint('📊 Loaded ${data.length} ouvriers');

      if (data.isEmpty) {
        debugPrint('⚠️ No ouvriers found for this chantier');
        debugPrint('🔍 Checking global annuaire...');

        final globalOuvriers = await DataStorage.loadGlobalOuvriers();
        debugPrint('🌍 Global annuaire has ${globalOuvriers.length} ouvriers');
      }

      if (mounted) {
        setState(() {
          _equipe = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading equipe: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- LOGIQUE DE POINTAGE (COMMUNE SCAN & CLIC) ---
  void _togglePresence(Ouvrier ouvrier, {bool? forceValue}) async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      setState(() {
        ouvrier.estPresent = forceValue ?? !ouvrier.estPresent;

        if (ouvrier.estPresent) {
          if (!ouvrier.joursPointes.contains(today)) {
            ouvrier.joursPointes.add(today);
          }
        } else {
          ouvrier.joursPointes.remove(today);
        }
      });

      await DataStorage.saveTeam(widget.chantier.id, _equipe);

      // Also update in global annuaire to keep data in sync
      _updateGlobalAnnuaire(ouvrier);
    } catch (e) {
      // Fallback date format if locale initialization failed
      String today = DateTime.now().toIso8601String().split('T')[0];
      setState(() {
        ouvrier.estPresent = forceValue ?? !ouvrier.estPresent;

        if (ouvrier.estPresent) {
          if (!ouvrier.joursPointes.contains(today)) {
            ouvrier.joursPointes.add(today);
          }
        } else {
          ouvrier.joursPointes.remove(today);
        }
      });
      await DataStorage.saveTeam(widget.chantier.id, _equipe);
    }
  }

  Future<void> _updateGlobalAnnuaire(Ouvrier ouvrier) async {
    try {
      final globalOuvriers = await DataStorage.loadGlobalOuvriers();
      final index = globalOuvriers.indexWhere((o) => o.id == ouvrier.id);

      if (index != -1) {
        // Update the ouvrier in global annuaire
        globalOuvriers[index] = ouvrier;
        await DataStorage.saveGlobalOuvriers(globalOuvriers);
        debugPrint('✅ Updated ouvrier ${ouvrier.nom} in global annuaire');
      } else {
        // Add to global annuaire if not exists
        globalOuvriers.add(ouvrier);
        await DataStorage.saveGlobalOuvriers(globalOuvriers);
        debugPrint('✅ Added ouvrier ${ouvrier.nom} to global annuaire');
      }
    } catch (e) {
      debugPrint('⚠️ Error updating global annuaire: $e');
    }
  }

  // --- OUVERTURE DU SCANNER QR ---
  void _openQRScanner() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text("Scanner le Badge"),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _processScannedWorker(barcode.rawValue!);
                        Navigator.pop(context);
                        break;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processScannedWorker(String workerId) async {
    try {
      // On cherche l'ouvrier dans l'équipe locale par son ID
      final worker = _equipe.firstWhere((o) => o.id == workerId);

      if (!worker.estPresent) {
        _togglePresence(worker, forceValue: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${worker.nom} pointé présent !"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${worker.nom} est déjà présent.")),
        );
      }
    } catch (e) {
      debugPrint('❌ Worker not found in local team: $workerId');

      // Try to find in global annuaire and add to team
      try {
        final globalOuvriers = await DataStorage.loadGlobalOuvriers();
        final worker = globalOuvriers.firstWhere((o) => o.id == workerId);

        // Add to local team
        setState(() {
          _equipe.add(worker);
        });

        // Save the team
        await DataStorage.saveTeam(widget.chantier.id, _equipe);

        // Mark as present
        _togglePresence(worker, forceValue: true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${worker.nom} ajouté au chantier et pointé présent !",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e2) {
        debugPrint('❌ Worker not found in global annuaire: $workerId');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ouvrier non reconnu."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ AMÉLIORATION: Dialog avec scroll et SafeArea
  Widget _buildAddOuvrierButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () async {
          debugPrint('➕ Opening global annuaire...');
          final globalOuvriers = await DataStorage.loadGlobalOuvriers();
          if (!context.mounted) return;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Ajouter un ouvrier"),
              // ✅ FIX: Utiliser ConstrainedBox au lieu de SizedBox fixe
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                  maxWidth: double.maxFinite,
                ),
                child: globalOuvriers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "Aucun ouvrier dans l'annuaire global",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true, // ✅ Important pour le dialog
                        itemCount: globalOuvriers.length,
                        itemBuilder: (context, index) {
                          final ouvrier = globalOuvriers[index];
                          final isAssigned = _equipe.any(
                            (o) => o.id == ouvrier.id,
                          );

                          return ListTile(
                            title: Text(ouvrier.nom),
                            subtitle: Text(ouvrier.specialite),
                            trailing: isAssigned
                                ? const Icon(Icons.check, color: Colors.green)
                                : IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      // Add to local team
                                      setState(() {
                                        _equipe.add(ouvrier);
                                      });

                                      // Save the team
                                      DataStorage.saveTeam(
                                        widget.chantier.id,
                                        _equipe,
                                      );

                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "${ouvrier.nom} ajouté au chantier",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fermer"),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text("AJOUTER UN OUVRIER"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A334D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    final presentCount = _equipe.where((o) => o.estPresent).length;

    return Scaffold(
      body: Column(
        children: [
          _buildStatsHeader(presentCount, isDark),
          if (_equipe.isEmpty) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Aucun ouvrier assigné à ce chantier",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    _buildAddOuvrierButton(context),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Column(
                children: [
                  _buildAddOuvrierButton(context),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _equipe.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _buildOuvrierTile(_equipe[index], isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openQRScanner,
        backgroundColor: const Color(0xFF1A334D),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.orange),
        label: const Text(
          "SCANNER BADGE",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFF1A334D).withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PRÉSENCE DU JOUR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.orangeAccent : Colors.blueGrey,
                ),
              ),
              Text(
                "${_getFrenchDay(DateTime.now().weekday)} ${DateTime.now().day} ${_getFrenchMonth(DateTime.now().month)}",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count / ${_equipe.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrenchDay(int weekday) {
    final days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return days[weekday - 1];
  }

  String _getFrenchMonth(int month) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month - 1];
  }

  Widget _buildOuvrierTile(Ouvrier o, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: o.estPresent
            ? (isDark
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.green.shade100)
            : (isDark ? Colors.white10 : Colors.grey.shade200),
        child: Text(
          o.nom[0],
          style: TextStyle(
            color: o.estPresent
                ? Colors.green
                : (isDark ? Colors.white38 : Colors.grey),
          ),
        ),
      ),
      title: Text(
        o.nom,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        o.specialite,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Retirer l'ouvrier"),
                  content: Text("Retirer ${o.nom} de ce chantier ?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ANNULER"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _equipe.removeWhere((ouvrier) => ouvrier.id == o.id);
                        });
                        DataStorage.saveTeam(widget.chantier.id, _equipe);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${o.nom} retiré du chantier"),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        "RETIRER",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Switch(
            value: o.estPresent,
            activeTrackColor: Colors.green.shade400,
            activeThumbColor: Colors.green,
            onChanged: (val) => _togglePresence(o),
          ),
        ],
      ),
    );
  }
}
