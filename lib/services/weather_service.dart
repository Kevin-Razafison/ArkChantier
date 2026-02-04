import 'dart:convert';
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
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=${city.trim()}&appid=$_apiKey&units=metric&lang=fr';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print("Erreur météo: $e");
    }
    return null;
  }
}
