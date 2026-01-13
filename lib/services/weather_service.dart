import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  // OPOMBA: Zamenjaj s svojim API ključem iz https://openweathermap.org/api
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> getWeatherByCity(String city) async {
    final url = Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric&lang=sl');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Weather.fromJson(json);
      } else if (response.statusCode == 401) {
        throw WeatherException('Neveljaven API ključ. Preveri OpenWeather API key.');
      } else if (response.statusCode == 404) {
        throw WeatherException('Mesto ni najdeno.');
      } else {
        throw WeatherException('Napaka pri pridobivanju vremena: ${response.statusCode}');
      }
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Napaka omrežja. Preveri internetno povezavo.');
    }
  }

  // Mock podatki za testiranje brez API ključa
  Future<Weather> getMockWeather() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulacija omrežja
    return Weather(
      cityName: 'Ljubljana',
      temperature: 18.5,
      description: 'delno oblačno',
      icon: '02d',
      humidity: 65,
      windSpeed: 3.2,
    );
  }
}

class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);
  
  @override
  String toString() => message;
}
