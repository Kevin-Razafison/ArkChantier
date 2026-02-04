import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/chantier_model.dart';
import '../models/journal_model.dart';
import '../models/report_model.dart';
import '../models/projet_model.dart';

class PdfService {
  static Future<pw.MemoryImage> _getLogo() async {
    try {
      // ByteData est maintenant reconnu grâce à dart:typed_data
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      final ByteData emptyData = await rootBundle.load(
        'assets/images/placeholder.png',
      );
      return pw.MemoryImage(emptyData.buffer.asUint8List());
    }
  }

  // --- HEADER REUTILISABLE ---
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
                  "Systeme ArkChantier Pro",
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
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
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(
            logo,
            "BILAN FINANCIER : ${projet.nom.toUpperCase()}",
            now,
          ),

          pw.Text(
            "Resume de l'avancement",
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
            "Analyse des Depenses Engages",
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
            headers: ['Poste de depense', 'Montant (EUR)', '% du total'],
            data: [
              [
                'Materiels et Stocks',
                '${totalMat.toStringAsFixed(2)} EUR',
                '${totalEngage > 0 ? (totalMat / totalEngage * 100).toInt() : 0}%',
              ],
              [
                'Main d\'oeuvre',
                '${totalMO.toStringAsFixed(2)} EUR',
                '${totalEngage > 0 ? (totalMO / totalEngage * 100).toInt() : 0}%',
              ],
              ['TOTAL ENGAGE', '${totalEngage.toStringAsFixed(2)} EUR', '100%'],
            ],
          ),

          pw.SizedBox(height: 30),
          pw.Text(
            "Detail par Chantier",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headers: ['Chantier', 'Budget Initial', 'Depenses', 'Ecart'],
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

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Bilan_Financier_${projet.nom}.pdf',
    );
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
  static Future<void> generateInventoryReport(List<Materiel> inventaire) async {
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
          _buildHeader(logo, "ETAT CONSOLIDE DES STOCKS", now),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
            headers: ['Designation', 'Qte', 'Unite', 'Total (EUR)'],
            data: inventaire
                .map(
                  (item) => [
                    item.nom,
                    item.quantite.toString(),
                    item.unite,
                    "${(item.quantite * item.prixUnitaire).toStringAsFixed(2)} EUR",
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
                  "VALEUR TOTALE : ${grandTotal.toStringAsFixed(2)} EUR",
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

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Inventaire_Global.pdf',
    );
  }

  // --- 3. BULLETIN DE PAIE OUVRIER ---
  static Future<void> generateOuvrierReport(Ouvrier worker) async {
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
                "EMPLOYE : ${worker.nom.toUpperCase()}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text("Specialite : ${worker.specialite}"),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                headers: ['Designation', 'Volume', 'Taux Journalier', 'Total'],
                data: [
                  [
                    'Prestation Travail',
                    '$jours jours',
                    '${worker.salaireJournalier} EUR',
                    '${totalDu.toStringAsFixed(2)} EUR',
                  ],
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Signature employe",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.blue50,
                    child: pw.Text(
                      "NET A PAYER : ${totalDu.toStringAsFixed(2)} EUR",
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

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Paye_${worker.nom}.pdf',
    );
  }

  // --- 4. RAPPORT COMPLET CHANTIER (AVEC PHOTOS) ---
  static Future<void> generateChantierFullReport({
    required Chantier chantier,
    required List<JournalEntry> journal,
    required List<Report> reports,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();
    final font = await PdfGoogleFonts.robotoRegular();

    final List<String> imagePaths = [
      ...journal.where((e) => e.imagePath != null).map((e) => e.imagePath!),
      ...reports.map((r) => r.imagePath),
    ];

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => [
          _buildHeader(logo, "RAPPORT : ${chantier.nom.toUpperCase()}", now),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Lieu : ${chantier.lieu}"),
              pw.Text(
                "Progression : ${(chantier.progression * 100).toInt()}%",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            "GALERIE PHOTOS DE SUIVI",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: imagePaths.map((path) {
              try {
                final file = File(path);
                if (!file.existsSync()) return pw.SizedBox();
                return pw.Container(
                  width: 160,
                  height: 120,
                  child: pw.Image(
                    pw.MemoryImage(file.readAsBytesSync()),
                    fit: pw.BoxFit.cover,
                  ),
                );
              } catch (e) {
                return pw.SizedBox();
              }
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Rapport_${chantier.nom}.pdf',
    );
  }
}
