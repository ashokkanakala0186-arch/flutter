import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/crop.dart';
import '../../models/farm.dart';
import '../../services/session_service.dart';
import '../../widgets/farm_background.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_crop_screen.dart';

class CropMonitoringScreen extends StatefulWidget {
  const CropMonitoringScreen({super.key, this.farm});

  final Farm? farm;

  @override
  State<CropMonitoringScreen> createState() => _CropMonitoringScreenState();
}

class _CropMonitoringScreenState extends State<CropMonitoringScreen> {
  List<Crop> _crops = [];
  Map<int, String> _farmNames = {};
  bool _loading = true;
  final Map<int, MenuController> _menus = {};

  MenuController _menuFor(Crop crop) {
    final id = crop.id ?? 0;
    return _menus.putIfAbsent(id, () => MenuController());
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SessionService.instance.userId;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final farms = await DatabaseHelper.instance.getAllFarms(userId);
      final names = {for (final f in farms) f.id!: f.farmName};
      final List<Crop> crops;
      if (widget.farm != null) {
        crops = await DatabaseHelper.instance.getCropsForFarm(widget.farm!.id!);
      } else {
        crops = await DatabaseHelper.instance.getCropsForUser(userId);
      }
      if (!mounted) return;
      setState(() {
        _crops = crops;
        _farmNames = names;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAddEdit([Crop? crop]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditCropScreen(crop: crop, initialFarm: widget.farm),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteCrop(Crop crop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Crop'),
        content: Text('Are you sure you want to delete "${crop.cropName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteCrop(crop.id!);
    _load();
  }

  String get _title {
    if (widget.farm != null) return 'Crops — ${widget.farm!.farmName}';
    return 'My Crops';
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.sunny,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(_title),
          actions: [
            IconButton(
              onPressed: () => _openAddEdit(),
              icon: const Icon(
                Icons.add_circle,
                color: AppColors.green,
                size: 30,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              )
            : _crops.isEmpty
            ? EmptyState(
                icon: Icons.grass,
                title: 'No Crops Added',
                message:
                    'Add your first crop to monitor planting, growth '
                    'stages, health and notes.',
              )
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: _load,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _crops.length,
                  itemBuilder: (context, index) =>
                      _cropCard(context, _crops[index]),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAddEdit(),
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Crop'),
        ),
      ),
    );
  }

  Widget _cropCard(BuildContext context, Crop crop) {
    final stage = _stageInfo(crop.growthStage);
    final status = _statusInfo(crop.status);
    final farmName = _farmNames[crop.farmId];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: stage.$3,
                  ),
                ),
                child: Icon(stage.$2, color: AppColors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.cropName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    if (farmName != null)
                      Text(
                        'Farm: $farmName',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: status.$1.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.$2, size: 14, color: status.$1),
                    const SizedBox(width: 5),
                    Text(
                      crop.status.isEmpty ? 'Unknown' : crop.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: status.$1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paleGreen.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(stage.$2, size: 16, color: stage.$3.last),
                const SizedBox(width: 6),
                Text(
                  'Growth Stage: ${crop.growthStage.isEmpty ? '—' : crop.growthStage}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event, size: 16, color: AppColors.textGrey),
              const SizedBox(width: 7),
              Text(
                'Planted: ${crop.plantingDate.isEmpty ? '—' : crop.plantingDate}',
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const Spacer(),
              MenuAnchor(
                controller: _menuFor(crop),
                builder: (context, controller, child) => IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.textGrey,
                  ),
                ),
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      _menuFor(crop).close();
                      _openAddEdit(crop);
                    },
                    child: const Text('Edit Crop'),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () {
                      _menuFor(crop).close();
                      _deleteCrop(crop);
                    },
                    child: const Text('Delete Crop'),
                  ),
                ],
              ),
            ],
          ),
          if (crop.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              crop.notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  (String, IconData, List<Color>) _stageInfo(String stage) {
    switch (stage) {
      case 'Seedling':
        return ('Seedling', Icons.spa, [AppColors.lightGreen, AppColors.green]);
      case 'Vegetative':
        return (
          'Vegetative',
          Icons.nature,
          [AppColors.green, AppColors.primary],
        );
      case 'Flowering':
        return (
          'Flowering',
          Icons.local_florist,
          [Color(0xFFF48FB1), Color(0xFFD81B60)],
        );
      case 'Harvest':
        return (
          'Harvest',
          Icons.agriculture,
          [Color(0xFFF9A825), Color(0xFFEF6C00)],
        );
      default:
        return ('Unknown', Icons.eco, [AppColors.green, AppColors.lightGreen]);
    }
  }

  (Color, IconData) _statusInfo(String status) {
    switch (status) {
      case 'Healthy':
        return (AppColors.green, Icons.check_circle);
      case 'Needs Attention':
        return (AppColors.amberDark, Icons.warning_amber_rounded);
      case 'Critical':
        return (AppColors.danger, Icons.error_outline);
      default:
        return (AppColors.textGrey, Icons.help_outline);
    }
  }
}
