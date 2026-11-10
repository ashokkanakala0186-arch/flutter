import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/crop.dart';
import '../../models/farm.dart';
import '../../services/session_service.dart';
import '../../widgets/farm_background.dart';

class AddEditCropScreen extends StatefulWidget {
  const AddEditCropScreen({super.key, this.crop, this.initialFarm});

  final Crop? crop;
  final Farm? initialFarm;

  @override
  State<AddEditCropScreen> createState() => _AddEditCropScreenState();
}

class _AddEditCropScreenState extends State<AddEditCropScreen> {
  static const List<String> _growthStages = [
    'Seedling',
    'Vegetative',
    'Flowering',
    'Harvest',
  ];

  static const List<String> _statuses = [
    'Healthy',
    'Needs Attention',
    'Critical',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  List<Farm> _farms = [];
  int? _farmId;
  String? _plantingDate;
  String _growthStage = 'Seedling';
  String _status = 'Healthy';
  bool _saving = false;

  bool get _isEdit => widget.crop != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.crop?.cropName ?? '');
    _notesController = TextEditingController(text: widget.crop?.notes ?? '');
    _farmId = widget.crop?.farmId ?? widget.initialFarm?.id;
    _plantingDate = widget.crop?.plantingDate;
    if (widget.crop != null && widget.crop!.growthStage.isNotEmpty) {
      _growthStage = widget.crop!.growthStage;
    }
    if (widget.crop != null && widget.crop!.status.isNotEmpty) {
      _status = widget.crop!.status;
    }
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    final userId = SessionService.instance.userId;
    if (userId == null) return;
    final farms = await DatabaseHelper.instance.getAllFarms(userId);
    if (!mounted) return;
    setState(() {
      _farms = farms;
      if (_farmId == null && farms.isNotEmpty) {
        _farmId = farms.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _plantingDate != null
          ? DateTime.tryParse(_plantingDate!) ?? now
          : now,
      firstDate: DateTime(2019),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select Planting Date',
    );
    if (picked != null) {
      setState(() {
        _plantingDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_farmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a farm before adding crops.')),
      );
      return;
    }
    setState(() => _saving = true);
    final crop = Crop(
      id: widget.crop?.id,
      farmId: _farmId!,
      cropName: _nameController.text.trim(),
      plantingDate: _plantingDate ?? '',
      growthStage: _growthStage,
      status: _status,
      notes: _notesController.text.trim(),
    );
    try {
      if (_isEdit) {
        await DatabaseHelper.instance.updateCrop(crop);
      } else {
        await DatabaseHelper.instance.addCrop(crop);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.sunny,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(_isEdit ? 'Edit Crop' : 'Add Crop')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.paleGreen, AppColors.cardGreen],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.green, AppColors.primary],
                          ),
                        ),
                        child: const Icon(
                          Icons.grass,
                          color: AppColors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crop Monitoring',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track planting, growth stages and crop health.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Crop Name',
                    hintText: 'e.g. Tomato, Rice, Wheat',
                    prefixIcon: Icon(Icons.eco),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Please enter a crop name'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _farmId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Farm',
                    prefixIcon: Icon(Icons.agriculture),
                  ),
                  items: _farms.map((f) {
                    return DropdownMenuItem(
                      value: f.id,
                      child: Text(f.farmName),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _farmId = value),
                  validator: (value) =>
                      value == null ? 'Please select a farm' : null,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Planting Date',
                      prefixIcon: Icon(Icons.event),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.green,
                      ),
                    ),
                    child: Text(
                      _plantingDate ?? 'Select planting date',
                      style: TextStyle(
                        color: _plantingDate == null
                            ? AppColors.textGrey
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _growthStage,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Growth Stage',
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  items: _growthStages
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _growthStage = value ?? 'Seedling'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Crop Status',
                    prefixIcon: Icon(Icons.health_and_safety),
                  ),
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'Healthy'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Watering schedule, fertilizer, observations…',
                    prefixIcon: Icon(Icons.notes, size: 22),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: _saving
                      ? const SizedBox(
                          height: 54,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.green,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _save,
                          child: Text(_isEdit ? 'UPDATE CROP' : 'SAVE CROP'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
