import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../widgets/chantier_map_preview.dart';

class FullScreenMapView extends StatelessWidget {
  final List<Chantier> chantiers;
  final Chantier chantierActuel;

  const FullScreenMapView({
    super.key,
    required this.chantiers,
    required this.chantierActuel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(chantierActuel.nom.toUpperCase()),
        backgroundColor: isDark ? const Color(0xFF1A334D) : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Utiliser SizedBox.expand pour forcer le Hero et la Map à remplir tout l'écran
      body: SizedBox.expand(
        child: Hero(
          tag: 'map_preview_hero',
          child: ChantierMapPreview(
            chantiers: chantiers,
            chantierActuel: chantierActuel,
          ),
        ),
      ),
    );
  }
}
