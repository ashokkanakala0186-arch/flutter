import 'package:flutter/material.dart';

import '../main.dart';

class AlertStyle {
  AlertStyle._();

  static const List<String> types = [
    'Weather Alert',
    'Irrigation Alert',
    'Crop Alert',
    'Pest Alert',
    'Temperature Alert',
    'Moisture Alert',
    'Water Level Alert',
  ];

  static Color color(String type) {
    switch (type) {
      case 'Weather Alert':
        return AppColors.skyBlue;
      case 'Irrigation Alert':
        return const Color(0xFF0097A7);
      case 'Crop Alert':
        return AppColors.green;
      case 'Pest Alert':
        return AppColors.amberDark;
      case 'Temperature Alert':
        return AppColors.danger;
      case 'Moisture Alert':
        return AppColors.earth;
      case 'Water Level Alert':
        return const Color(0xFF1565C0);
      default:
        return AppColors.green;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case 'Weather Alert':
        return Icons.cloud;
      case 'Irrigation Alert':
        return Icons.water_drop;
      case 'Crop Alert':
        return Icons.grass;
      case 'Pest Alert':
        return Icons.bug_report;
      case 'Temperature Alert':
        return Icons.thermostat;
      case 'Moisture Alert':
        return Icons.terrain;
      case 'Water Level Alert':
        return Icons.water;
      default:
        return Icons.notifications_active;
    }
  }

  static String emoji(String type) {
    switch (type) {
      case 'Weather Alert':
        return '🌦️';
      case 'Irrigation Alert':
        return '💧';
      case 'Crop Alert':
        return '🌱';
      case 'Pest Alert':
        return '🐛';
      case 'Temperature Alert':
        return '🌡️';
      case 'Moisture Alert':
        return '🟤';
      case 'Water Level Alert':
        return '🌊';
      default:
        return '🔔';
    }
  }
}
