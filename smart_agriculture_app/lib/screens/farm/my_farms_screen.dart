import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/farm.dart';
import '../../services/session_service.dart';
import '../../widgets/farm_background.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_farm_screen.dart';
import 'crop_monitoring_screen.dart';

class MyFarmsScreen extends StatefulWidget {
  const MyFarmsScreen({super.key});

  @override
  State<MyFarmsScreen> createState() => _MyFarmsScreenState();
}

class _MyFarmsScreenState extends State<MyFarmsScreen> {
  List<Farm> _farms = [];
  bool _loading = true;
  final Map<int, MenuController> _menus = {};

  MenuController _menuFor(Farm farm) {
    final id = farm.id ?? 0;
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
    final farms = await DatabaseHelper.instance.getAllFarms(userId);
    if (!mounted) return;
    setState(() {
      _farms = farms;
      _loading = false;
    });
  }

  Future<void> _openAddEdit([Farm? farm]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEditFarmScreen(farm: farm)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteFarm(Farm farm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farm'),
        content: Text(
          'Are you sure you want to delete "${farm.farmName}"? '
          'All crops of this farm will also be removed.',
        ),
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
    await DatabaseHelper.instance.deleteFarm(farm.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('"${farm.farmName}" deleted')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.countryside,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Farms'),
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
            : _farms.isEmpty
            ? EmptyState(
                icon: Icons.agriculture,
                title: 'No Farms Yet',
                message:
                    'Add your first farm to start monitoring your fields, '
                    'crops, weather and alerts.',
              )
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: _load,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: _farms.length,
                  itemBuilder: (context, index) =>
                      _farmCard(context, _farms[index]),
                ),
              ),
        floatingActionButton: _farms.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openAddEdit(),
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Farm'),
              ),
      ),
    );
  }

  Widget _farmCard(BuildContext context, Farm farm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.green],
                    ),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.farmName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      if (farm.mainCrop.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.paleGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.eco,
                                size: 14,
                                color: AppColors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Main Crop: ${farm.mainCrop}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                MenuAnchor(
                  controller: _menuFor(farm),
                  builder: (context, controller, child) => IconButton(
                    onPressed: () => controller.isOpen
                        ? controller.close()
                        : controller.open(),
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textGrey,
                    ),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () {
                        _menuFor(farm).close();
                        _openAddEdit(farm);
                      },
                      leadingIcon: const Icon(Icons.edit, size: 18),
                      child: const Text('Edit Farm'),
                    ),
                    MenuItemButton(
                      onPressed: () {
                        _menuFor(farm).close();
                        _deleteFarm(farm);
                      },
                      leadingIcon: const Icon(Icons.delete_outline, size: 18),
                      child: const Text('Delete Farm'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _detailRow(Icons.location_on, 'Location', farm.location),
            _detailRow(Icons.straighten, 'Farm Size', farm.farmSize),
            _detailRow(Icons.layers, 'Soil Type', farm.soilType),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CropMonitoringScreen(farm: farm),
                  ),
                ),
                icon: const Icon(Icons.grass, size: 18, color: AppColors.green),
                label: const Text('View Crops'),
              ),
            ),
            if (farm.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                farm.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}
