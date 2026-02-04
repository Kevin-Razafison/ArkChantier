import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/chantier_model.dart';

class ChantierMapPreview extends StatelessWidget {
  final List<Chantier> chantiers;

  const ChantierMapPreview({super.key, required this.chantiers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Déterminer le centre de la carte (premier chantier ou Paris par défaut)
    final LatLng initialCenter = chantiers.isNotEmpty
        ? LatLng(chantiers.first.latitude, chantiers.first.longitude)
        : const LatLng(48.8566, 2.3522);

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
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 10.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // Permet de bouger et zoomer
              ),
            ),
            children: [
              // Couche de la carte (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.votreapp.chantier',
                // Filtre sombre pour le mode dark (optionnel mais stylé)
                tileBuilder: isDark
                    ? (context, tileWidget, tile) => ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -1,
                          0,
                          0,
                          0,
                          255,
                          0,
                          -1,
                          0,
                          0,
                          255,
                          0,
                          0,
                          -1,
                          0,
                          255,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: tileWidget,
                      )
                    : null,
              ),

              // Couche des Marqueurs
              MarkerLayer(
                markers: chantiers.map((chantier) {
                  return Marker(
                    point: LatLng(chantier.latitude, chantier.longitude),
                    width: 100,
                    height: 60,
                    child: _buildMarkerWidget(context, chantier.nom),
                  );
                }).toList(),
              ),
            ],
          ),

          // Indicateur Live
          Positioned(left: 10, top: 10, child: _buildLiveBadge()),
        ],
      ),
    );
  }

  Widget _buildMarkerWidget(BuildContext context, String name) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Chantier : $name"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        children: [
          const Icon(Icons.location_on, color: Colors.red, size: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
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
      ),
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
