import 'package:flutter/material.dart';
import 'create_account_screen.dart';
import 'widgets/animated_tree.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _features = [
    {
      'title': 'Private by Design',
      'desc': '100% Offline Vault. Your data never leaves your device.',
      'icon': '🛡️',
    },
    {
      'title': 'Your Living Wealth',
      'desc': 'This tree is a reflection of your financial health. Watch it bloom as you grow your savings.',
      'icon': '🌳',
    },
    {
      'title': 'Growth Evolution',
      'desc': 'Track your habits with a gamified Growth Chain.',
      'icon': '🌱',
    },
    {
      'title': 'Local Intelligence',
      'desc': 'Secure AI insights that protect your privacy.',
      'icon': '🧠',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final growthColor = Colors.green[600]!;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, -0.6),
                radius: 1.2,
                colors: [
                  growthColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                
                // Hero Image
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Hero(
                    tag: 'get_started_hero',
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.35,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: const Center(
                        child: AnimatedTree(
                          balance: 1000, // Show a healthy growing tree for onboarding
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Headline & Animated Feature List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        'Your Wealth,\nGrown Privately.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1.1,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Feature Progress Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_features.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _currentPage == index ? 20 : 6,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                  ? growthColor 
                                  : growthColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Feature Carousel
                      SizedBox(
                        height: 100,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (idx) => setState(() => _currentPage = idx),
                          itemCount: _features.length,
                          itemBuilder: (context, index) {
                            final feature = _features[index];
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(feature['icon']!, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      feature['title']!,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.grey[400] : Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  feature['desc']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Premium CTA Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [growthColor, Colors.green[800]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: growthColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Start Growing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.8)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
