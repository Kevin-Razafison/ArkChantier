import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/chantier_model.dart';

class ChantierMapPreview extends StatefulWidget {
  final List<Chantier> chantiers;
  final Chantier chantierActuel; // <-- AJOUT : On passe le chantier sélectionné

  const ChantierMapPreview({
    super.key,
    required this.chantiers,
    required this.chantierActuel,
  });

  @override
  State<ChantierMapPreview> createState() => _ChantierMapPreviewState();
}

class _ChantierMapPreviewState extends State<ChantierMapPreview> {
  // Le contrôleur qui permet de manipuler la carte (zoom, déplacement)
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant ChantierMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    // REDIRECTION : Si le chantier sélectionné change, on déplace la carte
    if (oldWidget.chantierActuel.id != widget.chantierActuel.id) {
      _moveToCurrentChantier();
    }
  }

  void _moveToCurrentChantier() {
    final lat = widget.chantierActuel.latitude;
    final lon = widget.chantierActuel.longitude;

    // SÉCURITÉ ZOOM FINITE : On ne déplace que si les coordonnées sont valides
    if (lat != 0 && lon != 0 && !lat.isNaN && !lon.isNaN) {
      _mapController.move(LatLng(lat, lon), 13.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrage des chantiers valides pour les marqueurs
    final validChantiers = widget.chantiers
        .where((c) => c.latitude != 0 && !c.latitude.isNaN)
        .toList();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey[900] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController, // <-- LIEN AVEC LE CONTRÔLEUR
            options: MapOptions(
              initialCenter: LatLng(
                widget.chantierActuel.latitude != 0
                    ? widget.chantierActuel.latitude
                    : 20.0,
                widget.chantierActuel.longitude != 0
                    ? widget.chantierActuel.longitude
                    : 0.0,
              ),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.votreapp.chantier',
                tileBuilder: isDark ? _darkMapFilter : null,
              ),
              MarkerLayer(
                markers: validChantiers.map((chantier) {
                  // Effet visuel : Le marqueur actuel est plus gros ou différent
                  final bool isSelected =
                      chantier.id == widget.chantierActuel.id;

                  return Marker(
                    point: LatLng(chantier.latitude, chantier.longitude),
                    width: 100,
                    height: 70,
                    child: _buildMarkerWidget(
                      context,
                      chantier.nom,
                      isSelected,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(left: 10, top: 10, child: _buildLiveBadge()),
        ],
      ),
    );
  }

  // --- LES MÊMES MÉTHODES DE FILTRE ET BADGE QUE TU AVAIS ---
  // (Inclus ici _darkMapFilter, _buildMarkerWidget mis à jour, et _buildLiveBadge)

  Widget _buildMarkerWidget(
    BuildContext context,
    String name,
    bool isSelected,
  ) {
    return Column(
      children: [
        Icon(
          Icons.location_on,
          color: isSelected
              ? Colors.orange
              : Colors.red, // Orange si sélectionné
          size: isSelected ? 40 : 30,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _darkMapFilter(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    // Ton filtre matriciel actuel...
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        -0.2126,
        -0.7152,
        -0.0722,
        0,
        255,
        -0.2126,
        -0.7152,
        -0.0722,
        0,
        255,
        -0.2126,
        -0.7152,
        -0.0722,
        0,
        255,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tileWidget,
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.white),
          SizedBox(width: 4),
          Text(
            "LIVE MAP",
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
