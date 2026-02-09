import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchOuvrierData();
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 20),
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

  Future<void> _fetchOuvrierData() async {
    try {
      debugPrint(
        '🔍 Recherche ouvrier pour user ID: ${widget.user.id} / Firebase UID: ${widget.user.firebaseUid}',
      );

      final allWorkers = await DataStorage.loadGlobalOuvriers();

      debugPrint('📋 ${allWorkers.length} ouvrier(s) dans l\'annuaire global');

      // Chercher par ID ou par firebaseUid
      final worker = allWorkers.cast<Ouvrier?>().firstWhere(
        (w) => w?.id == widget.user.id || w?.id == widget.user.firebaseUid,
        orElse: () => null,
      );

      if (worker != null) {
        debugPrint('✅ Ouvrier trouvé: ${worker.nom} (ID: ${worker.id})');
      } else {
        debugPrint('⚠️ Aucun ouvrier trouvé dans l\'annuaire global');
        debugPrint(
          '   IDs recherchés: ${widget.user.id}, ${widget.user.firebaseUid}',
        );
        debugPrint(
          '   IDs disponibles: ${allWorkers.map((w) => w.id).join(", ")}',
        );
      }

      if (mounted) {
        setState(() {
          _realWorkerData = worker;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur _fetchOuvrierData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _realWorkerData!.nom);
    String? tempImagePath = _realWorkerData!.photoPath;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Modifier mon profil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setModalState(() => tempImagePath = image.path);
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: tempImagePath != null
                      ? FileImage(File(tempImagePath!))
                      : null,
                  child: tempImagePath == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nom complet",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;

                final allWorkers = await DataStorage.loadTeam(
                  "annuaire_global",
                );
                final index = allWorkers.indexWhere(
                  (w) => w.id == widget.user.id,
                );

                if (index != -1) {
                  allWorkers[index].nom = nameController.text;
                  allWorkers[index].photoPath = tempImagePath;
                }
                await DataStorage.saveTeam("annuaire_global", allWorkers);

                if (!mounted) return;

                setState(() {
                  _realWorkerData!.nom = nameController.text;
                  _realWorkerData!.photoPath = tempImagePath;
                });
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profil mis à jour !")),
                );
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_realWorkerData == null) return _buildErrorState();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final String monthPrefix =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-";

    final int joursTravailles = _realWorkerData!.joursPointes
        .where((date) => date.startsWith(monthPrefix))
        .length;
    final double totalPaie =
        joursTravailles * _realWorkerData!.salaireJournalier;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            _buildSectionLabel("MON POINTAGE (CE MOIS)"),
            _buildInteractiveCalendar(monthPrefix, isDark),
            _buildSectionLabel("MA SITUATION FINANCIÈRE"),
            _buildSalaryCard(joursTravailles, totalPaie, isDark),
            const SizedBox(height: 25),
            _buildQRBadgeCard(isDark),
          ],
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
      ),
      child: Stack(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.orange,
                backgroundImage: _realWorkerData!.photoPath != null
                    ? FileImage(File(_realWorkerData!.photoPath!))
                    : null,
                child: _realWorkerData!.photoPath == null
                    ? Text(
                        _realWorkerData!.nom[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                    const Text(
                      "OUVRIER QUALIFIÉ",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "ID: #${_realWorkerData!.id.substring(0, 8)}",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
              onPressed: _editProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCalendar(String prefix, bool isDark) {
    final int daysInMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
              color: isPointed
                  ? Colors.green
                  : (isDark ? Colors.white10 : Colors.grey[50]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                "$day",
                style: TextStyle(
                  color: isPointed
                      ? Colors.white
                      : (isDark ? Colors.white38 : Colors.black38),
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalaryCard(int jours, double total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () =>
                  PdfService.generateOuvrierReport(_realWorkerData!, "Ar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRBadgeCard(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors
              .white, // On laisse le QR sur fond blanc pour qu'il soit scannable
          borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
          Text(
            "Données introuvables",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
