import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:weather_app/weather_forecast_item.dart';
import 'additionalinfoitem.dart';
import 'searchBar.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  double temp = 0;
  String city = '';
  bool isLocationEnabled = false;

  @override

  void initState() {
    super.initState();
    _checkLocationPermission();
    _getCurrentLocation();
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    setState(() {
      isLocationEnabled = status.isGranted;
    });
  }

  Future<void> _getCurrentLocation() async {
    if (await Permission.location.isGranted) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        city = placemarks.first.locality.toString();
        isLocationEnabled = true;
        getWeatherData(city);
      });
    } else {
      PermissionStatus status = await Permission.location.request();
      if (status.isGranted) {
        _getCurrentLocation(); // Retry fetching location after permission is granted
      } else {
        setState(() {
          isLocationEnabled = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> getWeatherData(String cityName) async {
    city = cityName;
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=5a1139a980e31152039d863a204837be',
        ),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        print(data['cod']);
        throw 'Location not found';
      }
      dynamic tempData = data['list'][0]['main']['temp'];
      if (tempData is int) {
        temp = tempData.toDouble();
      } else if (tempData is double) {
        temp = tempData;
      } else {
        throw 'Unexpected temperature data type';
      }
      return data;
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            isLocationEnabled ? Icons.location_on : Icons.location_off,
            color: Colors.white,
          ),
          onPressed: () async {
            if (!isLocationEnabled) {
              await Permission.location.request();
              _checkLocationPermission();
              _getCurrentLocation();
            }else if(isLocationEnabled){
              print(isLocationEnabled);
              _getCurrentLocation();            }
          },
        ),
        title: const Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          SearchBarAnimationWidget(
            onSubmitted: (cityName) {
              setState(() {
                getWeatherData(cityName);
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: getWeatherData(city),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];
          final currentTemp = currentWeatherData['main']['temp'];
          final currentSky = currentWeatherData['weather'][0]['main'];
          final pressure = currentWeatherData['main']['pressure'];
          final windspeed = currentWeatherData['wind']['speed'];
          final humidity = currentWeatherData['main']['humidity'];
          final tempincelcius = currentTemp - 273.15;

          return isLocationEnabled ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 10,
                            sigmaY: 10,
                          ),
                          child: Padding(
                            padding:
                            const EdgeInsets.only(top: 16, bottom: 16),
                            child: Column(
                              children: [
                                Text(
                                  '${tempincelcius.toStringAsFixed(2)}° C',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Icon(
                                  currentSky == 'Clouds'
                                      ? Icons.cloud
                                      : currentSky == 'Clear'
                                      ? Icons.wb_sunny
                                      : currentSky == 'Rain'
                                      ? Icons.beach_access
                                      : Icons.wb_twilight,
                                  size: 64,
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Text(
                                  '$currentSky , $city',
                                  style: const TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ),

                const SizedBox(
                  height: 20,
                ),
                // forecast card
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Weather Forecast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < 7; i++)
                        HourlyForecast(
                          time: data['list'][i]['dt_txt']
                              .toString()
                              .substring(11, 16),
                          icon: data['list'][i]['weather'][0]['main'] ==
                              'Clouds'
                              ? Icons.cloud
                              : data['list'][i]['weather'][0]['main'] ==
                              'Clear'
                              ? Icons.wb_sunny
                              : data['list'][i]['weather'][0]['main'] ==
                              'Rain'
                              ? Icons.beach_access
                              : Icons.wb_twilight,
                          temp: (data['list'][i]['main']['temp'] - 273.15)
                              .toStringAsFixed(2),
                        ),
                    ],
                  ),
                ),
                // Additional Information Card
                const SizedBox(
                  height: 16,
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AdditionalnfoItem(
                      icon: Icons.water_drop,
                      label: 'Humidity',
                      value: humidity.toString(),
                    ),
                    AdditionalnfoItem(
                      icon: Icons.air_rounded,
                      label: 'Windspeed',
                      value: windspeed.toString(),
                    ),
                    AdditionalnfoItem(
                      icon: Icons.beach_access,
                      label: 'Pressure',
                      value: pressure.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ) : Center(child: Text('Please Allow Location Access'));
        },
      ),
    );
  }
}
