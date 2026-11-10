import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/ai_service.dart';
import '../../widgets/farm_background.dart';
import 'ai_chat_screen.dart';

class AICropAdviceScreen extends StatelessWidget {
  const AICropAdviceScreen({
    super.key,
    required this.analysis,
    this.imageBytes,
  });

  final CropAnalysis analysis;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return FarmBackground(
      scene: FarmScene.sunrise,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Crop Analysis')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildHeader(context),
            if (imageBytes != null) ...[
              const SizedBox(height: 18),
              _buildImage(),
            ],
            const SizedBox(height: 18),
            _buildConditionCard(context),
            const SizedBox(height: 14),
            _buildProblemsCard(context),
            const SizedBox(height: 14),
            _buildCareCard(context),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AIChatScreen(
                    initialQuestion:
                        'My ${analysis.cropName} crop: ${analysis.condition} What should I do?',
                  ),
                ),
              ),
              icon: const Icon(Icons.support_agent),
              label: const Text('Ask Assistant About This Crop'),
            ),
            const SizedBox(height: 12),
            Text(
              'This guidance is general. Local weather, soil and practices may vary.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
          colors: [AppColors.paleGreen, AppColors.cardGreen],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(analysis.icon, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.cropName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Here is a quick analysis of your crop',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.memory(
        imageBytes!,
        height: 170,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildConditionCard(BuildContext context) {
    return _adviceCard(
      context,
      title: 'Possible Condition',
      icon: Icons.visibility,
      color: AppColors.skyBlue,
      children: [
        Text(
          analysis.condition,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.4,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProblemsCard(BuildContext context) {
    return _adviceCard(
      context,
      title: 'Possible Problems',
      icon: Icons.warning_amber_rounded,
      color: AppColors.amberDark,
      children: [
        for (final problem in analysis.problems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•  ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberDark,
                  ),
                ),
                Expanded(
                  child: Text(
                    problem,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCareCard(BuildContext context) {
    return _adviceCard(
      context,
      title: 'Recommended Care',
      icon: Icons.favorite,
      color: AppColors.green,
      children: [
        Text(
          analysis.care,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _adviceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.13),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
