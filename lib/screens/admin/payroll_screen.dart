import 'package:flutter/material.dart';
import '../../models/ouvrier_model.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../services/pdf_service.dart';

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
  String _searchQuery = '';
  SortType _sortType = SortType.name;
  bool _showOnlyWorked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final ouvriers = await DataStorage.loadTeam("annuaire_global");
    if (!mounted) return;
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

  List<Ouvrier> get _filteredAndSortedOuvriers {
    var filtered = _allOuvriers.where((worker) {
      final matchesSearch = worker.nom.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      if (_showOnlyWorked) {
        final stats = _calculateMonthlyPay(worker);
        return matchesSearch && stats['days'] > 0;
      }

      return matchesSearch;
    }).toList();

    // Tri
    switch (_sortType) {
      case SortType.name:
        filtered.sort((a, b) => a.nom.compareTo(b.nom));
        break;
      case SortType.salary:
        filtered.sort((a, b) {
          final statsA = _calculateMonthlyPay(a);
          final statsB = _calculateMonthlyPay(b);
          return (statsB['total'] as double).compareTo(
            statsA['total'] as double,
          );
        });
        break;
      case SortType.days:
        filtered.sort((a, b) {
          final statsA = _calculateMonthlyPay(a);
          final statsB = _calculateMonthlyPay(b);
          return (statsB['days'] as int).compareTo(statsA['days'] as int);
        });
        break;
    }

    return filtered;
  }

  double get _totalPayroll {
    return _filteredAndSortedOuvriers.fold(0.0, (sum, worker) {
      final stats = _calculateMonthlyPay(worker);
      return sum + (stats['total'] as double);
    });
  }

  int get _totalDaysWorked {
    return _filteredAndSortedOuvriers.fold(0, (sum, worker) {
      final stats = _calculateMonthlyPay(worker);
      return sum + (stats['days'] as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAndSortedOuvriers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Récapitulatif de Paie"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              if (filteredList.isNotEmpty) {
                _exportAllToPdf();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune donnée à exporter'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            tooltip: 'Exporter tout en PDF',
          ),
          PopupMenuButton<SortType>(
            icon: const Icon(Icons.sort),
            tooltip: 'Trier par',
            onSelected: (value) => setState(() => _sortType = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortType.name,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortType == SortType.name
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Nom'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortType.salary,
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: _sortType == SortType.salary
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Salaire'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortType.days,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _sortType == SortType.days
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Jours travaillés'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMonthSelector(),
                _buildStatsCard(),
                _buildSearchAndFilters(),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.people_outline
                                    : Icons.search_off,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? "Aucun ouvrier dans l'annuaire"
                                    : "Aucun résultat",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final worker = filteredList[index];
                              final stats = _calculateMonthlyPay(worker);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: stats['days'] > 0
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: stats['days'] > 0
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    worker.nom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${stats['days']} jour${stats['days'] > 1 ? 's' : ''} travaillé${stats['days'] > 1 ? 's' : ''}",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_money,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${worker.salaireJournalier} ${widget.projet.devise}/jour",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${stats['total']} ${widget.projet.devise}",
                                        style: TextStyle(
                                          color: stats['total'] > 0
                                              ? Colors.green
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.picture_as_pdf,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          PdfService.generateOuvrierReport(
                                            worker,
                                            widget.projet.devise,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '📄 Rapport généré pour ${worker.nom}',
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        },
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Générer PDF individuel',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
      decoration: BoxDecoration(
        color: const Color(0xFF1A334D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => setState(
              () => _selectedDate = DateTime(
                _selectedDate.year,
                _selectedDate.month - 1,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                "${months[_selectedDate.month - 1]} ${_selectedDate.year}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Période de paie',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
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

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.people,
            '${_filteredAndSortedOuvriers.length}',
            'Ouvriers',
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            Icons.calendar_today,
            '$_totalDaysWorked',
            'Jours totaux',
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            Icons.attach_money,
            _totalPayroll.toStringAsFixed(0),
            widget.projet.devise,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un ouvrier...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _showOnlyWorked,
            onChanged: (value) =>
                setState(() => _showOnlyWorked = value ?? false),
            title: const Text(
              'Afficher uniquement les ouvriers ayant travaillé',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _exportAllToPdf() async {
    // Simuler la génération d'un PDF global
    // Dans une vraie application, vous créeriez un PDF avec tous les ouvriers

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Génération du rapport global...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📄 Rapport global généré pour ${_filteredAndSortedOuvriers.length} ouvrier(s)',
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VOIR',
          textColor: Colors.white,
          onPressed: () {
            // Ouvrir le PDF
          },
        ),
      ),
    );
  }
}

enum SortType { name, salary, days }
