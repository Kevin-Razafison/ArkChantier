import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LocationPickerMap extends StatefulWidget {
  final LatLng initialPoint;
  const LocationPickerMap({super.key, required this.initialPoint});

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  LatLng? _selectedPoint;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  // Fonction de recherche via Nominatim (OSM)
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'ChantierApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newPoint = LatLng(lat, lon);

          setState(() {
            _selectedPoint = newPoint;
          });
          _mapController.move(
            newPoint,
            13.0,
          ); // Déplace la carte vers le résultat
        } else {
          _showError("Aucun lieu trouvé.");
        }
      }
    } catch (e) {
      _showError("Erreur de connexion.");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choisir l'emplacement"),
        backgroundColor: const Color(0xFF1A334D),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent, size: 30),
            onPressed: () => Navigator.pop(context, _selectedPoint),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialPoint,
              initialZoom: 5.0,
              onTap: (_, point) => setState(() => _selectedPoint = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.monchantier.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 45,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // BARRE DE RECHERCHE
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Rechercher une ville, un pays...",
                    border: InputBorder.none,
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () =>
                                _searchLocation(_searchController.text),
                          ),
                  ),
                  onSubmitted: _searchLocation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
