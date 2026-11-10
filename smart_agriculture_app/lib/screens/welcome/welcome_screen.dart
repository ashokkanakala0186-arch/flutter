import 'package:flutter/material.dart';

import '../auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to\nSmart Agriculture',
      tagline: 'Smart Farming for a Better Future',
      primaryColor: const Color(0xFF15803D),
      secondaryColor: const Color(0xFF22C55E),
      accentColor: const Color(0xFF86EFAC),
      bgColor1: const Color(0xFFECFDF5),
      bgColor2: const Color(0xFFD1FAE5),
      featureA: FeatureData(
        icon: Icons.agriculture_rounded,
        label: 'Smart Agriculture',
        desc: 'AI-powered farming tools at your fingertips',
        steps: [
          'Create a profile and add your farms and crops in guided steps.',
          'The app listens to your data, not guesses — using the facts you record.',
          'Smart hints help you decide when to water, protect and harvest.',
        ],
      ),
      featureB: FeatureData(
        icon: Icons.home_rounded,
        label: 'Farm Management',
        desc: 'Organize all your farms in one place',
        steps: [
          'Add each farm with name, location, size and soil type.',
          'Register the crops you plant along with their growth stage.',
          'Review every farm and crop at a glance from the dashboard.',
        ],
      ),
    ),
    OnboardingPage(
      title: 'Grow & Protect\nYour Crops',
      tagline: 'Monitor, Track & Stay Weather Ready',
      primaryColor: const Color(0xFFD97706),
      secondaryColor: const Color(0xFFF59E0B),
      accentColor: const Color(0xFFFDE68A),
      bgColor1: const Color(0xFFFFFBEB),
      bgColor2: const Color(0xFFFEF3C7),
      featureA: FeatureData(
        icon: Icons.eco_rounded,
        label: 'Crop Monitoring',
        desc: 'Track growth stages & health in real-time',
        steps: [
          'Log each crop with its current growth stage when you plant it.',
          'Update the condition as the crop develops day by day.',
          'See the health of your whole farm from one monitoring list.',
        ],
      ),
      featureB: FeatureData(
        icon: Icons.wb_sunny_rounded,
        label: 'Weather Updates',
        desc: 'Live temperature, humidity & forecasts',
        steps: [
          'The app detects your farm location automatically.',
          'It fetches live temperature, humidity, wind and sky conditions.',
          'Smart alerts warn you before risky weather arrives.',
        ],
      ),
    ),
    OnboardingPage(
      title: 'Smarter Soil\n& Scanning',
      tagline: 'Irrigation Intelligence Meets Crop Analysis',
      primaryColor: const Color(0xFF0891B2),
      secondaryColor: const Color(0xFF06B6D4),
      accentColor: const Color(0xFFA5F3FC),
      bgColor1: const Color(0xFFECFEFF),
      bgColor2: const Color(0xFFCFFAFE),
      featureA: FeatureData(
        icon: Icons.water_drop_rounded,
        label: 'Soil & Irrigation',
        desc: 'Smart watering schedules for every crop',
        steps: [
          'Record your soil type when creating a farm.',
          'Moisture info is combined with live weather conditions.',
          'Receive watering suggestions timed for each crop.',
        ],
      ),
      featureB: FeatureData(
        icon: Icons.document_scanner_rounded,
        label: 'Crop Scanner',
        desc: 'Scan & diagnose plant diseases instantly',
        steps: [
          'Take a photo of a leaf, fruit or whole plant.',
          'AI analyzes the visual signs of the crop within seconds.',
          'You get the diagnosed problem plus a clear care plan.',
        ],
      ),
    ),
    OnboardingPage(
      title: 'Farm Smarter.\nGrow Better.',
      tagline: 'Your Smart Farming Journey Starts Here',
      primaryColor: const Color(0xFF7C3AED),
      secondaryColor: const Color(0xFF8B5CF6),
      accentColor: const Color(0xFFDDD6FE),
      bgColor1: const Color(0xFFF5F3FF),
      bgColor2: const Color(0xFFEDE9FE),
      featureA: FeatureData(
        icon: Icons.smart_toy_rounded,
        label: 'AI Assistant',
        desc: 'Ask anything about crops, soil & pests',
        steps: [
          'Type a question in your own words, in any way you like.',
          'The assistant answers instantly with practical steps.',
          'Get guidance on planting, pests, weather and soil.',
        ],
      ),
      featureB: FeatureData(
        icon: Icons.rocket_launch_rounded,
        label: 'Get Started',
        desc: 'Begin your smart farming journey today',
        steps: [
          'Create an account or log in to your farm.',
          'Add your first farm and crop in under a minute.',
          'Start monitoring and receive smart guidance every day.',
        ],
      ),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipToLast() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLastPage = _currentPage == _pages.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [page.bgColor1, Colors.white, page.bgColor2],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(isLastPage, page.primaryColor),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildFullPage(_pages[index], size);
                  },
                ),
              ),

              _buildPageIndicator(page.primaryColor),

              const SizedBox(height: 16),

              _buildBottomButton(page.primaryColor, isLastPage),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isLastPage, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _currentPage > 0
              ? IconButton(
                  onPressed: _previousPage,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                  ),
                )
              : const SizedBox(width: 48),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1} / ${_pages.length}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: primaryColor,
              ),
            ),
          ),

          isLastPage
              ? const SizedBox(width: 48)
              : TextButton(
                  onPressed: _skipToLast,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFullPage(OnboardingPage page, Size size) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          _buildHeroIllustration(page, size),

          const SizedBox(height: 20),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: page.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              page.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: page.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildTopicCard(page.featureA, page.primaryColor),

          const SizedBox(height: 12),

          _buildTopicCard(page.featureB, page.secondaryColor),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroIllustration(OnboardingPage page, Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.primaryColor.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.9),
            page.accentColor.withValues(alpha: 0.2),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [page.primaryColor, page.secondaryColor],
          ),
        ),
        child: Icon(
          _getCenterIcon(_currentPage),
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getCenterIcon(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return Icons.agriculture_rounded;
      case 1:
        return Icons.eco_rounded;
      case 2:
        return Icons.water_drop_rounded;
      case 3:
        return Icons.smart_toy_rounded;
      default:
        return Icons.agriculture_rounded;
    }
  }

  Widget _buildTopicCard(FeatureData feature, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(feature.icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.desc,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: color.withValues(alpha: 0.14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'How it works',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < feature.steps.length; i++)
            _buildStep(i, feature.steps[i], color),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            gradient: _currentPage == index
                ? LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                  )
                : null,
            color: _currentPage == index ? null : const Color(0xFFD1D5DB),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(Color primaryColor, bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ElevatedButton(
            onPressed: isLastPage ? _getStarted : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastPage ? 'GET STARTED' : 'NEXT',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isLastPage
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_forward_rounded,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String tagline;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color bgColor1;
  final Color bgColor2;
  final FeatureData featureA;
  final FeatureData featureB;

  OnboardingPage({
    required this.title,
    required this.tagline,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.bgColor1,
    required this.bgColor2,
    required this.featureA,
    required this.featureB,
  });
}

class FeatureData {
  final IconData icon;
  final String label;
  final String desc;
  final List<String> steps;

  FeatureData({
    required this.icon,
    required this.label,
    required this.desc,
    required this.steps,
  });
}
