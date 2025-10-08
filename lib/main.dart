import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentAddress;
  WeatherData? _weatherData;
  Timer? _timer;

  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchWeatherData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final position = await _weatherService.getCurrentPosition();

      final addressFuture = _weatherService.fetchAddress(position);
      final weatherFuture = _weatherService.fetchWeather(position);

      final address = await addressFuture;
      final weather = await weatherFuture;

      setState(() {
        _currentAddress = address;
        _weatherData = weather;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDay = _weatherData?.current.isDay == 1;
    final gradientColors = isDay
        ? [const Color(0xFF4A90E2), const Color(0xFF87CEEB)]
        : [const Color(0xFF020D1E), const Color(0xFF2A4B7C)];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchWeatherData,
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }
    if (_weatherData == null) {
      return const Center(
          child: Text('No weather data available.',
              style: TextStyle(color: Colors.white)));
    }

    return RefreshIndicator(
      onRefresh: _fetchWeatherData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationHeader(address: _currentAddress ?? 'Unknown Location'),
            const SizedBox(height: 20),
            CurrentWeatherCard(weather: _weatherData!.current, daily: _weatherData!.daily),
            const SizedBox(height: 20),
            HourlyForecastCard(hourly: _weatherData!.hourly),
            const SizedBox(height: 20),
            DailyForecastCard(daily: _weatherData!.daily),
            const SizedBox(height: 20),
            WeatherDetailsRow(icon: WeatherIcons.windy, title: 'Wind Speed', title2: 'Wind Direction', 
              value: _weatherData!.current.windSpeed.toString(),
              value2: _weatherData!.current.windDirection.toString(),
              unit: 'm/s', unit2: '°',),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DetailCard(
                    icon: Icons.wb_sunny_outlined,
                    title: 'UV Index',
                    value: _weatherData!.current.uvIndex.toString(),
                    label: WeatherUtils.getUvIndexString(_weatherData!.current.uvIndex),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetailCard(
                    icon: Icons.water_drop_outlined,
                    title: 'Humidity',
                    value: '${_weatherData!.current.humidity}',
                    label: WeatherUtils.getHumidityString(_weatherData!.current.humidity),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DetailCard(
                    icon: WeatherIcons.barometer,
                    title: 'Pressure',
                    value: '${_weatherData!.current.surfacePressure.round()}',
                    label: 'hPa',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetailCard(
                      icon: WeatherIcons.rain,
                      title: 'Precipitation',
                      value: '${_weatherData!.current.precipitation.round()}',
                      label: 'mm',
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            WeatherDetailsRow(icon: WeatherIcons.horizon_alt, title: 'Sunrise', title2: 'Sunset', 
              value: _weatherData!.current.sunrise,
              value2: _weatherData!.current.sunset),
          ],
        ),
      ),
    );
  }
}

class LocationHeader extends StatelessWidget {
  final String address;
  const LocationHeader({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          address,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class CurrentWeatherCard extends StatelessWidget {
  final CurrentWeather weather;
  final DailyData daily;

  const CurrentWeatherCard({super.key, required this.weather, required this.daily});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather.temperature.round()}°C',
                style: const TextStyle(fontSize: 60, color: Colors.white, fontWeight: FontWeight.w300),
              ),
              Text(
                WeatherUtils.getWeatherCondition(weather.weatherCode),
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                'Feels like ${weather.apparentTemperature.round()}°',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
               Text(
                'H: ${daily.maxTemperatures.first.round()}° / L: ${daily.minTemperatures.first.round()}°',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
          BoxedIcon(
            WeatherUtils.getWeatherIcon(weather.weatherCode, weather.isDay),
            size: 90,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class HourlyForecastCard extends StatelessWidget {
  final HourlyData hourly;
  const HourlyForecastCard({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    return CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Forecast',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 24),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourly.times.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(DateFormat('HH:mm').format(hourly.times[index]), style: const TextStyle(color: Colors.white70)),
                      BoxedIcon(
                        WeatherUtils.getWeatherIcon(hourly.weatherCodes[index], hourly.isDay[index]),
                        color: Colors.white,
                        size: 32,
                      ),
                      Text('${hourly.temperatures[index].round()}°', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Icon(Icons.water_drop_outlined, color: Colors.lightBlueAccent, size: 16),
                      Text('${hourly.precipitationProbabilities[index]}%', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DailyForecastCard extends StatelessWidget {
  final DailyData daily;
  const DailyForecastCard({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    return CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
            '7-Day Forecast',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24, height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daily.times.length,
            itemBuilder: (context, index) {
              final day = index == 0 ? 'Today' : DateFormat('EEE').format(daily.times[index]);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 16))),
                    const Icon(Icons.water_drop_outlined, color: Colors.lightBlueAccent, size: 16),
                    const SizedBox(width: 4),
                    Text('${daily.precipitationSums[index]} mm', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    BoxedIcon(WeatherUtils.getWeatherIcon(daily.weatherCodes[index]), color: Colors.white, size: 24),
                    const Spacer(),
                    Text(
                      '${daily.minTemperatures[index].round()}° / ${daily.maxTemperatures[index].round()}°',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WeatherDetailsRow extends StatelessWidget {
    final IconData icon;
    final String title;
    final String title2;
    final String value;
    final String value2;
    final String? unit;
    final String? unit2;
    const WeatherDetailsRow({super.key, required this.icon, required this.title, required this.value, this.unit, required this.title2, required this.value2, this.unit2});

    @override
    Widget build(BuildContext context) {
        return CardBase(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(icon, color: Colors.white, size: 100),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(color: Colors.white, fontSize: 14)),
                          Text('$value ${unit ?? ''}', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          Text(title2, style: TextStyle(color: Colors.white, fontSize: 14)),
                          Text('$value2 ${unit2 ?? ''}', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ]
                      ),
                    ],
                  ),
                ],
              ),
            ),
        );
    }
}

class DetailCard extends StatelessWidget {
    final IconData icon;
    final String title;
    final String value;
    final String? label;

    const DetailCard({
        super.key,
        required this.icon,
        required this.title,
        required this.value,
        this.label,
    });

    @override
    Widget build(BuildContext context) {
        return CardBase(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Row(
                        children: [
                            Icon(icon, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(title, style: const TextStyle(color: Colors.white70)),
                        ],
                    ),
                    const SizedBox(height: 10),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    if (label != null)
                        const SizedBox(height: 10),
                        Text(label!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    if (title == 'UV Index' || title == 'Humidity')
                        LinearProgressIndicator(
                          value: title == 'UV Index'
                              ? double.parse(value) / 11
                              : double.parse(value) / 100,
                          color: title == 'UV Index'
                              ? Colors.orangeAccent
                              : Colors.lightBlueAccent,
                          backgroundColor: Colors.grey[300],
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5), // Makes the corners rounded
                        ),
                ],
            ),
        );
    }
}

class CardBase extends StatelessWidget {
  final Widget child;
  const CardBase({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(42, 75, 124, 0.3),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: child,
    );
  }
}

class WeatherData {
  final CurrentWeather current;
  final HourlyData hourly;
  final DailyData daily;

  WeatherData({required this.current, required this.hourly, required this.daily});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final hourlyJson = json['hourly'];
    final dailyJson = json['daily'];

    // Find the current hour index to properly align current data with hourly data
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final currentTimeString = DateFormat("yyyy-MM-dd'T'HH:mm").format(DateTime(now.year, now.month, now.day, now.hour));
    final currentHourIndex = (hourlyJson['time'] as List).indexOf(currentTimeString);

    return WeatherData(
      current: CurrentWeather.fromJson(json['current'], hourlyJson, currentHourIndex, dailyJson['sunrise'][0], dailyJson['sunset'][0]),
      hourly: HourlyData.fromJson(hourlyJson, currentHourIndex),
      daily: DailyData.fromJson(dailyJson),
    );
  }
}

class CurrentWeather {
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final int isDay;
  final double precipitation;
  final int weatherCode;
  final double surfacePressure;
  final double windSpeed;
  final int windDirection;
  final double uvIndex;
  final String sunrise;
  final String sunset;

  CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.isDay,
    required this.precipitation,
    required this.weatherCode,
    required this.surfacePressure,
    required this.windSpeed,
    required this.windDirection,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> currentJson, Map<String, dynamic> hourlyJson, int currentIndex, String sunrise, String sunset) {
    final sunriseDateTime = DateTime.parse(sunrise);
    final sunsetDateTime = DateTime.parse(sunset);
    
    return CurrentWeather(
      temperature: currentJson['temperature_2m'],
      apparentTemperature: currentJson['apparent_temperature'],
      humidity: currentJson['relative_humidity_2m'],
      isDay: currentJson['is_day'],
      precipitation: currentJson['precipitation'],
      weatherCode: currentJson['weather_code'],
      surfacePressure: currentJson['surface_pressure'],
      windSpeed: currentJson['wind_speed_10m'],
      windDirection: currentJson['wind_direction_10m'],
      uvIndex: hourlyJson['uv_index'][currentIndex],
      sunrise: DateFormat('HH:mm').format(sunriseDateTime),
      sunset: DateFormat('HH:mm').format(sunsetDateTime),
    );
  }
}

class HourlyData {
  final List<DateTime> times;
  final List<double> temperatures;
  final List<int> weatherCodes;
  final List<int> precipitationProbabilities;
  final List<int> isDay;

  HourlyData({
    required this.times,
    required this.temperatures,
    required this.weatherCodes,
    required this.precipitationProbabilities,
    required this.isDay
  });

  factory HourlyData.fromJson(Map<String, dynamic> json, int startIndex) {
    // We only want the next 24 hours of data
    final endIndex = startIndex + 24;
    return HourlyData(
      times: (json['time'] as List).sublist(startIndex, endIndex).map((t) => DateTime.parse(t)).toList(),
      temperatures: (json['temperature_2m'] as List).sublist(startIndex, endIndex).map((t) => t as double).toList(),
      weatherCodes: (json['weather_code'] as List).sublist(startIndex, endIndex).map((w) => w as int).toList(),
      precipitationProbabilities: (json['precipitation_probability'] as List).sublist(startIndex, endIndex).map((p) => p as int).toList(),
      isDay: (json['is_day'] as List).sublist(startIndex, endIndex).map((d) => d as int).toList(),
    );
  }
}

class DailyData {
  final List<DateTime> times;
  final List<int> weatherCodes;
  final List<double> maxTemperatures;
  final List<double> minTemperatures;
  final List<DateTime> sunrises;
  final List<DateTime> sunsets;
  final List<double> precipitationSums;

  DailyData({
    required this.times,
    required this.weatherCodes,
    required this.maxTemperatures,
    required this.minTemperatures,
    required this.sunrises,
    required this.sunsets,
    required this.precipitationSums,
  });

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      times: (json['time'] as List).map((t) => DateTime.parse(t)).toList(),
      weatherCodes: (json['weather_code'] as List).map((w) => w as int).toList(),
      maxTemperatures: List<double>.from((json['temperature_2m_max'] as List).map((t) => (t as num).toDouble())),
      minTemperatures: List<double>.from((json['temperature_2m_min'] as List).map((t) => (t as num).toDouble())),
      sunrises: (json['sunrise'] as List).map((t) => DateTime.parse(t)).toList(),
      sunsets: (json['sunset'] as List).map((t) => DateTime.parse(t)).toList(),
      precipitationSums: List<double>.from((json['precipitation_sum'] as List).map((p) => (p as num).toDouble())),
    );
  }
}

class WeatherService {
  static const String _weatherApiUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geoApiUrl = 'https://us1.locationiq.com/v1/reverse';

  static const String _geoApiKey = 'pk.bc98f806118d9b793c2981c9535079cd';

  Future<WeatherData> fetchWeather(Position position) async {
    final lat = position.latitude;
    final lon = position.longitude;

    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum',
      'hourly': 'temperature_2m,weather_code,precipitation_probability,is_day,uv_index',
      'current': 'temperature_2m,relative_humidity_2m,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,apparent_temperature',
      'timezone': 'Asia/Bangkok',
    };

    final url = Uri.parse(_weatherApiUrl).replace(queryParameters: params);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<String> fetchAddress(Position position) async {
    final url = Uri.parse('$_geoApiUrl?key=$_geoApiKey&lat=${position.latitude}&lon=${position.longitude}&format=json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];
      // Prioritize city, then suburb, then quarter for the location name
      return address['city'] ?? address['suburb'] ?? address['quarter'] ?? 'Unknown Location';
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}

/// Utility class for weather-related helper functions.
class WeatherUtils {
  static IconData getWeatherIcon(int weatherCode, [int isDay = 1]) {
    switch (weatherCode) {
      case 0:
        return isDay == 1 ? WeatherIcons.day_sunny : WeatherIcons.night_clear;
      case 1:
      case 2:
      case 3:
        return isDay == 1 ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
      case 45:
      case 48:
        return isDay == 1 ? WeatherIcons.day_fog : WeatherIcons.night_fog;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return isDay == 1 ? WeatherIcons.day_sleet : WeatherIcons.night_alt_sleet;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return isDay == 1 ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;
      case 71:
      case 73:
      case 75:
      case 77:
        return isDay == 1 ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;
      case 80:
      case 81:
      case 82:
        return isDay == 1 ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;
      case 95:
      case 96:
      case 99:
        return isDay == 1 ? WeatherIcons.day_thunderstorm : WeatherIcons.night_alt_thunderstorm;
      default:
        return WeatherIcons.na;
    }
  }

  static String getWeatherCondition(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Clear Sky';
      case 1:
      case 2:
      case 3:
        return 'Partly Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  static String getUvIndexString(double uvIndex) {
    if (uvIndex < 3) return 'Low';
    if (uvIndex < 6) return 'Moderate';
    if (uvIndex < 8) return 'High';
    if (uvIndex < 11) return 'Very High';
    return 'Extreme';
  }

  static String getHumidityString(int humidity) {
    if (humidity < 40) return 'Low';
    if (humidity < 70) return 'Normal';
    return 'High';
  }
}
