import 'package:flutter/material.dart';

class ChantierMapPreview extends StatelessWidget {
  const ChantierMapPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50], // Simule le fond de la carte
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://tile.openstreetmap.org/12/2048/1361.png'), // Image statique OSM
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Stack(
        children: [
          // On place des "Pins" de chantiers à des positions relatives (%)
          _buildMapPin(top: 0.3, left: 0.4, name: "Chantier Alpha", context: context),
          _buildMapPin(top: 0.6, left: 0.7, name: "Extension Zone B", context: context),
          _buildMapPin(top: 0.4, left: 0.2, name: "Dépôt Central", context: context),
          
          // Petit indicateur de zoom (esthétique)
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              children: [
                _mapButton(Icons.add),
                const SizedBox(height: 5),
                _mapButton(Icons.remove),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin({required double top, required double left, required String name, required BuildContext context}) {
    return Align(
      alignment: Alignment(left * 2 - 1, top * 2 - 1), // Conversion % vers coordonnées Alignment
      child: Tooltip(
        message: name,
        child: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Accès au $name"))),
          child: const Icon(Icons.location_on, color: Colors.red, size: 30),
        ),
      ),
    );
  }

  Widget _mapButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)]),
      child: Icon(icon, size: 18, color: Colors.grey[700]),
    );
  }
}