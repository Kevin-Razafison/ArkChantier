import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/chantier_model.dart';
import '../models/projet_model.dart';

class PdfService {
  // --- NOUVELLE MÉTHODE : PRÉVISUALISATION, IMPRESSION ET PARTAGE ---
  static Future<void> _handlePdfOutput(pw.Document pdf, String fileName) async {
    try {
      // 1. Convertir le PDF en octets
      final Uint8List bytes = await pdf.save();

      // 2. Obtenir un dossier temporaire sur le téléphone
      final Directory tempDir = await getTemporaryDirectory();
      final String path = "${tempDir.path}/$fileName";
      final File file = File(path);

      // 3. Écrire le fichier physiquement
      await file.writeAsBytes(bytes);

      // 4. Ouvrir DIRECTEMENT le menu de partage (WhatsApp, Email, etc.)

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          subject: 'Export ArkChantier : $fileName',
          sharePositionOrigin: Rect.fromLTWH(0, 0, 10, 10),
        ),
      );
    } catch (e) {
      debugPrint("Erreur lors de l'export/partage : $e");
    }
  }

  static Future<pw.MemoryImage> _getLogo() async {
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      final ByteData emptyData = await rootBundle.load(
        'assets/images/placeholder.png',
      );
      return pw.MemoryImage(emptyData.buffer.asUint8List());
    }
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage logo,
    String title,
    DateTime date,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Image(logo, width: 60, height: 60),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text("Date : ${date.day}/${date.month}/${date.year}"),
                pw.Text(
                  "Système ArkChantier Pro",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 20),
      ],
    );
  }

  // --- 1. RAPPORT FINANCIER DU PROJET ---
  static Future<void> generateFinancialReport({
    required Projet projet,
    required double totalMat,
    required double totalMO,
    required double totalEngage,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    double budgetGlobal = projet.chantiers.fold(
      0,
      (sum, c) => sum + c.budgetInitial,
    );
    double progressionMoyenne = projet.chantiers.isEmpty
        ? 0
        : projet.chantiers.map((c) => c.progression).reduce((a, b) => a + b) /
              projet.chantiers.length;

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(
            logo,
            "BILAN FINANCIER : ${projet.nom.toUpperCase()}",
            now,
          ),
          pw.Text(
            "Résumé de l'avancement",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildStatTile(
                  "Chantiers",
                  "${projet.chantiers.length}",
                ),
              ),
              pw.Expanded(
                child: _buildStatTile(
                  "Progression",
                  "${(progressionMoyenne * 100).toInt()}%",
                ),
              ),
              pw.Expanded(
                child: _buildStatTile(
                  "Statut",
                  budgetGlobal >= totalEngage ? "Sain" : "Alerte Budget",
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "Analyse des Dépenses Engagées",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headers: [
              'Poste de dépense',
              'Montant (${projet.devise})',
              '% du total',
            ],
            data: [
              [
                'Matériels et Stocks',
                '${totalMat.toStringAsFixed(2)} ${projet.devise}',
                '${totalEngage > 0 ? (totalMat / totalEngage * 100).toInt() : 0}%',
              ],
              [
                'Main d\'œuvre',
                '${totalMO.toStringAsFixed(2)} ${projet.devise}',
                '${totalEngage > 0 ? (totalMO / totalEngage * 100).toInt() : 0}%',
              ],
              [
                'TOTAL ENGAGÉ',
                '${totalEngage.toStringAsFixed(2)} ${projet.devise}',
                '100%',
              ],
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            "Détail par Chantier",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: ['Chantier', 'Budget Initial', 'Dépenses', 'Écart'],
            data: projet.chantiers
                .map(
                  (c) => [
                    c.nom,
                    c.budgetInitial.toStringAsFixed(0),
                    c.depensesActuelles.toStringAsFixed(0),
                    (c.budgetInitial - c.depensesActuelles).toStringAsFixed(0),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await _handlePdfOutput(pdf, 'Bilan_Financier_${projet.nom}.pdf');
  }

  static pw.Widget _buildStatTile(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      margin: const pw.EdgeInsets.symmetric(horizontal: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- 2. RAPPORT INVENTAIRE GLOBAL ---
  static Future<void> generateInventoryReport(
    List<Materiel> inventaire,
    String devise,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();
    final font = await PdfGoogleFonts.robotoRegular();

    double grandTotal = inventaire.fold(
      0,
      (sum, item) => sum + (item.quantite * item.prixUnitaire),
    );

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(logo, "ÉTAT CONSOLIDÉ DES STOCKS", now),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headers: ['Désignation', 'Qté', 'Unité', 'Total ($devise)'],
            data: inventaire
                .map(
                  (item) => [
                    item.nom,
                    item.quantite.toString(),
                    item.unite,
                    "${(item.quantite * item.prixUnitaire).toStringAsFixed(2)} $devise",
                  ],
                )
                .toList(),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors.grey100,
                child: pw.Text(
                  "VALEUR TOTALE : ${grandTotal.toStringAsFixed(2)} $devise",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    await _handlePdfOutput(pdf, 'Inventaire_Global.pdf');
  }

  // --- 3. BULLETIN DE PAIE OUVRIER ---
  static Future<void> generateOuvrierReport(
    Ouvrier worker,
    String devise,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();
    final font = await PdfGoogleFonts.robotoRegular();

    final String monthStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final int jours = worker.joursPointes
        .where((d) => d.startsWith(monthStr))
        .length;
    final double totalDu = jours * worker.salaireJournalier;

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logo, "BULLETIN DE PAIE", now),
              pw.Text(
                "EMPLOYÉ : ${worker.nom.toUpperCase()}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text("Spécialité : ${worker.specialite}"),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                headers: ['Désignation', 'Volume', 'Taux Journalier', 'Total'],
                data: [
                  [
                    'Prestation Travail',
                    '$jours jours',
                    '${worker.salaireJournalier} $devise',
                    '${totalDu.toStringAsFixed(2)} $devise',
                  ],
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Signature employé",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.blue50,
                    child: pw.Text(
                      "NET À PAYER : ${totalDu.toStringAsFixed(2)} $devise",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await _handlePdfOutput(pdf, 'Paye_${worker.nom}.pdf');
  }

  // --- 4. RAPPORT COMPLET CHANTIER ---
  static Future<void> generateChantierFullReport({
    required Chantier chantier,
    required List<Incident> incidents,
    required List<Ouvrier> equipage,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();
    final font = await PdfGoogleFonts.robotoRegular();
    final pw.Widget mapWidget = await _buildMapSection(chantier);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(
            logo,
            "RAPPORT D'ACTIVITÉ : ${chantier.nom.toUpperCase()}",
            now,
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Localisation : ${chantier.lieu}"),
              pw.Text(
                "Avancement : ${(chantier.progression * 100).toInt()}%",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ],
          ),
          pw.Text(
            "ÉQUIPE PRÉSENTE AUJOURD'HUI",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            headers: ['Nom', 'Spécialité', 'Statut'],
            data: equipage.map((o) {
              final String today = DateTime.now().toIso8601String().split(
                'T',
              )[0];
              final bool isPresent = o.joursPointes.contains(today);
              return [o.nom, o.specialite, isPresent ? "PRÉSENT" : "ABSENT"];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.SizedBox(height: 20),
          mapWidget,
          pw.SizedBox(height: 20),
          pw.Text(
            "JOURNAL DES INCIDENTS",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (incidents.isEmpty)
            pw.Text(
              "Aucun incident signalé.",
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
            )
          else
            ...incidents.map(
              (incident) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          incident.titre,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          "Priorité : ${incident.priorite.name.toUpperCase()}",
                          style: pw.TextStyle(
                            color: incident.priorite == Priorite.critique
                                ? PdfColors.red
                                : PdfColors.orange,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      incident.description,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (incident.imagePath != null &&
                        incident.imagePath!.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 10),
                        child: File(incident.imagePath!).existsSync()
                            ? pw.Image(
                                pw.MemoryImage(
                                  File(incident.imagePath!).readAsBytesSync(),
                                ),
                                height: 150,
                              )
                            : pw.SizedBox(),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    await _handlePdfOutput(pdf, 'Rapport_Complet_${chantier.nom}.pdf');
  }

  static Future<pw.Widget> _buildMapSection(Chantier chantier) async {
    final mapUrl =
        'https://static-maps.yandex.ru/1.x/?ll=${chantier.longitude},${chantier.latitude}&z=14&l=map&size=450,200';
    try {
      final response = await http.get(Uri.parse(mapUrl));
      if (response.statusCode == 200) {
        final mapImage = pw.MemoryImage(response.bodyBytes);
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "LOCALISATION DU SITE",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Image(mapImage),
            pw.SizedBox(height: 5),
            pw.Text(
              "Coordonnées : ${chantier.latitude}, ${chantier.longitude}",
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        );
      }
    } catch (e) {
      return pw.Text("Carte non disponible");
    }
    return pw.SizedBox();
  }
}
