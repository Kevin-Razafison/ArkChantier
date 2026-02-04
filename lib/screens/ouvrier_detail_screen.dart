import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ouvrier_model.dart';
import '../services/pdf_service.dart';
import '../services/data_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OuvrierDetailScreen extends StatefulWidget {
  final Ouvrier worker;

  const OuvrierDetailScreen({super.key, required this.worker});

  @override
  State<OuvrierDetailScreen> createState() => _OuvrierDetailScreenState();
}

class _OuvrierDetailScreenState extends State<OuvrierDetailScreen> {
  Future<void> _makePhoneCall() async {
    final String phoneNumber = widget.worker.telephone;

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Aucun numéro de téléphone enregistré pour cet ouvrier.",
          ),
        ),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Impossible d\'ouvrir l\'application de téléphone.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    }
  }

  void _showEditWorkerSheet() {
    final nomController = TextEditingController(text: widget.worker.nom);
    final phoneController = TextEditingController(
      text: widget.worker.telephone,
    );
    final salaireController = TextEditingController(
      text: widget.worker.salaireJournalier.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Modifier l'Ouvrier",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom"),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Téléphone"),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: salaireController,
              decoration: const InputDecoration(
                labelText: "Salaire Journalier",
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A334D),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  setState(() {
                    widget.worker.nom = nomController.text;
                    widget.worker.telephone = phoneController.text;
                    widget.worker.salaireJournalier =
                        double.tryParse(salaireController.text) ??
                        widget.worker.salaireJournalier;
                  });

                  // Load all workers, update this one, save back
                  final allWorkers = await DataStorage.loadTeam(
                    "annuaire_global",
                  );
                  final index = allWorkers.indexWhere(
                    (w) => w.id == widget.worker.id,
                  );
                  if (index != -1) {
                    allWorkers[index] = widget.worker;
                    await DataStorage.saveTeam("annuaire_global", allWorkers);
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text("Enregistrer les modifications"),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                "Supprimer l'ouvrier",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => _confirmDelete(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer l'ouvrier ?"),
        content: Text(
          "Êtes-vous sûr de vouloir retirer ${widget.worker.nom} de la base de données ? Cette action est irréversible.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final allWorkers = await DataStorage.loadTeam("annuaire_global");
              allWorkers.removeWhere((o) => o.id == widget.worker.id);
              await DataStorage.saveTeam("annuaire_global", allWorkers);

              if (!context.mounted) return;
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              Navigator.of(context).pop(); // Return to list

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ouvrier supprimé avec succès.")),
              );
            },
            child: const Text("Supprimer"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: const Text("Afficher le Badge"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Badge de ${widget.worker.nom}"),
                  content: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: widget.worker.id, // On encode l'ID de l'ouvrier
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final List<String> moisFr = [
      "",
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Ouvrier"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const Divider(height: 40, indent: 40, endIndent: 40),
            _buildSectionTitle("Informations Générales"),
            _buildDetailItem(
              Icons.payments,
              "Salaire Journalier",
              "${widget.worker.salaireJournalier} € / jour",
            ),
            _buildDetailItem(
              Icons.phone,
              "Téléphone",
              widget.worker.telephone.isNotEmpty
                  ? widget.worker.telephone
                  : "Non renseigné",
            ),
            _buildDetailItem(
              Icons.badge,
              "ID Employé",
              "#${widget.worker.id.length > 8 ? widget.worker.id.substring(0, 8) : widget.worker.id}",
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Pointage du mois (${moisFr[now.month]})"),
            _buildAttendanceGrid(),
            const SizedBox(height: 30),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Hero(
          tag: "avatar-${widget.worker.id}",
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue[100],
            child: Text(
              widget.worker.nom[0],
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A334D),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          widget.worker.nom,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          widget.worker.specialite.toUpperCase(),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceGrid() {
    final now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final String monthPrefix =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-";

    final List<String> mois = [
      "",
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${mois[now.month]} ${now.year}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A334D),
                ),
              ),
              Text(
                "${widget.worker.joursPointes.where((d) => d.startsWith(monthPrefix)).length} j. travaillés",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final int day = index + 1;
              final String dateKey =
                  "$monthPrefix${day.toString().padLeft(2, '0')}";
              final bool isPointed = widget.worker.joursPointes.contains(
                dateKey,
              );

              return GestureDetector(
                onTap: () async {
                  setState(() {
                    if (isPointed) {
                      widget.worker.joursPointes.remove(dateKey);
                    } else {
                      widget.worker.joursPointes.add(dateKey);
                    }
                  });

                  final allWorkers = await DataStorage.loadTeam(
                    "annuaire_global",
                  );
                  final index = allWorkers.indexWhere(
                    (w) => w.id == widget.worker.id,
                  );
                  if (index != -1) {
                    allWorkers[index] = widget.worker;
                    await DataStorage.saveTeam("annuaire_global", allWorkers);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isPointed ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPointed
                          ? Colors.green
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: isPointed
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        fontSize: 12,
                        color: isPointed ? Colors.white : Colors.black87,
                        fontWeight: isPointed
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, "Présent"),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.white, "Absent"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text("Appeler"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _makePhoneCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Modifier"),
                  onPressed: () {
                    _showEditWorkerSheet();
                  },
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Badge"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showQRCodeBadge(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: const Text("Exporter la fiche de paie (PDF)"),
              onPressed: () => PdfService.generateOuvrierReport(widget.worker),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A334D)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showQRCodeBadge() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Badge : ${widget.worker.nom}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Présentez ce code pour le pointage"),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: widget.worker.id, // L'ID que le scanner va lire
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
