import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ouvrier_model.dart';

class PdfService {
  static Future<void> generateOuvrierReport(Ouvrier worker) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // --- CALCUL DYNAMIQUE ---
    // On crée le préfixe du mois actuel (ex: "2026-02")
    final String currentMonthPrefix = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    
    // On compte le nombre de jours pointés qui commencent par ce préfixe
    final int joursTravailles = worker.joursPointes
        .where((date) => date.startsWith(currentMonthPrefix))
        .length;

    final double totalDu = joursTravailles * worker.salaireJournalier;

    // Traduction des mois pour l'affichage
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
                // En-tête avec Logo fictif ou Nom de l'entreprise
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

                // Informations Ouvrier
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("EMPLOYÉ : ${worker.nom.toUpperCase()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text("Poste : ${worker.specialite}"),
                      pw.Text("ID Employé : ${worker.id.substring(0, 8)}"),
                      pw.Text("Période : ${moisFr[now.month]} ${now.year}"),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),

                // Tableau des prestations
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  headers: ['Désignation', 'Quantité', 'Prix Unitaire', 'Total'],
                  data: [
                    [
                      'Prestation de travail (${moisFr[now.month]})', 
                      '$joursTravailles jours', 
                      '${worker.salaireJournalier.toStringAsFixed(2)} €', 
                      '${totalDu.toStringAsFixed(2)} €'
                    ],
                  ],
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                ),

                // Total Net
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      color: PdfColors.grey200,
                      child: pw.Text(
                        "NET À PAYER : ${totalDu.toStringAsFixed(2)} €",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // Section Signature
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text("Signature de l'ouvrier", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                        pw.SizedBox(height: 50),
                        pw.Container(width: 120, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text("Cachet de l'entreprise", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 50),
                        pw.Container(
                          width: 150,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text("Généré par l'application Mon Chantier - Document faisant foi", 
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Lancer l'impression ou l'enregistrement
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Fiche_Paie_${worker.nom}_${moisFr[now.month]}.pdf',
    );
  }
}