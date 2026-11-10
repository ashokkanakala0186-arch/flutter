import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/weather_data.dart';
import '../../services/alert_service.dart';
import '../../services/location_service.dart';
import '../../services/session_service.dart';
import '../../services/soil_water_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/farm_background.dart';
import '../moisture/soil_moisture_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _loading = true;
  String? _error;
  WeatherData? _weather;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final location = await LocationService.getCurrentLocation();
      final weather = await WeatherService.fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _generateAlerts(weather);
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _generateAlerts(WeatherData weather) async {
    final userId = SessionService.instance.userId;
    if (userId == null) return;
    try {
      await AlertService.generateWeatherAlerts(
        userId: userId,
        temperature: weather.temperature,
        humidity: weather.humidity,
        windSpeedKmh: weather.windSpeed,
        isRaining: weather.isRaining,
        isFoggy: weather.isFoggy,
        isThunderstorm: weather.isThunderstorm,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.cloudy,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Farm Weather'),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _load,
              tooltip: 'Refresh weather',
              icon: const Icon(Icons.refresh, color: AppColors.green),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.green),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location and weather…',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ],
                ),
              )
            : _error != null
            ? _buildError(context)
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _buildHeroCard(context),
                    const SizedBox(height: 16),
                    _buildLocationCard(context),
                    const SizedBox(height: 14),
                    _buildInfoCards(context),
                    const SizedBox(height: 14),
                    _buildWaterNeedCard(context),
                    const SizedBox(height: 16),
                    _buildAdviceCard(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFEBEE),
              ),
              child: const Icon(
                Icons.cloud_off,
                size: 46,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load the weather',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _heroGradient() {
    const sunny = [Color(0xFF1E88E5), Color(0xFF4FC3F7)];
    const cloudy = [Color(0xFF78909C), Color(0xFFB0BEC5)];
    const snowy = [Color(0xFF0277BD), Color(0xFF81D4FA)];
    const storm = [Color(0xFF263238), Color(0xFF455A64)];
    const foggy = [Color(0xFF90A4AE), Color(0xFFCFD8DC)];
    const night = [Color(0xFF283593), Color(0xFF5C6BC0)];

    final code = _weather!.weatherCode;
    if (code == 0) return sunny;
    if (code == 1 || code == 2) {
      return const [Color(0xFF42A5F5), Color(0xFF90CAF9)];
    }
    if (code == 3) return cloudy;
    if (code == 45 || code == 48) return foggy;
    if (_weather!.isRaining || code == 95 || code == 96 || code == 99) {
      return storm;
    }
    if (_weather!.isSnowy) return snowy;
    return night;
  }

  Widget _buildHeroCard(BuildContext context) {
    final weather = _weather!;
    final gradient = _heroGradient();
    final time = _shortTime(weather.time);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.4),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Farm Weather',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white.withValues(alpha: 0.95),
                ),
              ),
              Text(
                'Updated $time',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(weather.conditionEmoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 6),
          Text(
            '${weather.temperature.round()}°C',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weather.condition,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFFB9F6CA)),
                SizedBox(width: 8),
                Text(
                  'Real-time weather for your location',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(String iso) {
    try {
      final parts = iso.split('T');
      if (parts.length < 2) return iso;
      final timePart = parts[1];
      final hm = timePart.split(':');
      if (hm.length < 2) return iso;
      return '${hm[0]}:${hm[1]}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildLocationCard(BuildContext context) {
    final weather = _weather!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.skyPale,
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.skyBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📍 Current Farm Location',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Latitude: ${weather.latitude.toStringAsFixed(4)}°\n'
                  'Longitude: ${weather.longitude.toStringAsFixed(4)}°',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    final weather = _weather!;
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            icon: Icons.water_drop,
            color: AppColors.skyBlue,
            label: '💧 Humidity',
            value: '${weather.humidity.round()}%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoCard(
            icon: Icons.air,
            color: AppColors.green,
            label: '💨 Wind Speed',
            value: '${weather.windSpeed.round()} km/h',
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 23, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterNeedCard(BuildContext context) {
    final weather = _weather!;
    final balance = SoilWaterService.dailyBalance(weather: weather);
    final needsWater = balance.netNeedMm >= 1;

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SoilMoistureScreen())),
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.water_drop,
                  color: AppColors.skyBlue,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Today's Water Need",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.skyBlue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _waterMetric(
                    label: 'Crop need',
                    value: '${balance.cropNeedMm.toStringAsFixed(1)} mm',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _waterMetric(
                    label: 'Rain credit',
                    value: '${balance.rainMm.toStringAsFixed(1)} mm',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _waterMetric(
                    label: 'Water today',
                    value: '${balance.netNeedMm.toStringAsFixed(1)} mm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              needsWater
                  ? 'Your crops will use about '
                        '${balance.netNeedMm.toStringAsFixed(1)} mm of water '
                        'today. Tap to see litres for each farm.'
                  : 'The rain should be enough today. Tap to check your soil '
                        'moisture and water levels.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waterMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textGrey,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(BuildContext context) {
    final weather = _weather!;
    final advice = _smartAdvice(weather);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.paleGreen, AppColors.cardGreen],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.amberDark,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Smart Farm Advice',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            advice,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '🔔 Smart alerts were updated based on this weather.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.green.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _smartAdvice(WeatherData weather) {
    if (weather.isThunderstorm) {
      return 'Thunderstorm detected. Stay indoors and avoid field work '
          'until it passes safely.';
    }
    if (weather.isRaining) {
      return 'It is raining. Avoid unnecessary irrigation and '
          'check the field drainage to prevent water logging.';
    }
    if (weather.temperature >= 35) {
      return 'Temperature is high. Check crop moisture and avoid '
          'watering during the hottest hours of the day.';
    }
    if (weather.temperature <= 5) {
      return 'Temperature is very low. Protect young crops from '
          'cold stress, especially at night.';
    }
    if (weather.windSpeed >= 30) {
      return 'Wind is strong. Avoid spraying pesticides or '
          'fertilizers until the wind settles.';
    }
    if (weather.isFoggy) {
      return 'Foggy conditions. Monitor crops for fungal diseases '
          'and improve air flow in the field.';
    }
    if (weather.humidity < 30) {
      return 'Air is dry. Check soil moisture and plan irrigation '
          'to protect your crops.';
    }
    return 'Weather conditions look suitable. Continue monitoring '
        'your crop and soil conditions.';
  }
}
