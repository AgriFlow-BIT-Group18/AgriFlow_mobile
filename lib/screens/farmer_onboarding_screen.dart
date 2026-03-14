import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/main_layout.dart';

class FarmerOnboardingScreen extends StatefulWidget {
  const FarmerOnboardingScreen({super.key});

  @override
  State<FarmerOnboardingScreen> createState() => _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState extends State<FarmerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: 'Your Farm Inputs, Digital',
      description:
          'Order seeds, fertilizers and pesticides from your phone, anytime.',
      imageColor: const Color(
        0xFF2D6C50,
      ).withValues(alpha: 0.05), // bg-primary/5
      showLanguageToggle: true,
    ),
    OnboardingItem(
      title: 'Track Every Delivery',
      description:
          'Know exactly where your order is, from approval to your doorstep.',
      imageColor: Colors.orange.shade50, // bg-orange-50
      showLanguageToggle: false,
    ),
    OnboardingItem(
      title: 'Always in the Know',
      description:
          'Get notified the moment your order is approved, shipped, or delivered.',
      imageColor: const Color(
        0xFF2D6C50,
      ).withValues(alpha: 0.05), // bg-primary/5
      showLanguageToggle: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation - Skip Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Skip action
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2D6C50),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Container
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: item.imageColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 32),
                              clipBehavior: Clip.antiAlias,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.black12,
                                ), // Placeholder for image
                              ),
                            ),
                          ),

                          // Language Toggle (only on first screen)
                          if (item.showLanguageToggle)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Row(
                                children: [
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D6C50),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'EN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'FR',
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Text Content
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 28, // Approx 3xl
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Color(0xFF0F172A), // slate-900
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 18, // lg
                              height: 1.6, // relaxed
                              color: Colors.blueGrey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 32 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2D6C50)
                              : Colors.blueGrey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Button(s)
                  if (_currentPage < _pages.length - 1)
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6C50),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF2D6C50,
                        ).withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainLayout(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6C50),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF2D6C50,
                            ).withValues(alpha: 0.3),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2D6C50),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I already have an account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

class OnboardingItem {
  final String title;
  final String description;
  final Color imageColor;
  final bool showLanguageToggle;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imageColor,
    required this.showLanguageToggle,
  });
}
