import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherBanner extends StatelessWidget {
  final String city;
  final double? lat;
  final double? lon;

  const WeatherBanner({super.key, required this.city, this.lat, this.lon});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherData?>(
      future: (lat != null && lon != null && lat != 0)
          ? WeatherService.fetchWeatherByCoords(lat!, lon!)
          : WeatherService.fetchWeather(city),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Image.network(
                "https://openweathermap.org/img/wn/${data.iconCode}@2x.png",
                width: 50,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${data.temp.toInt()}°C - ${data.description}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  const Icon(Icons.air, color: Colors.white70, size: 16),
                  Text(
                    "${data.windSpeed} km/h",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
