import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import du scanner
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
      final data = await DataStorage.loadTeam(widget.chantier.id);
      if (mounted) {
        setState(() {
          _equipe = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE DE POINTAGE (COMMUNE SCAN & CLIC) ---
  void _togglePresence(Ouvrier ouvrier, {bool? forceValue}) async {
    setState(() {
      ouvrier.estPresent = forceValue ?? !ouvrier.estPresent;
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

  // --- OUVERTURE DU SCANNER QR ---
  void _openQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "SCANNEZ LE BADGE OUVRIER",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A334D),
                ),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final String? code = barcode.rawValue;
                    if (code != null) {
                      _processScannedWorker(code);
                      Navigator.pop(
                        context,
                      ); // Ferme le scanner après détection
                      break;
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _processScannedWorker(String workerId) {
    try {
      // On cherche l'ouvrier dans l'équipe locale par son ID
      final worker = _equipe.firstWhere((o) => o.id == workerId);

      if (!worker.estPresent) {
        _togglePresence(worker, forceValue: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${worker.nom} pointé présent !"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${worker.nom} est déjà présent.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ouvrier non reconnu sur ce chantier."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    final presentCount = _equipe.where((o) => o.estPresent).length;

    return Scaffold(
      // On l'enveloppe dans un Scaffold interne pour avoir le FloatingActionButton
      body: Column(
        children: [
          _buildStatsHeader(presentCount),
          Expanded(
            child: _equipe.isEmpty
                ? const Center(child: Text("Aucun ouvrier assigné"))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _equipe.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildOuvrierTile(_equipe[index]),
                  ),
          ),
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

  // ... (Garde tes méthodes _buildStatsHeader et _buildOuvrierTile identiques)
  Widget _buildStatsHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A334D).withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PRÉSENCE DU JOUR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              Text(
                DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now()),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildOuvrierTile(Ouvrier o) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: o.estPresent
            ? Colors.green.shade100
            : Colors.grey.shade200,
        child: Text(
          o.nom[0],
          style: TextStyle(color: o.estPresent ? Colors.green : Colors.grey),
        ),
      ),
      title: Text(o.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(o.specialite, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: o.estPresent,
        activeTrackColor: Colors.green.shade400,
        activeThumbColor: Colors.green,
        onChanged: (val) => _togglePresence(o),
      ),
    );
  }
}
