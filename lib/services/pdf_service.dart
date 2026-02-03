import 'dart:io';
import 'dart:typed_data'; // AJOUTÉ : Pour ByteData
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/chantier_model.dart';
import '../models/journal_model.dart';
import '../models/report_model.dart';

class PdfService {
  // --- UTILS : CHARGEMENT DU LOGO ---
  static Future<pw.MemoryImage> _getLogo() async {
    // Utilisation de ByteData grâce à l'import typed_data
    final ByteData logoData = await rootBundle.load('assets/images/logo.png');
    return pw.MemoryImage(logoData.buffer.asUint8List());
  }

  // --- UTILS : HEADER STANDARD RÉUTILISABLE ---
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
                  "Système Mon Chantier Pro",
                  // CORRIGÉ : Retrait du 'const' ici
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

  // --- LOGIQUE DE FUSION DES MATÉRIELS ---
  static List<Materiel> aggregateMateriels(List<Materiel> brute) {
    final Map<String, Materiel> aggregated = {};

    for (var item in brute) {
      if (aggregated.containsKey(item.nom)) {
        aggregated[item.nom] = Materiel(
          id: aggregated[item.nom]!.id,
          nom: item.nom,
          categorie: item.categorie,
          quantite: aggregated[item.nom]!.quantite + item.quantite,
          prixUnitaire: item.prixUnitaire,
          unite: item.unite,
        );
      } else {
        aggregated[item.nom] = item;
      }
    }
    return aggregated.values.toList();
  }

  // --- 1. GÉNÉRATION RAPPORT INVENTAIRE ---
  static Future<void> generateInventoryReport(List<Materiel> inventaire) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();

    final List<Materiel> fusionnee = aggregateMateriels(inventaire);
    fusionnee.sort(
      (a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()),
    );

    double grandTotal = 0;
    for (var item in fusionnee) {
      grandTotal += (item.quantite * item.prixUnitaire);
    }

    pdf.addPage(
      pw.MultiPage(
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
            headers: ['Désignation', 'Qté', 'Unité', 'Total (€)'],
            data: fusionnee
                .map(
                  (item) => [
                    item.nom,
                    item.quantite.toString(),
                    item.unite,
                    (item.quantite * item.prixUnitaire).toStringAsFixed(2),
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
                  "VALEUR TOTALE : ${grandTotal.toStringAsFixed(2)} €",
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

  // --- 2. GÉNÉRATION FICHE DE PAIE OUVRIER ---
  static Future<void> generateOuvrierReport(Ouvrier worker) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();

    final String monthStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final int jours = worker.joursPointes
        .where((d) => d.startsWith(monthStr))
        .length;
    final double totalDu = jours * worker.salaireJournalier;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logo, "BULLETIN DE PAIE", now),
              pw.SizedBox(height: 20),
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
                    '${worker.salaireJournalier} €',
                    '${totalDu.toStringAsFixed(2)} €',
                  ],
                ],
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Signature employé",
                    // CORRIGÉ : Retrait du 'const' ici
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    color: PdfColors.blue50,
                    child: pw.Text(
                      "NET À PAYER : ${totalDu.toStringAsFixed(2)} €",
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

  // --- 3. GÉNÉRATION RAPPORT COMPLET CLIENT ---
  static Future<void> generateChantierFullReport({
    required Chantier chantier,
    required List<JournalEntry> journal,
    required List<Report> reports,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();

    final List<String> images = [
      ...journal.where((e) => e.imagePath != null).map((e) => e.imagePath!),
      ...reports.map((r) => r.imagePath),
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(logo, "RAPPORT DE CHANTIER : ${chantier.nom}", now),
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
            "GALERIE PHOTOS",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: images.map((path) {
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

  // --- 4. GÉNÉRATION RAPPORT DE RETARDS ---
  static Future<void> generateDelayReport(
    List<Chantier> chantiersEnRetard,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(logo, "RAPPORT D'ALERTE : CHANTIERS EN RETARD", now),

          pw.Text(
            "Ce document liste les projets nécessitant une intervention immédiate ou une révision du planning.",
            style: pw.TextStyle(
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 20),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.red200),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
            headers: [
              'Chantier',
              'Localisation',
              'Progression',
              'Budget Consommé',
            ],
            data: chantiersEnRetard
                .map(
                  (c) => [
                    c.nom,
                    c.lieu,
                    "${(c.progression * 100).toInt()}%",
                    "${c.depensesActuelles.toStringAsFixed(0)} €",
                  ],
                )
                .toList(),
          ),

          pw.SizedBox(height: 40),
          pw.Text(
            "Notes de direction :",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Container(
              height: 100,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Rapport_Retards.pdf',
    );
  }
}
