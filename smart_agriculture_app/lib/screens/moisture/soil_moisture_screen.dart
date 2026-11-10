import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/crop.dart';
import '../../models/farm.dart';
import '../../models/soil_reading.dart';
import '../../models/weather_data.dart';
import '../../services/location_service.dart';
import '../../services/session_service.dart';
import '../../services/soil_water_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/date_formats.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/farm_background.dart';
import '../farm/my_farms_screen.dart';

class SoilMoistureScreen extends StatefulWidget {
  const SoilMoistureScreen({super.key, this.farm});

  final Farm? farm;

  @override
  State<SoilMoistureScreen> createState() => _SoilMoistureScreenState();
}

class _SoilMoistureScreenState extends State<SoilMoistureScreen> {
  List<Farm> _farms = [];
  List<Crop> _crops = [];
  List<SoilReading> _readings = [];
  WeatherData? _weather;
  int? _farmId;
  bool _loading = true;
  bool _saving = false;
  double _moisture = 30;
  double _waterLevel = 40;
  double _usedLitres = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Farm? get _farm {
    for (final farm in _farms) {
      if (farm.id == _farmId) return farm;
    }
    return _farms.isEmpty ? null : _farms.first;
  }

  SoilReading? get _latest => _readings.isEmpty ? null : _readings.first;

  Future<void> _load() async {
    final userId = SessionService.instance.userId;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final farms = await DatabaseHelper.instance.getAllFarms(userId);
      WeatherData? weather;
      try {
        final location = await LocationService.getCurrentLocation();
        weather = await WeatherService.fetchWeather(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      } catch (_) {}
      var selectedId = widget.farm?.id ?? _farmId;
      if (selectedId == null && farms.isNotEmpty) selectedId = farms.first.id;
      var crops = <Crop>[];
      var readings = <SoilReading>[];
      if (selectedId != null) {
        crops = await DatabaseHelper.instance.getCropsForFarm(selectedId);
        readings = await DatabaseHelper.instance.getSoilReadingsForFarm(
          selectedId,
        );
      }
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _farmId = selectedId;
        _crops = crops;
        _readings = readings;
        _weather = weather;
        _loading = false;
        if (readings.isNotEmpty) {
          _moisture = readings.first.moisturePercent;
          _waterLevel = readings.first.waterLevelPercent;
          _usedLitres = readings.first.waterUsedLitres;
        }
      });
      await SoilWaterService.runAutomaticChecks(weather: weather);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectFarm(int id) async {
    setState(() {
      _farmId = id;
      _crops = [];
      _readings = [];
    });
    try {
      final crops = await DatabaseHelper.instance.getCropsForFarm(id);
      final readings = await DatabaseHelper.instance.getSoilReadingsForFarm(id);
      if (!mounted) return;
      setState(() {
        _crops = crops;
        _readings = readings;
        if (readings.isNotEmpty) {
          _moisture = readings.first.moisturePercent;
          _waterLevel = readings.first.waterLevelPercent;
          _usedLitres = readings.first.waterUsedLitres;
        }
      });
    } catch (_) {}
  }

  Future<void> _saveReading() async {
    final userId = SessionService.instance.userId;
    final farm = _farm;
    if (userId == null || farm?.id == null) return;
    final plan = _buildPlan(farm!);
    final minMoisture =
        plan?.minMoisturePercent ??
        SoilWaterService.minimumMoisturePercent(weather: _weather);
    final minLevel =
        plan?.minWaterLevelPercent ??
        SoilWaterService.minimumWaterLevelPercent(weather: _weather);
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.addSoilReading(
        SoilReading(
          userId: userId,
          farmId: farm.id!,
          moisturePercent: _moisture,
          waterLevelPercent: _waterLevel,
          waterUsedLitres: _usedLitres,
          waterRequiredLitres: plan?.requiredLitres ?? 0,
          minMoisturePercent: minMoisture,
          minWaterLevelPercent: minLevel,
          note: '',
          createdAt: DatabaseHelper.instance.now(),
        ),
      );
      await SoilWaterService.runAutomaticChecks(weather: _weather);
      await _load();
      if (!mounted) return;
      final low = _moisture < minMoisture || _waterLevel < minLevel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            low
                ? 'Reading saved. A low level alert was sent.'
                : 'Reading saved. Soil and water levels look good.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteReading(SoilReading reading) async {
    if (reading.id == null) return;
    await DatabaseHelper.instance.deleteSoilReading(reading.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reading deleted')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.countryside,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Soil & Water'),
          actions: [
            IconButton(
              onPressed: _load,
              tooltip: 'Refresh soil and water',
              icon: const Icon(Icons.refresh, color: AppColors.green),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : _farms.isEmpty
            ? _buildNoFarm(context)
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _buildFarmPicker(context),
                    const SizedBox(height: 16),
                    _buildPlanCard(context),
                    const SizedBox(height: 14),
                    _buildStatusCard(context),
                    const SizedBox(height: 14),
                    _buildRecordCard(context),
                    const SizedBox(height: 20),
                    _buildHistory(context),
                  ],
                ),
              ),
      ),
    );
  }

  WaterPlan? _buildPlan(Farm farm) {
    return SoilWaterService.buildPlan(
      farm: farm,
      reading: _latest,
      weather: _weather,
      cropName: SoilWaterService.cropNameFor(farm, _crops),
      growthStage: _crops.isEmpty ? '' : _crops.first.growthStage,
    );
  }

  WaterPlan? get _plan {
    final farm = _farm;
    if (farm == null) return null;
    return _buildPlan(farm);
  }

  Widget _buildNoFarm(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 28),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyState(
              icon: Icons.agriculture,
              title: 'No Farm Added',
              message:
                  'Add a farm first. Then you can record soil moisture '
                  'and water levels for it.',
            ),
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyFarmsScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('ADD A FARM'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child, {EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFarmPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Farm', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _farmId,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.agriculture),
            hintText: 'Choose a farm',
          ),
          items: _farms
              .map(
                (farm) => DropdownMenuItem(
                  value: farm.id,
                  child: Text(
                    farm.farmName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) _selectFarm(value);
          },
        ),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context) {
    final plan = _plan;
    final balance = plan?.balance;
    final weather = _weather;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: AppColors.skyBlue, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Today's Water Need",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: _tag(
                  plan?.weatherBased ?? false ? 'Live weather' : 'Typical day',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            balance == null
                ? 'Add weather data to see the water need.'
                : '${balance.cropName} • ${plan!.farmName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Crop need',
                  value: '${balance?.cropNeedMm.toStringAsFixed(1) ?? '0'} mm',
                  color: AppColors.amberDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  icon: Icons.cloud,
                  label: 'Rain credit',
                  value: '${balance?.rainMm.toStringAsFixed(1) ?? '0'} mm',
                  color: AppColors.skyBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  icon: Icons.local_drink,
                  label: 'Water today',
                  value: _litres(plan?.requiredLitres ?? 0),
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _adviceBox(plan?.advice ?? ''),
          if (weather != null) ...[
            const SizedBox(height: 10),
            _weatherLine(context, weather, plan),
          ],
        ],
      ),
    );
  }

  Widget _weatherLine(
    BuildContext context,
    WeatherData weather,
    WaterPlan? plan,
  ) {
    final area = plan?.areaSquareMetres ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Based on ${_areaLabel(area)}, ${weather.conditionEmoji} '
            '${weather.condition.toLowerCase()}, '
            '${weather.minTemp.round()}° to ${weather.maxTemp.round()}°C.',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textGrey,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final plan = _plan;
    final latest = _latest;
    final status = plan?.status;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: _statusColor(status), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Soil & Water Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Flexible(child: _statusChip(status)),
            ],
          ),
          const SizedBox(height: 16),
          if (latest == null)
            const Text(
              'No reading yet for this farm. Record soil moisture and the '
              'water level to get live advice.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            )
          else ...[
            _gauge(
              label: 'Soil moisture',
              icon: Icons.terrain,
              value: latest.moisturePercent,
              minimum: plan?.minMoisturePercent ?? latest.minMoisturePercent,
              low: latest.isMoistureLow,
            ),
            const SizedBox(height: 16),
            _gauge(
              label: 'Water level (tank or pond)',
              icon: Icons.water,
              value: latest.waterLevelPercent,
              minimum:
                  plan?.minWaterLevelPercent ?? latest.minWaterLevelPercent,
              low: latest.isWaterLevelLow,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule, size: 15, color: AppColors.textGrey),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Last checked ${DateFormats.timeAgo(latest.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _gauge({
    required String label,
    required IconData icon,
    required double value,
    required double minimum,
    required bool low,
  }) {
    final color = low ? AppColors.danger : AppColors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
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
            minHeight: 10,
            backgroundColor: AppColors.paleGreen,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          low
              ? 'Below the safe minimum of ${minimum.round()}%. Water soon.'
              : 'Safe minimum is ${minimum.round()}%.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: low ? AppColors.danger : AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(BuildContext context) {
    final plan = _plan;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: AppColors.green, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Record Reading',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Move the sliders to match your field check.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
          ),
          const SizedBox(height: 10),
          _slider(
            label: 'Soil moisture',
            value: _moisture,
            minimum: plan?.minMoisturePercent ?? 30,
            onChanged: (value) => setState(() => _moisture = value),
          ),
          const SizedBox(height: 10),
          _slider(
            label: 'Water level (tank or pond)',
            value: _waterLevel,
            minimum: plan?.minWaterLevelPercent ?? 25,
            onChanged: (value) => setState(() => _waterLevel = value),
          ),
          const SizedBox(height: 10),
          _slider(
            label: 'Water used today',
            value: _usedLitres,
            minimum: 0,
            max: 6000,
            step: 250,
            onChanged: (value) => setState(() => _usedLitres = value),
            valueLabel: _litres(_usedLitres),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _saving
                ? const SizedBox(
                    height: 54,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _saveReading,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('SAVE READING'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double minimum,
    required ValueChanged<double> onChanged,
    double max = 100,
    double step = 5,
    String? valueLabel,
  }) {
    final low = minimum > 0 && value < minimum;
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
              valueLabel ?? '${value.round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: low ? AppColors.danger : AppColors.primaryDark,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: low ? AppColors.danger : AppColors.green,
            thumbColor: low ? AppColors.danger : AppColors.green,
            overlayColor: (low ? AppColors.danger : AppColors.green).withValues(
              alpha: 0.15,
            ),
            trackHeight: 5,
          ),
          child: Slider(
            value: value.clamp(0, max).toDouble(),
            min: 0,
            max: max,
            divisions: (max / step).round(),
            label: valueLabel ?? '${value.round()}%',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: AppColors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recent Readings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_readings.isNotEmpty)
              Text(
                '${_readings.length} saved',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textGrey,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_readings.isEmpty)
          _card(
            const Text(
              'Your readings will be listed here. Check the field once a day '
              'for the best results.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textGrey,
                height: 1.4,
              ),
            ),
          )
        else
          for (final reading in _readings.take(10)) _readingRow(reading),
      ],
    );
  }

  Widget _readingRow(SoilReading reading) {
    return Dismissible(
      key: ValueKey('reading-${reading.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      onDismissed: (_) => _deleteReading(reading),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (reading.needsWater ? AppColors.danger : AppColors.green)
                    .withValues(alpha: 0.12),
              ),
              child: Icon(
                reading.needsWater ? Icons.warning_amber_rounded : Icons.check,
                size: 20,
                color: reading.needsWater ? AppColors.danger : AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moisture ${reading.moisturePercent.round()}% • '
                    'Water ${reading.waterLevelPercent.round()}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Used ${_litres(reading.waterUsedLitres)} of '
                    '${_litres(reading.waterRequiredLitres)}',
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
            const SizedBox(width: 8),
            Text(
              DateFormats.timeAgo(reading.createdAt),
              style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
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

  Widget _statusChip(WaterStatus? status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              SoilWaterService.statusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.paleGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.green,
        ),
      ),
    );
  }

  Widget _adviceBox(String advice) {
    if (advice.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.paleGreen.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        advice,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Color _statusColor(WaterStatus? status) {
    switch (status) {
      case WaterStatus.healthy:
        return AppColors.green;
      case WaterStatus.stable:
        return AppColors.skyBlue;
      case WaterStatus.low:
        return AppColors.amberDark;
      case WaterStatus.critical:
        return AppColors.danger;
      case null:
        return AppColors.textGrey;
    }
  }

  IconData _statusIcon(WaterStatus? status) {
    switch (status) {
      case WaterStatus.healthy:
        return Icons.check_circle;
      case WaterStatus.stable:
        return Icons.info;
      case WaterStatus.low:
        return Icons.warning_amber_rounded;
      case WaterStatus.critical:
        return Icons.error_outline;
      case null:
        return Icons.help_outline;
    }
  }

  String _litres(double value) => '${value.round()} L';

  String _areaLabel(double squareMetres) {
    if (squareMetres >= 4000) {
      final acres = squareMetres / 4046.86;
      return '${acres.toStringAsFixed(1)} acres';
    }
    if (squareMetres >= 1000) {
      return '${(squareMetres / 10000).toStringAsFixed(2)} hectares';
    }
    return '${squareMetres.round()} square metres';
  }
}
