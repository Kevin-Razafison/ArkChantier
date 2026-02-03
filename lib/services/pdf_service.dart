import 'dart:io';
import 'dart:typed_data';
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
  // --- CHARGEMENT DES RESSOURCES (LOGO & POLICE) ---
  static Future<pw.MemoryImage> _getLogo() async {
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Fallback si le logo n'est pas trouvé
      final ByteData emptyData = await rootBundle.load(
        'assets/images/placeholder.png',
      );
      return pw.MemoryImage(emptyData.buffer.asUint8List());
    }
  }

  // --- HEADER RÉUTILISABLE (SANS CONST SUR LES STYLES) ---
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

  // --- 1. RAPPORT INVENTAIRE GLOBAL ---
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
          _buildHeader(logo, "ÉTAT CONSOLIDÉ DES STOCKS", now),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey900),
            headers: ['Désignation', 'Qté', 'Unité', 'Total (€)'],
            data: inventaire
                .map(
                  (item) => [
                    item.nom,
                    item.quantite.toString(),
                    item.unite,
                    "${(item.quantite * item.prixUnitaire).toStringAsFixed(2)} €",
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

  // --- 2. BULLETIN DE PAIE OUVRIER ---
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
                "EMPLOYÉ : ${worker.nom.toUpperCase()}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text("Spécialité : ${worker.specialite}"),
              pw.SizedBox(height: 30),
              pw.TableHelper.fromTextArray(
                headerDecoration: pw.BoxDecoration(
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

  // --- 3. RAPPORT COMPLET CHANTIER (AVEC PHOTOS) ---
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
          _buildHeader(logo, "RAPPORT : ${chantier.nom}", now),
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

  // --- 4. RAPPORT DE RETARDS (ALERTES) ---
  static Future<void> generateDelayReport(
    List<Chantier> chantiersEnRetard,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final logo = await _getLogo();
    final font = await PdfGoogleFonts.robotoRegular();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => [
          _buildHeader(logo, "ALERTE : CHANTIERS EN RETARD", now),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.red200),
            headerDecoration: pw.BoxDecoration(color: PdfColors.red800),
            headers: ['Chantier', 'Lieu', 'Progression', 'Dépenses'],
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
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Rapport_Retards.pdf',
    );
  }
}
