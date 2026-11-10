import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/farm.dart';
import '../../services/session_service.dart';
import '../../widgets/farm_background.dart';

class AddEditFarmScreen extends StatefulWidget {
  const AddEditFarmScreen({super.key, this.farm});

  final Farm? farm;

  @override
  State<AddEditFarmScreen> createState() => _AddEditFarmScreenState();
}

class _AddEditFarmScreenState extends State<AddEditFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _sizeController;
  late final TextEditingController _soilController;
  late final TextEditingController _cropController;
  late final TextEditingController _descriptionController;
  bool _saving = false;

  bool get _isEdit => widget.farm != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.farm?.farmName ?? '');
    _locationController = TextEditingController(
      text: widget.farm?.location ?? '',
    );
    _sizeController = TextEditingController(text: widget.farm?.farmSize ?? '');
    _soilController = TextEditingController(text: widget.farm?.soilType ?? '');
    _cropController = TextEditingController(text: widget.farm?.mainCrop ?? '');
    _descriptionController = TextEditingController(
      text: widget.farm?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _sizeController.dispose();
    _soilController.dispose();
    _cropController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = SessionService.instance.userId;
    if (userId == null) return;
    setState(() => _saving = true);
    final farm = Farm(
      id: widget.farm?.id,
      userId: widget.farm?.userId ?? userId,
      farmName: _nameController.text.trim(),
      location: _locationController.text.trim(),
      farmSize: _sizeController.text.trim(),
      soilType: _soilController.text.trim(),
      mainCrop: _cropController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    try {
      if (_isEdit) {
        await DatabaseHelper.instance.updateFarm(farm);
      } else {
        await DatabaseHelper.instance.addFarm(farm);
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
      scene: FarmScene.sunrise,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(_isEdit ? 'Edit Farm' : 'Add Farm')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Farm Name',
                    prefixIcon: Icon(Icons.agriculture),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Please enter a farm name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'Village, district or area',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sizeController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Size',
                    hintText: 'e.g. 5 acres',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _soilController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Soil Type',
                    hintText: 'e.g. Loamy, Clay, Sandy',
                    prefixIcon: Icon(Icons.layers),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cropController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Main Crop',
                    hintText: 'e.g. Rice, Tomato, Wheat',
                    prefixIcon: Icon(Icons.eco),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Tell us more about your farm…',
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
                          child: Text(_isEdit ? 'UPDATE FARM' : 'SAVE FARM'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
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
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.green],
                ),
              ),
              child: const Icon(
                Icons.agriculture,
                color: AppColors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit ? 'Update your farm' : 'Register your farm',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keep your farm information up to date for better monitoring.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
