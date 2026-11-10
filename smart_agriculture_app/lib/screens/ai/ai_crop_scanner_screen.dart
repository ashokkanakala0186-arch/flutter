import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../main.dart';
import '../../models/crop_scan.dart';
import '../../services/ai_service.dart';
import '../../services/session_service.dart';
import '../../widgets/farm_background.dart';
import 'ai_crop_advice_screen.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class AICropScannerScreen extends StatefulWidget {
  const AICropScannerScreen({super.key});

  @override
  State<AICropScannerScreen> createState() => _AICropScannerScreenState();
}

class _AICropScannerScreenState extends State<AICropScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _bytes;
  String? _sourcePath;
  String _selectedCrop = 'Tomato';
  bool _analysing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _sourcePath = file.path;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not open the image. Please try again.');
    }
  }

  Future<void> _analyze() async {
    if (_bytes == null || _analysing) return;
    setState(() => _analysing = true);
    final analysis = AIService.instance.analyzeCrop(_selectedCrop);

    final userId = SessionService.instance.userId;
    if (userId != null) {
      await DatabaseHelper.instance.addCropScan(
        CropScan(
          userId: userId,
          cropName: _selectedCrop,
          imagePath: _sourcePath ?? '',
          condition: analysis.condition,
          problem: analysis.problems.join('\n• '),
          care: analysis.care,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _analysing = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AICropAdviceScreen(analysis: analysis, imageBytes: _bytes),
      ),
    );
    if (mounted) _showMessage('Crop scan saved successfully.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.countryside,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Crop Scanner'),
          actions: [
            IconButton(
              onPressed: () => setState(() {
                _bytes = null;
                _sourcePath = null;
              }),
              tooltip: 'Clear photo',
              icon: const Icon(Icons.refresh, color: AppColors.green),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildImagePreview(),
            const SizedBox(height: 14),
            _buildPickButtons(),
            const SizedBox(height: 22),
            _buildCropLabel(context),
            const SizedBox(height: 10),
            _buildCropChips(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: _analysing
                  ? const SizedBox(
                      height: 54,
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _bytes == null ? null : _analyze,
                      icon: const Icon(Icons.search),
                      label: const Text('ANALYZE CROP'),
                    ),
            ),
            if (_bytes == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Add a photo first to analyze your crop.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.green],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.document_scanner,
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
                  'Scan your crop',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Take a photo and get quick guidance for your crop.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final hasImage = _bytes != null;
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasImage ? Colors.transparent : const Color(0xFFB7D5B9),
          width: 1.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.memory(_bytes!, fit: BoxFit.cover, width: double.infinity)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paleGreen,
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    size: 36,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No photo selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use the camera or gallery below',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
    );
  }

  Widget _buildPickButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Open Camera'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        ),
      ],
    );
  }

  Widget _buildCropLabel(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.eco, color: AppColors.green, size: 20),
        const SizedBox(width: 8),
        Text('Select Crop', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildCropChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final crop in AIService.cropTypes)
          ChoiceChip(
            label: Text('${AIService.cropIcon(crop)} $crop'),
            selected: _selectedCrop == crop,
            onSelected: (_) => setState(() => _selectedCrop = crop),
            selectedColor: AppColors.green,
            backgroundColor: AppColors.white,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _selectedCrop == crop
                  ? AppColors.white
                  : AppColors.textDark,
            ),
            showCheckmark: false,
            side: BorderSide(
              color: _selectedCrop == crop
                  ? AppColors.green
                  : const Color(0xFFCFE3D0),
            ),
          ),
      ],
    );
  }
}
