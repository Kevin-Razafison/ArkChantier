import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/ouvrier_model.dart';

class PdfService {
  static Future<void> generateOuvrierReport(Ouvrier worker) async {
    final pdf = pw.Document();

    // Simulation de données de pointage
    const int joursTravailles = 22; 
    final double totalDu = joursTravailles * worker.salaireJournalier;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("FICHE DE PAIE SIMPLIFIEE", 
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}"),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Infos Ouvrier
                pw.Text("Ouvrier : ${worker.nom}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text("Spécialité : ${worker.specialite}"),
                pw.Text("ID : ${worker.id}"),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),

                // Tableau des prestations
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                  headers: ['Description', 'Quantite', 'Prix Unitaire', 'Total'],
                  data: [
                    ['Jours travailles (Fevrier)', '$joursTravailles jours', '${worker.salaireJournalier} EUR', '$totalDu EUR'],
                  ],
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.center,
                ),

                pw.Spacer(),

                // Section Signature avec la correction du BORDER
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    children: [
                      pw.Text("Signature de l'employeur", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 60),
                      // --- CORRECTION ICI ---
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(width: 1, color: PdfColors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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