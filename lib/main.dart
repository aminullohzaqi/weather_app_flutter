import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Position? _currentPosition;
  bool _isLoading = true;
  Map? _responseCurent;
  Map? _responseHourly;
  Map? _responseDaily;
  Map<String, List<dynamic>> _hourlyForecast = {};
  Map<String, List<dynamic>> _dailyForecast = {};

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  defineWeatherIcon(int weatherCode, [int isDay = 1]) {
    if (isDay == 1) {
      if (weatherCode == 0) {
        return WeatherIcons.day_sunny;
      } else if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) {
        return WeatherIcons.day_cloudy;
      } else if (weatherCode == 45 || weatherCode == 48) {
        return WeatherIcons.day_fog;
      } else if (weatherCode == 51 || weatherCode == 53 || weatherCode == 55 || weatherCode == 56 || weatherCode == 57) {
        return WeatherIcons.day_sleet;
      } else if (weatherCode == 61 || weatherCode == 63 || weatherCode == 65 || weatherCode == 66 || weatherCode == 67) {
        return WeatherIcons.day_rain_wind;
      } else if (weatherCode == 80 || weatherCode == 81 || weatherCode == 82) {
        return WeatherIcons.showers;
      } else if (weatherCode == 95 || weatherCode == 96 || weatherCode == 99) {
        return WeatherIcons.thunderstorm;
      }
    } else {
      if (weatherCode == 0) {
        return WeatherIcons.night_clear;
      } else if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) {
        return WeatherIcons.night_cloudy;
      } else if (weatherCode == 45 || weatherCode == 48) {
        return WeatherIcons.night_fog;
      } else if (weatherCode == 51 || weatherCode == 53 || weatherCode == 55 || weatherCode == 56 || weatherCode == 57) {
        return WeatherIcons.night_sleet;
      } else if (weatherCode == 61 || weatherCode == 63 || weatherCode == 65 || weatherCode == 66 || weatherCode == 67) {
        return WeatherIcons.night_rain_wind;
      } else if (weatherCode == 80 || weatherCode == 81 || weatherCode == 82) {
        return WeatherIcons.showers;
      } else if (weatherCode == 95 || weatherCode == 96 || weatherCode == 99) {
        return WeatherIcons.thunderstorm;
      }
    }
  }

  defineWeatherCondition(int weatherCode) {
    if (weatherCode == 0) {
      return "Cerah";
    } else if (weatherCode == 1 || weatherCode == 2 || weatherCode == 3) {
      return "Sebagian Berawan";
    } else if (weatherCode == 45 || weatherCode == 48) {
      return "Berkabut";
    } else if (weatherCode == 51 || weatherCode == 53 || weatherCode == 55 || weatherCode == 56 || weatherCode == 57) {
      return "Hujan Ringan";
    } else if (weatherCode == 61 || weatherCode == 63 || weatherCode == 65 || weatherCode == 66 || weatherCode == 67) {
      return "Hujan";
    } else if (weatherCode == 80 || weatherCode == 81 || weatherCode == 82) {
      return "Hujan Lebat";
    } else if (weatherCode == 95 || weatherCode == 96 || weatherCode == 99) {
      return "Hujan Badai";
    }
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      await _fetchPosts();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPosts() async {
    if (_currentPosition == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final lat = _currentPosition!.latitude;
      final lon = _currentPosition!.longitude;
      final now = DateTime.now().toUtc().add(const Duration(hours: 7));
      final dateTime = DateTime(now.year, now.month, now.day, now.hour);
      final formattedString = DateFormat("yyyy-MM-dd'T'HH:mm").format(dateTime);
      final formattedStringDateOnly = DateFormat("yyyy-MM-dd").format(dateTime);

      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,wind_speed_10m_max&hourly=temperature_2m,weather_code,relative_humidity_2m,dew_point_2m,precipitation_probability,surface_pressure,wind_speed_10m,visibility,uv_index,is_day&current=temperature_2m,relative_humidity_2m,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,apparent_temperature&timezone=Asia%2FBangkok');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          var resp = jsonDecode(response.body);
          _responseCurent = resp['current'];
          _responseHourly = resp['hourly'];
          _responseDaily = resp['daily'];

          if (_responseCurent != null) {
            final humidity = _responseCurent?['relative_humidity_2m'];
            if (humidity < 50) {
              _responseCurent?['relative_humidity_2m_str'] = 'Rendah';
            } else if (humidity < 75) {
              _responseCurent?['relative_humidity_2m_str'] = 'Sedang';
            } else {
              _responseCurent?['relative_humidity_2m_str'] = 'Tinggi';
            }
          }

          if (_responseHourly != null) {
            final int index = _responseHourly?['time'].indexOf(formattedString);
            _responseCurent?['uv_index'] = _responseHourly?['uv_index'][index];
            if (_responseCurent?['uv_index'] < 3) {
              _responseCurent?['uv_index_str'] = 'Rendah';
            } else if (_responseCurent?['uv_index'] < 6) {
              _responseCurent?['uv_index_str'] = 'Sedang';
            } else if (_responseCurent?['uv_index'] < 8) {
              _responseCurent?['uv_index_str'] = 'Tinggi';
            } else if (_responseCurent?['uv_index'] < 11) {
              _responseCurent?['uv_index_str'] = 'Sangat Tinggi';
            } else {
              _responseCurent?['uv_index_str'] = 'Ekstrim';
            }

            _hourlyForecast['time'] = [];
            _hourlyForecast['weather_code'] = [];
            _hourlyForecast['temperature_2m'] = [];
            _hourlyForecast['precipitation_probability'] = [];
            _hourlyForecast['icon'] = [];

            for (int i = index; i < index + 24; i++) {
              final time = DateTime.parse(_responseHourly?['time'][i]);
              final formattedTime = DateFormat('HH:mm').format(time);
              final weatherCode = _responseHourly?['weather_code'][i];
              final temperature2m = _responseHourly?['temperature_2m'][i];
              final precipitationProbability = _responseHourly?['precipitation_probability'][i];
              final isDay = _responseHourly?['is_day'][i];
              final icon = defineWeatherIcon(weatherCode, isDay);

              _hourlyForecast['time']!.add(formattedTime);
              _hourlyForecast['weather_code']!.add(weatherCode);
              _hourlyForecast['temperature_2m']!.add(temperature2m);
              _hourlyForecast['precipitation_probability']!.add(precipitationProbability);
              _hourlyForecast['icon']!.add(icon);
            }
          }

          if (_responseDaily != null) {
            final int index = _responseDaily?['time'].indexOf(formattedStringDateOnly);
            _responseCurent?['sunrise'] = DateFormat('HH:mm').format(DateTime.parse(_responseDaily?['sunrise'][index]));
            _responseCurent?['sunset'] = DateFormat('HH:mm').format(DateTime.parse(_responseDaily?['sunset'][index]));

            _dailyForecast['day'] = [];
            _dailyForecast['precipitation_sum'] = [];
            _dailyForecast['temp_min'] = [];
            _dailyForecast['temp_max'] = [];
            _dailyForecast['weather_code'] = [];
            _dailyForecast['icon'] = [];
            
            for (int i = index; i < index + 7; i++) {
              final time = DateTime.parse(_responseDaily?['time'][i]);
              final day = DateFormat('E').format(time);
              final precipitationSum = _responseDaily?['precipitation_sum'][i];
              final tempMin = _responseDaily?['temperature_2m_min'][i];
              final tempMax = _responseDaily?['temperature_2m_max'][i];
              final weatherCode = _responseDaily?['weather_code'][i];
              final icon = defineWeatherIcon(weatherCode);
              if (i == index) {
                _dailyForecast['day']!.add('Today');
              } else {
                _dailyForecast['day']!.add(day);
              }
              _dailyForecast['precipitation_sum']!.add(precipitationSum);
              _dailyForecast['temp_min']!.add(tempMin);
              _dailyForecast['temp_max']!.add(tempMax);
              _dailyForecast['weather_code']!.add(weatherCode);
              _dailyForecast['icon']!.add(icon);
            }
          }

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load posts');
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: (_responseCurent?['is_day'] ?? 1) == 0
                ? [const Color(0xFF020D1E), const Color(0xFF2A4B7C)]
                : [const Color(0xFF4A90E2), const Color(0xFF87CEEB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.white),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Gunung Sahari Selatan',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] 
                ),
              ) ,
            ),
            body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 16.0, right: 16.0, bottom: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text('${_responseCurent?['temperature_2m'] ?? 'N/A'}°C', style: TextStyle(fontSize: 50, color: Colors.white)),
                                  ]
                                ),
                                Row(
                                  children: [
                                    Text(defineWeatherCondition(_responseCurent?['weather_code'] ?? 0), 
                                      style: TextStyle(
                                      fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                                  ]
                                ),
                                const SizedBox(height: 50),
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward, color: Color.fromARGB(255, 188, 188, 188)),
                                    Text(
                                      '${_dailyForecast['temp_max']?[0] ?? 'N/A'}°', 
                                      style: TextStyle(
                                        fontSize: 16, color: Color.fromARGB(255, 188, 188, 188)
                                      )
                                    ),
                                    Text(
                                      " / ", 
                                      style: TextStyle(
                                        fontSize: 16, color: Color.fromARGB(255, 188, 188, 188)
                                      )
                                    ),
                                    Icon(Icons.arrow_downward, color: Color.fromARGB(255, 188, 188, 188)),
                                    Text(
                                      '${_dailyForecast['temp_min']?[0] ?? 'N/A'}°', 
                                      style: TextStyle(
                                        fontSize: 16, color: Color.fromARGB(255, 188, 188, 188)
                                      )
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("Terasa seperti ${_responseCurent?['apparent_temperature'] ?? 'N/A'}°", 
                                      style: TextStyle(
                                        fontSize: 16, color: Color.fromARGB(255, 188, 188, 188)
                                    ))
                                  ],
                                ),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Icon(defineWeatherIcon(_responseCurent?['weather_code'] ?? 0, _responseCurent?['is_day'] ?? 1), size: 90, color: Colors.white),
                        )
                      ],
                    ),
                    
                    Container(
                      margin: const EdgeInsets.only(top: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4B7C).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prakiraan per jam',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const Divider(color: Colors.white24, height: 32),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _hourlyForecast['time']?.length,
                              itemBuilder: (context, index) {
                                final time = _hourlyForecast['time']?[index];
                                final temp = _hourlyForecast['temperature_2m']?[index];
                                final icon = _hourlyForecast['icon']?[index];
                                final precip = _hourlyForecast['precipitation_probability']?[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text('${time ?? 'N/A'}', style: const TextStyle(color: Colors.white70)),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
                                        child: Icon(icon, color: Colors.white, size: 32),
                                      ),
                                      Text('${temp ?? 'N/A'}°', style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      const SizedBox(height: 20),
                                      const Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 16),
                                      Text(
                                        '${precip ?? 'N/A'}%',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 16.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4B7C).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _dailyForecast['day']?.length,
                        itemBuilder: (context, index) {
                          final day = _dailyForecast['day']?[index];
                          final precip = _dailyForecast['precipitation_sum']?[index];
                          final icon = _dailyForecast['icon']?[index];
                          final tempMin = _dailyForecast['temp_min']?[index];
                          final tempMax = _dailyForecast['temp_max']?[index];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80, 
                                  child: Text(
                                    '${day ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                
                                if (precip != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(precip) ?? 'N/A'} mm',
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ],
                                  ),
              
                                const Spacer(),
              
                                if (icon != null)
                                  Icon(icon, color: Colors.white, size: 24),
                                
                                const Spacer(),
                                if (tempMax != null && tempMin != null)
                                  Row(
                                    children: [
                                      Text(
                                        '${tempMin ?? 'N/A'}°',
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                      Text(
                                        ' - ${tempMax ?? 'N/A'}°',
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 16.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4B7C).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(WeatherIcons.windy, color: Colors.white, size: 100),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Kecepatan Angin", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  Text("${_responseCurent?['wind_speed_10m'] ?? 'N/A'} km/h", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20),
                                  Text("Arah Angin", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  Text("${_responseCurent?['wind_direction_10m'] ?? 'N/A'}°", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                ]
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A4B7C).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 14),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text("Index UV", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                                      child: Text("${_responseCurent?['uv_index'] ?? 'N/A'}", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("${_responseCurent?['uv_index_str'] ?? 'N/A'}", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (_responseCurent?['uv_index'] ?? 0) / 10,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.redAccent,
                                        minHeight: 10,
                                        borderRadius: BorderRadius.circular(5), // Makes the corners rounded
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A4B7C).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.water_drop_rounded, color: Colors.white, size: 14),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text("Kelembaban", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                                      child: Text("${_responseCurent?['relative_humidity_2m'] ?? 'N/A'} %", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("${_responseCurent?['relative_humidity_2m_str'] ?? 'N/A'}%", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: (_responseCurent?['relative_humidity_2m'] ?? 0) / 100 ,
                                        backgroundColor: Colors.grey[300],
                                        color: Colors.blue,
                                        minHeight: 10,
                                        borderRadius: BorderRadius.circular(5), // Makes the corners rounded
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A4B7C).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(WeatherIcons.rain, color: Colors.white, size: 14),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text("Curah Hujan", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                                      child: Text("${_responseCurent?['precipitation'] ?? 'N/A'}", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("mm", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 16.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A4B7C).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(WeatherIcons.barometer, color: Colors.white, size: 14),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text("Tekanan Udara", style: TextStyle(color: Colors.white, fontSize: 14)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                                      child: Text("${_responseCurent?['surface_pressure'] ?? 'N/A'}", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text("hPa", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 16.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4B7C).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Icon(WeatherIcons.horizon_alt, color: Colors.white, size: 100),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Matahari Terbit", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  Text("${_responseCurent?['sunrise'] ?? 'N/A'}", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 20),
                                  Text("Matahari Terbenam", style: TextStyle(color: Colors.white, fontSize: 14)),
                                  Text("${_responseCurent?['sunset'] ?? 'N/A'}", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                ]
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
