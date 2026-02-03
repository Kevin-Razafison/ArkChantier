import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart'; // Importation critique ajoutée

class PdfService {
  
  // --- GÉNÉRATION RAPPORT INVENTAIRE ---
  static Future<void> generateInventoryReport(List<Materiel> inventaire) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    double grandTotal = 0;
    for (var item in inventaire) {
      grandTotal += (item.quantite * item.prixUnitaire);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ÉTAT DES STOCKS - CHANTIER", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("${now.day}/${now.month}/${now.year}"),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              headers: ['Désignation', 'Catégorie', 'Qté', 'P.U (€)', 'Total (€)'],
              data: inventaire.map((item) {
                return [
                  item.nom,
                  item.categorie.name.toUpperCase(),
                  item.quantite.toString(),
                  item.prixUnitaire.toStringAsFixed(2),
                  (item.quantite * item.prixUnitaire).toStringAsFixed(2),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
                child: pw.Text(
                  "VALEUR TOTALE DU STOCK : ${grandTotal.toStringAsFixed(2)} €",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Inventaire_Stock_${now.millisecondsSinceEpoch}.pdf',
    );
  }

  // --- GÉNÉRATION FICHE DE PAIE OUVRIER ---
  static Future<void> generateOuvrierReport(Ouvrier worker) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final String currentMonthPrefix = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    
    final int joursTravailles = worker.joursPointes
        .where((date) => date.startsWith(currentMonthPrefix))
        .length;

    final double totalDu = joursTravailles * worker.salaireJournalier;

    final List<String> moisFr = [
      "", "Janvier", "Février", "Mars", "Avril", "Mai", "Juin", 
      "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("GESTION CHANTIER PRO", 
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text("Fiche de Paie Officielle", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text("Le: ${now.day} ${moisFr[now.month]} ${now.year}"),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text("BULLETIN DE PAIE", 
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("EMPLOYÉ : ${worker.nom.toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text("Poste : ${worker.specialite}"),
                      pw.Text("Période : ${moisFr[now.month]} ${now.year}"),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  headers: ['Désignation', 'Quantité', 'Prix Unitaire', 'Total'],
                  data: [
                    ['Travail (${moisFr[now.month]})', '$joursTravailles jours', '${worker.salaireJournalier.toStringAsFixed(2)} €', '${totalDu.toStringAsFixed(2)} €'],
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      color: PdfColors.grey200,
                      child: pw.Text("NET À PAYER : ${totalDu.toStringAsFixed(2)} €", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Signature de l'ouvrier", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                    pw.Text("Cachet Entreprise", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Fiche_Paie_${worker.nom}.pdf',
    );
  }
}