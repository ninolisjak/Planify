import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String _apiKey = 'f9d2ea0117cfb6e9af01494b623b1d1f';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Privzete koordinate za Ljubljano
  static const double _defaultLat = 46.0569;
  static const double _defaultLon = 14.5058;

  Future<Weather> getWeatherByCoordinates({double? lat, double? lon}) async {
    final latitude = lat ?? _defaultLat;
    final longitude = lon ?? _defaultLon;
    final url = Uri.parse('$_baseUrl?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&lang=sl');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Weather.fromJson(json);
      } else if (response.statusCode == 401) {
        throw WeatherException('Neveljaven API ključ. Preveri OpenWeather API key.');
      } else if (response.statusCode == 404) {
        throw WeatherException('Lokacija ni najdena.');
      } else {
        throw WeatherException('Napaka pri pridobivanju vremena: ${response.statusCode}');
      }
    } catch (e) {
      if (e is WeatherException) rethrow;
      throw WeatherException('Napaka omrežja. Preveri internetno povezavo.');
    }
  }

  // Ohrani staro metodo za združljivost
  Future<Weather> getWeatherByCity(String city) async {
    // Uporabi koordinate za znana mesta
    if (city.toLowerCase() == 'ljubljana') {
      return getWeatherByCoordinates(lat: 46.0569, lon: 14.5058);
    } else if (city.toLowerCase() == 'maribor') {
      return getWeatherByCoordinates(lat: 46.5547, lon: 15.6459);
    }
    // Za druga mesta uporabi privzete koordinate
    return getWeatherByCoordinates();
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
