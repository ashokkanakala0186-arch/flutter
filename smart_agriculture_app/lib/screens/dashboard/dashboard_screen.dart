import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/alert.dart';
import '../../models/crop_scan.dart';
import '../../models/soil_reading.dart';
import '../../models/weather_data.dart';
import '../../services/ai_service.dart';
import '../../services/location_service.dart';
import '../../services/session_service.dart';
import '../../services/soil_water_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/alert_style.dart';
import '../../widgets/dashboard_background.dart';
import '../../widgets/date_formats.dart';
import '../ai/ai_chat_screen.dart';
import '../ai/ai_crop_advice_screen.dart';
import '../ai/ai_crop_scanner_screen.dart';
import '../alerts/alerts_screen.dart';
import '../farm/crop_monitoring_screen.dart';
import '../farm/my_farms_screen.dart';
import '../moisture/soil_moisture_screen.dart';
import '../weather/weather_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _weatherLoading = false;
  int _farmCount = 0;
  int _cropCount = 0;
  int _unreadAlerts = 0;
  List<Alert> _alerts = [];
  List<CropScan> _scans = [];
  List<SoilReading> _soilReadings = [];
  WeatherData? _weather;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = SessionService.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() {
      _weatherLoading = true;
      _weather = null;
    });
    try {
      final farms = await DatabaseHelper.instance.getAllFarms(user.id!);
      final crops = await DatabaseHelper.instance.getCropsForUser(user.id!);
      final alerts = await DatabaseHelper.instance.getAlerts(user.id!);
      final scans = await DatabaseHelper.instance.getCropScans(user.id!);
      final readings = await DatabaseHelper.instance.getLatestSoilReadings(
        user.id!,
      );
      final weather = await _fetchWeather();
      if (!mounted) return;
      setState(() {
        _farmCount = farms.length;
        _cropCount = crops.length;
        _alerts = alerts;
        _scans = scans;
        _soilReadings = readings;
        _unreadAlerts = alerts.where((a) => !a.isRead).length;
        _weather = weather;
        _weatherLoading = false;
        _loading = false;
      });
      await SoilWaterService.runAutomaticChecks(weather: weather);
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherLoading = false;
          _loading = false;
        });
      }
    }
  }

  Future<WeatherData?> _fetchWeather() async {
    try {
      final location = await LocationService.getCurrentLocation();
      return await WeatherService.fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                )
              : RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      _buildHeader(context),
                      _buildWeatherCard(context),
                      _buildStats(context),
                      _buildSoilWaterCard(context),
                      _buildQuickActions(context),
                      _buildAlertsPreview(context),
                      _buildScanPreview(context),
                      _buildAssistantBanner(context),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = SessionService.instance.currentUser?.name ?? 'Farmer';
    final firstName = name.trim().split(' ').first;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.green],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_greeting()}, $firstName 🌾',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              _notificationBell(),
              const SizedBox(width: 12),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(Icons.eco, color: AppColors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormats.current(),
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFFB9F6CA)),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Monitoring active • All systems looking good',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _notificationBell() {
    return Badge(
      isLabelVisible: _unreadAlerts > 0,
      backgroundColor: AppColors.danger,
      label: Text('$_unreadAlerts'),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final weather = _weather;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WeatherScreen())),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E88E5), Color(0xFF4FC3F7)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              if (_weatherLoading)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.white,
                  ),
                )
              else if (weather == null)
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off, color: AppColors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Weather data unavailable. Tap to open Farm Weather.',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  weather.conditionEmoji,
                  style: const TextStyle(fontSize: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${weather.temperature.round()}°C',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.condition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '💧 ${weather.humidity.round()}%',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '💨 ${weather.windSpeed.round()} km/h',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.agriculture,
              _farmCount,
              'Farms',
              AppColors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              Icons.grass,
              _cropCount,
              'Crops',
              AppColors.amberDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              Icons.notifications_active,
              _unreadAlerts,
              'Alerts',
              _unreadAlerts > 0 ? AppColors.danger : AppColors.skyBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, int value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilWaterCard(BuildContext context) {
    final readings = _soilReadings;
    final averageMoisture = SoilWaterService.averageMoisturePercent(readings);
    final averageLevel = SoilWaterService.averageWaterLevelPercent(readings);
    final minMoisture = SoilWaterService.highestRequiredMoisture(readings);
    final minLevel = SoilWaterService.highestRequiredWaterLevel(readings);
    final moistureLow = readings.isNotEmpty && averageMoisture < minMoisture;
    final levelLow = readings.isNotEmpty && averageLevel < minLevel;
    final needing = SoilWaterService.countNeedingWater(readings);
    final subtitle = readings.isEmpty
        ? 'Track soil moisture and water levels'
        : '${readings.length} farm${readings.length == 1 ? '' : 's'} monitored';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SoilMoistureScreen())),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.skyPale,
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: AppColors.skyBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soil & Water',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textGrey),
                ],
              ),
              const SizedBox(height: 14),
              if (readings.isEmpty)
                const Text(
                  'No readings yet. Record soil moisture and the water level '
                  'to get water advice from today\'s weather.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                )
              else ...[
                _soilGauge(
                  'Soil moisture',
                  averageMoisture,
                  minMoisture,
                  moistureLow,
                ),
                const SizedBox(height: 12),
                _soilGauge('Water level', averageLevel, minLevel, levelLow),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      needing > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      size: 16,
                      color: needing > 0 ? AppColors.danger : AppColors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        needing > 0
                            ? '$needing of ${readings.length} farms below the safe level'
                            : 'All farms are above the safe level',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: needing > 0
                              ? AppColors.danger
                              : AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _soilGauge(String label, double value, double minimum, bool low) {
    final color = low ? AppColors.danger : AppColors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.paleGreen,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Safe minimum ${minimum.round()}%',
          style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    const actions = [
      (
        Icons.agriculture,
        'My Farms',
        [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        MyFarmsScreen(),
      ),
      (
        Icons.grass,
        'Crop Information',
        [Color(0xFF00695C), Color(0xFF00897B)],
        CropMonitoringScreen(),
      ),
      (
        Icons.water_drop,
        'Soil & Water',
        [Color(0xFF006064), Color(0xFF0097A7)],
        SoilMoistureScreen(),
      ),
      (
        Icons.wb_sunny,
        'Weather',
        [Color(0xFF0D47A1), Color(0xFF1E88E5)],
        WeatherScreen(),
      ),
      (
        Icons.photo_camera,
        'Crop Scanner',
        [Color(0xFFE65100), Color(0xFFF9A825)],
        AICropScannerScreen(),
      ),
      (
        Icons.support_agent,
        'Ask Assistant',
        [Color(0xFF4E342E), Color(0xFF6D4C41)],
        AIChatScreen(),
      ),
      (
        Icons.notifications_active,
        'Alerts',
        [Color(0xFFB71C1C), Color(0xFFD32F2F)],
        AlertsScreen(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, Icons.touch_app, 'Quick Actions'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 4 : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 104,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return _actionTile(
                    icon: action.$1,
                    label: action.$2,
                    gradient: action.$3,
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => action.$4)),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.32),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.22),
              ),
              child: Icon(icon, size: 20, color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  context,
                  Icons.notifications_active,
                  'Smart Alerts',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _alerts.isEmpty
                ? const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No alerts right now. All clear! 🌿',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _alerts.length && i < 3; i++)
                        _alertRow(_alerts[i]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _alertRow(Alert alert) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _alertColor(alert.type).withValues(alpha: 0.12),
            ),
            child: Icon(
              _alertIcon(alert.type),
              size: 20,
              color: _alertColor(alert.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormats.timeAgo(alert.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
          ),
          if (!alert.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  context,
                  Icons.photo_camera,
                  'Recent Crop Scans',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AICropScannerScreen(),
                  ),
                ),
                child: const Text('Scan now'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _scans.isEmpty
                ? const Row(
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.skyBlue,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No scans yet. Use the Crop Scanner to check your crops.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _scans.length && i < 3; i++)
                        _scanRow(context, _scans[i]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _scanRow(BuildContext context, CropScan scan) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AICropAdviceScreen(
            analysis: CropAnalysis(
              cropName: scan.cropName,
              icon: AIService.cropIcon(scan.cropName),
              condition: scan.condition,
              problems: [scan.problem],
              care: scan.care,
            ),
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paleGreen,
              ),
              alignment: Alignment.center,
              child: Text(
                AIService.cropIcon(scan.cropName),
                style: const TextStyle(fontSize: 21),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.cropName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scan.condition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormats.timeAgo(scan.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AIChatScreen())),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.amber, AppColors.amberDark],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.25),
                ),
                child: const Icon(
                  Icons.support_agent,
                  size: 26,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask your Agriculture Assistant',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Crops • Pests • Weather • Soil • More',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.green, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }

  Color _alertColor(String type) => AlertStyle.color(type);

  IconData _alertIcon(String type) => AlertStyle.icon(type);
}
