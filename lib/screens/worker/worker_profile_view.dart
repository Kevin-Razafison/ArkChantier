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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ FIX: Dialog d'édition sans overflow
  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _realWorkerData!.nom);
    String? tempImagePath = _realWorkerData!.photoPath;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text("Modifier mon profil"),
          content: SingleChildScrollView(
            // ✅ Important pour éviter overflow
            child: Column(
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
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: tempImagePath != null
                            ? FileImage(File(tempImagePath!))
                            : null,
                        child: tempImagePath == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nom complet",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                // ✅ Validation
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Le nom ne peut pas être vide"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final allWorkers = await DataStorage.loadGlobalOuvriers();
                final index = allWorkers.indexWhere(
                  (w) => w.id == widget.user.id,
                );

                if (index != -1) {
                  allWorkers[index].nom = nameController.text.trim();
                  allWorkers[index].photoPath = tempImagePath;
                  await DataStorage.saveGlobalOuvriers(allWorkers);
                }

                if (!mounted) return;

                setState(() {
                  _realWorkerData!.nom = nameController.text.trim();
                  _realWorkerData!.photoPath = tempImagePath;
                });

                if (!context.mounted) return;
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profil mis à jour !"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Enregistrer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

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
            const SizedBox(height: 40), // ✅ Espace en bas
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
                backgroundColor: Colors.green,
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "OUVRIER QUALIFIÉ",
                      style: TextStyle(
                        color: Colors.green,
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
              tooltip: "Modifier mon profil",
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
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
                  fontWeight: isPointed ? FontWeight.bold : FontWeight.normal,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Salaire journalier",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                "${_realWorkerData!.salaireJournalier.toInt()} Ar",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CUMUL DU MOIS",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  Text(
                    "$jours jour(s) travaillé(s)",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                try {
                  await PdfService.generateOuvrierReport(
                    _realWorkerData!,
                    "Ar",
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Fiche de paie générée"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRBadgeCard(bool isDark) {
    return Center(
      child: Column(
        children: [
          const Text(
            "MON BADGE QR",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: QrImageView(
              data: _realWorkerData!.id,
              version: QrVersions.auto,
              size: 150,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A334D),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Présentez ce code au chef pour pointer",
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 60,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            "Données introuvables",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Contactez votre chef de chantier",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
