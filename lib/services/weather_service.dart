import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temp;
  final String description;
  final String iconCode;
  final double windSpeed;

  WeatherData({
    required this.temp,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temp: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }
}

class WeatherService {
  static const String _apiKey = "0522f5152941dfa624176e1b01842242";

  static Future<WeatherData?> fetchWeather(String city) async {
    // Éviter de lancer une requête inutile pour une ville invalide
    if (city.isEmpty || city == "N/A") return null;

    try {
      // Utilisation de Uri pour un encodage propre des caractères spéciaux
      final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'q': city.trim(),
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'fr',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        // Log de l'erreur pour voir si c'est un problème de ville introuvable (404)
        debugPrint("Erreur API : ${response.statusCode} pour la ville : $city");
        return null;
      }
    } catch (e) {
      debugPrint("Erreur connexion météo: $e");
      return null;
    }
  }

  static Future<WeatherData?> fetchWeatherByCoords(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'fr',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Erreur météo par coordonnées: $e");
    }
    return null;
  }
}
