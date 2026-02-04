import 'package:flutter/material.dart';
import '../models/ouvrier_model.dart';
import '../models/projet_model.dart';
import '../services/data_storage.dart';
import '../services/pdf_service.dart';

class PayrollScreen extends StatefulWidget {
  final Projet projet;

  const PayrollScreen({super.key, required this.projet});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  List<Ouvrier> _allOuvriers = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final ouvriers = await DataStorage.loadTeam("annuaire_global");
    setState(() {
      _allOuvriers = ouvriers;
      _isLoading = false;
    });
  }

  // Calcule le salaire pour un ouvrier sur le mois sélectionné
  Map<String, dynamic> _calculateMonthlyPay(Ouvrier worker) {
    final String monthFilter =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}";

    final daysWorked = worker.joursPointes
        .where((date) => date.startsWith(monthFilter))
        .length;
    final totalDue = daysWorked * worker.salaireJournalier;

    return {'days': daysWorked, 'total': totalDue};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Récapitulatif de Paie"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMonthSelector(),
                Expanded(
                  child: _allOuvriers.isEmpty
                      ? const Center(
                          child: Text("Aucun ouvrier dans l'annuaire"),
                        )
                      : ListView.builder(
                          itemCount: _allOuvriers.length,
                          itemBuilder: (context, index) {
                            final worker = _allOuvriers[index];
                            final stats = _calculateMonthlyPay(worker);

                            if (stats['days'] == 0)
                              return const SizedBox.shrink();

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.payments_outlined),
                                ),
                                title: Text(
                                  worker.nom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${stats['days']} jours travaillés",
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${stats['total']} ${widget.projet.devise}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.picture_as_pdf,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          PdfService.generateOuvrierReport(
                                            worker,
                                            widget.projet.devise,
                                          ),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildMonthSelector() {
    final months = [
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
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
              () => _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month - 1,
              ),
            ),
          ),
          Text(
            "${months[_selectedDate.month - 1]} ${_selectedDate.year}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
              () => _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
