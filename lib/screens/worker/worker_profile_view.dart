import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../models/ouvrier_model.dart';
import '../../services/data_storage.dart';
import '../../services/pdf_service.dart';

class WorkerProfileView extends StatefulWidget {
  final UserModel user;

  const WorkerProfileView({super.key, required this.user});

  @override
  State<WorkerProfileView> createState() => _WorkerProfileViewState();
}

class _WorkerProfileViewState extends State<WorkerProfileView> {
  Ouvrier? _realWorkerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOuvrierData();
  }

  Future<void> _fetchOuvrierData() async {
    try {
      final allWorkers = await DataStorage.loadTeam("annuaire_global");

      // On cherche l'ouvrier. Si on ne trouve pas, on ne lance pas d'exception fatale.
      final worker = allWorkers.cast<Ouvrier?>().firstWhere(
        (w) => w?.id == widget.user.id,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          _realWorkerData = worker;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A334D)),
      );
    }

    // Si on ne trouve pas l'ouvrier dans l'annuaire, on affiche une erreur propre
    if (_realWorkerData == null) {
      return _buildErrorState();
    }

    final now = DateTime.now();
    final String monthPrefix =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-";

    // LOGIQUE DE CALCUL INTERACTIVE
    final int joursTravailles = _realWorkerData!.joursPointes
        .where((date) => date.startsWith(monthPrefix))
        .length;
    final double totalPaie =
        joursTravailles * _realWorkerData!.salaireJournalier;

    return Container(
      color: const Color(0xFFF5F7F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 25),

            _buildSectionLabel("MON POINTAGE (CE MOIS)"),
            _buildInteractiveCalendar(monthPrefix),

            const SizedBox(height: 25),

            _buildSectionLabel("MA SITUATION FINANCIÈRE"),
            _buildSalaryInteractiveCard(joursTravailles, totalPaie),

            const SizedBox(height: 25),
            _buildQRBadgeCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE COMPOSANTS ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A334D),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.orange,
            child: Text(
              _realWorkerData!.nom[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _realWorkerData!.nom.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _realWorkerData!.specialite.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ID: #${_realWorkerData!.id.substring(0, 8)}",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCalendar(String prefix) {
    final int daysInMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          final day = index + 1;
          final dateKey = "$prefix${day.toString().padLeft(2, '0')}";
          bool isPointed = _realWorkerData!.joursPointes.contains(dateKey);

          return Container(
            decoration: BoxDecoration(
              color: isPointed ? Colors.green : Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPointed
                    ? Colors.green
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Text(
                "$day",
                style: TextStyle(
                  color: isPointed ? Colors.white : Colors.black38,
                  fontSize: 12,
                  fontWeight: isPointed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalaryInteractiveCard(int jours, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Salaire journalier",
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                "${_realWorkerData!.salaireJournalier.toInt()} Ar",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CUMUL DU MOIS",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                "${total.toInt()} Ar",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("TÉLÉCHARGER MA FICHE DE PAIE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A334D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // APPEL AU SERVICE PDF RÉEL
                PdfService.generateOuvrierReport(_realWorkerData!, "Ar");
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRBadgeCard() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: QrImageView(
              data: _realWorkerData!.id,
              version: QrVersions.auto,
              size: 140,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A334D),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "PRÉSENTEZ CE CODE POUR POINTER",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              "Données introuvables",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Votre compte n'est pas encore lié à un profil ouvrier actif. Contactez l'administrateur.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
