
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Weather {
  final String city;
  final double temperature;
  final String description;
  final String icon;

  Weather({
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      city: json['name'],
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
    );
  }

  String get iconUrl => "https://openweathermap.org/img/w/$icon.png";
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = '43f67914db8d6acc5b2c8631b4003e4b';

  Weather? _weather;
  List<Weather> _forecast = [];
  String? _error;

  Future<void> _fetchWeather(String city) async {
    try {
      final currentRes = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric'));
      final forecastRes = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric'));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        final current = Weather.fromJson(jsonDecode(currentRes.body));
        final forecastJson = jsonDecode(forecastRes.body)['list'] as List;
        final filtered = forecastJson
            .where((e) => e['dt_txt'].contains('12:00:00'))
            .map((e) => Weather(
                  city: city,
                  temperature: e['main']['temp'].toDouble(),
                  description: e['weather'][0]['description'],
                  icon: e['weather'][0]['icon'],
                ))
            .toList();

        setState(() {
          _weather = current;
          _forecast = filtered;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Ciudad no encontrada';
          _weather = null;
          _forecast = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al obtener los datos';
      });
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/');
    setState(() {
      _weather = null;
      _forecast = [];
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ClimaYa'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar ciudad',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _fetchWeather(_controller.text);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
            if (_weather != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _weather!.city,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Temperatura: ${_weather!.temperature}°C'),
                      Text('Descripción: ${_weather!.description}'),
                      Image.network(_weather!.iconUrl),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Pronóstico próximos 5 días",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ..._forecast.map((day) => ListTile(
                    leading: Image.network(day.iconUrl),
                    title: Text('${day.temperature}°C'),
                    subtitle: Text(day.description),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
