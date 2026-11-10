class CropAnalysis {
  const CropAnalysis({
    required this.cropName,
    required this.icon,
    required this.condition,
    required this.problems,
    required this.care,
  });

  final String cropName;
  final String icon;
  final String condition;
  final List<String> problems;
  final String care;
}

class AIService {
  AIService._();

  static final AIService instance = AIService._();

  static const List<String> cropTypes = [
    'Tomato',
    'Rice',
    'Chilli',
    'Potato',
    'Cotton',
    'Corn',
    'Wheat',
    'Banana',
    'General Crop',
  ];

  static String cropIcon(String cropName) {
    switch (cropName) {
      case 'Tomato':
        return '🍅';
      case 'Rice':
        return '🌾';
      case 'Chilli':
        return '🌶️';
      case 'Potato':
        return '🥔';
      case 'Cotton':
        return '🌱';
      case 'Corn':
        return '🌽';
      case 'Wheat':
        return '🌿';
      case 'Banana':
        return '🍌';
      default:
        return '🌾';
    }
  }

  String getReply(String question) {
    final q = question.toLowerCase().trim();
    if (q.isEmpty) return _greeting();

    if (_containsAny(q, [
      'hello',
      'hi',
      'hey',
      'good morning',
      'good evening',
      'help me',
      'namaste',
      'assalam',
    ])) {
      return _greeting();
    }
    if (_containsAny(q, ['yellow'])) return _yellowLeaves();
    if (_containsAny(q, ['wilt', 'wilting'])) return _wilting();
    if (_containsAny(q, [
      'pest',
      'insect',
      'bug',
      'aphid',
      'worm',
      'bollworm',
      'caterpillar',
    ])) {
      return _pests();
    }
    if (_containsAny(q, [
      'disease',
      'rot',
      'fungus',
      'fungal',
      'blight',
      'rust',
      'leaf spot',
    ])) {
      return _diseases();
    }
    if (_containsAny(q, [
      'water',
      'watering',
      'irrigation',
      'irrigate',
      'moisture',
      'drip',
    ])) {
      return _watering();
    }
    if (_containsAny(q, [
      'fertilizer',
      'fertiliser',
      'manure',
      'nutrient',
      'nitrogen',
      'compost',
      'urea',
      'potassium',
    ])) {
      return _fertilizer();
    }
    if (_containsAny(q, ['soil', 'drainage', 'land quality'])) return _soil();
    if (_containsAny(q, [
      'weather',
      'rain',
      'raining',
      'hot',
      'cold',
      'sun',
      'wind',
      'fog',
    ])) {
      return _weatherDecisions();
    }
    if (_containsAny(q, [
      'growth',
      'grow',
      'stage',
      'seedling',
      'flowering',
      'harvest',
      'vegetative',
    ])) {
      return _cropGrowth();
    }

    final crop = _matchCrop(q);
    if (crop != null) return _cropCare(crop);

    if (_containsAny(q, ['scan', 'photo', 'image', 'picture', 'camera'])) {
      return _scannerHelp();
    }

    return _fallback();
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  String? _matchCrop(String q) {
    for (final crop in cropTypes) {
      if (crop == 'General Crop') continue;
      if (q.contains(crop.toLowerCase())) return crop;
    }
    if (q.contains('maize')) return 'Corn';
    if (q.contains('brinjal')) return 'Chilli';
    return null;
  }

  String _greeting() {
    return 'Hello Farmer! 🌱\n\n'
        'I am your Smart Agriculture Assistant.\n'
        'I can help you with:\n'
        '🌱 Crop advice\n'
        '💧 Irrigation\n'
        '🐛 Pest problems\n'
        '🦠 Crop diseases\n'
        '🌿 Fertilizers\n'
        '🟤 Soil health\n'
        '🌦️ Weather decisions\n'
        '📷 Crop image analysis\n\n'
        'What would you like help with today?';
  }

  String _yellowLeaves() {
    return 'Why are your leaves yellow?\n\n'
        'Possible reasons include:\n'
        '• Overwatering\n'
        '• Nitrogen deficiency\n'
        '• Poor drainage\n'
        '• Pest attack\n'
        '• Crop disease\n\n'
        'Recommended steps:\n'
        '1. Check soil moisture.\n'
        '2. Inspect the leaves.\n'
        '3. Look for insects.\n'
        '4. Check for brown or black spots.\n'
        '5. Avoid excessive watering.\n\n'
        'If the problem continues, share a photo with the Crop Scanner.';
  }

  String _wilting() {
    return 'Your crop may be wilting because of:\n'
        '• Lack of water\n'
        '• Overwatering or root damage\n'
        '• Extreme heat\n'
        '• Root problems or disease\n\n'
        'Recommended steps:\n'
        '1. Check soil moisture near the roots.\n'
        '2. Water in the early morning or evening.\n'
        '3. Drain extra water if the soil stays wet.\n'
        '4. Protect plants from strong sun.\n'
        '5. Inspect the roots for pests or rot.';
  }

  String _pests() {
    return 'Pest control guidance 🐛\n\n'
        'Steps to control pests:\n'
        '1. Inspect the leaves daily for insects.\n'
        '2. Remove and destroy affected leaves.\n'
        '3. Encourage friendly insects like ladybirds.\n'
        '4. Use a neem-based spray if available.\n'
        '5. Avoid spraying during strong wind.\n\n'
        'If pests increase, ask your local agriculture officer for help.';
  }

  String _diseases() {
    return 'Crop disease guidance 🦠\n\n'
        'Steps:\n'
        '1. Remove and destroy infected parts.\n'
        '2. Improve air flow between plants.\n'
        '3. Avoid overhead watering.\n'
        '4. Keep the field clean of weeds.\n'
        '5. Use the right fungicide after checking with an expert.\n\n'
        'Rain, fog and poor drainage make diseases spread faster.';
  }

  String _watering() {
    return 'Irrigation guidance 💧\n\n'
        'How to water your crops:\n'
        '1. Water in the early morning or evening.\n'
        '2. Check soil moisture before watering.\n'
        '3. Avoid overwatering — wet roots can rot.\n'
        '4. Use drip irrigation to save water.\n'
        '5. Increase watering during the flowering stage.\n\n'
        'Water needs change with the weather. Check the Weather screen daily.';
  }

  String _fertilizer() {
    return 'Fertilizer guidance 🌿\n\n'
        'Steps:\n'
        '1. Test the soil to know the nutrients it needs.\n'
        '2. Use organic manure and compost.\n'
        '3. Apply nitrogen for yellow leaves.\n'
        '4. Apply potassium for fruit and root growth.\n'
        '5. Follow the correct amount — more is not better.\n\n'
        'Always water the field after applying fertilizer.';
  }

  String _soil() {
    return 'Soil health guidance 🟤\n\n'
        'Steps:\n'
        '1. Keep the soil loose and airy.\n'
        '2. Add compost to improve drainage.\n'
        '3. Avoid standing water on the field.\n'
        '4. Rotate crops every season.\n'
        '5. Test the soil once a year.\n\n'
        'Healthy soil grows healthy crops.';
  }

  String _weatherDecisions() {
    return 'Weather decisions for your farm 🌦️\n\n'
        '• Heavy rain: avoid irrigation and check field drainage.\n'
        '• High temperature: check crop moisture, avoid watering in the hottest hours.\n'
        '• Strong wind: avoid spraying pesticides or fertilizers.\n'
        '• Fog: monitor crops for fungal diseases.\n\n'
        'Always check the Weather screen for your exact location.';
  }

  String _cropGrowth() {
    return 'Crop growth guidance 🌱\n\n'
        'Track these stages:\n'
        '• Seedling: protect young plants, water carefully.\n'
        '• Vegetative: apply nitrogen, control weeds.\n'
        '• Flowering: water well, avoid stress.\n'
        '• Harvest: stop irrigation before picking.\n\n'
        'Record each stage in Crop Monitoring.';
  }

  String _cropCare(String cropName) {
    final analysis = analyzeCrop(cropName);
    return '${analysis.icon} ${analysis.cropName} care\n\n'
        'Possible condition:\n${analysis.condition}\n\n'
        'Possible problems:\n'
        '• ${analysis.problems.join('\n• ')}\n\n'
        'Recommended care:\n${analysis.care}';
  }

  String _scannerHelp() {
    return 'Use the Crop Scanner 📷\n\n'
        '1. Open the scanner tab.\n'
        '2. Take a photo of your crop.\n'
        '3. Select the crop type.\n'
        '4. Tap ANALYZE CROP.\n\n'
        'You will get guidance about the possible condition, '
        'problems and recommended care.';
  }

  String _fallback() {
    return 'I did not fully understand that question. 🤔\n\n'
        'I can help you with:\n'
        '• Yellow leaves\n'
        '• Wilting\n'
        '• Pests and insects\n'
        '• Crop diseases\n'
        '• Watering and irrigation\n'
        '• Fertilizers\n'
        '• Soil health\n'
        '• Weather decisions\n\n'
        'Please ask again in simple words.';
  }

  CropAnalysis analyzeCrop(String cropName) {
    switch (cropName) {
      case 'Tomato':
        return const CropAnalysis(
          cropName: 'Tomato',
          icon: '🍅',
          condition: 'Leaves may show yellowing or curling.',
          problems: [
            'Overwatering',
            'Nitrogen deficiency',
            'Poor drainage',
            'Pest attack',
          ],
          care:
              'Check soil moisture. Inspect the leaves for insects. '
              'Remove affected leaves. Avoid excessive watering. '
              'Apply a balanced fertilizer if needed.',
        );
      case 'Rice':
        return const CropAnalysis(
          cropName: 'Rice',
          icon: '🌾',
          condition: 'Possible leaf browning or water stress symptoms.',
          problems: [
            'Water stress',
            'Nitrogen deficiency',
            'Bacterial leaf blight',
            'Pest damage',
          ],
          care:
              'Maintain proper water level. Apply balanced fertilizer. '
              'Monitor leaves for spots. Remove weeds regularly.',
        );
      case 'Chilli':
        return const CropAnalysis(
          cropName: 'Chilli',
          icon: '🌶️',
          condition: 'Possible leaf curl or fruit rot signs.',
          problems: [
            'Aphid attack',
            'Fruit rot',
            'Nutrient deficiency',
            'Excess heat stress',
          ],
          care:
              'Inspect for aphids on young leaves. Improve drainage. '
              'Apply mulch to keep soil cool. Water during early morning.',
        );
      case 'Potato':
        return const CropAnalysis(
          cropName: 'Potato',
          icon: '🥔',
          condition: 'Possible yellowing of lower leaves or late blight.',
          problems: [
            'Late blight',
            'Overwatering',
            'Tuber pests',
            'Potassium deficiency',
          ],
          care:
              'Remove infected leaves. Improve airflow between plants. '
              'Avoid overhead watering. Check tubers for damage.',
        );
      case 'Cotton':
        return const CropAnalysis(
          cropName: 'Cotton',
          icon: '🌱',
          condition: 'Possible leaf spot or pest infestation.',
          problems: [
            'Bollworm attack',
            'Aphids',
            'Nutrient deficiency',
            'Fungal leaf spot',
          ],
          care:
              'Scout for bollworms regularly. Apply pest control carefully. '
              'Use balanced fertilizer. Improve field drainage.',
        );
      case 'Corn':
        return const CropAnalysis(
          cropName: 'Corn',
          icon: '🌽',
          condition: 'Possible yellowing of leaves or stunted growth.',
          problems: [
            'Nitrogen deficiency',
            'Drought stress',
            'Corn borer',
            'Poor soil condition',
          ],
          care:
              'Check soil moisture. Apply nitrogen fertilizer. '
              'Control corn borers. Remove weeds for better nutrition.',
        );
      case 'Wheat':
        return const CropAnalysis(
          cropName: 'Wheat',
          icon: '🌿',
          condition: 'Possible rust spots or yellowing leaves.',
          problems: [
            'Rust disease',
            'Aphids',
            'Nitrogen deficiency',
            'Moisture stress',
          ],
          care:
              'Inspect leaves for rust pustules. Keep leaves dry. '
              'Apply fungicide if needed. Ensure balanced nutrition.',
        );
      case 'Banana':
        return const CropAnalysis(
          cropName: 'Banana',
          icon: '🍌',
          condition: 'Possible leaf yellowing or black spots.',
          problems: [
            'Yellow Sigatoka leaf spot',
            'Nutrient deficiency',
            'Poor drainage',
            'Panama disease',
          ],
          care:
              'Remove infected leaves. Improve soil drainage. '
              'Apply potassium-rich fertilizer. Monitor the suckers.',
        );
      default:
        return const CropAnalysis(
          cropName: 'General Crop',
          icon: '🌾',
          condition: 'General signs need closer field inspection.',
          problems: [
            'Nutrient deficiency',
            'Pest attack',
            'Water stress',
            'Soil health issue',
          ],
          care:
              'Examine the soil and leaves closely. Look for insects. '
              'Keep watering and care records. Consult your local '
              'agriculture officer if the problem continues.',
        );
    }
  }
}
