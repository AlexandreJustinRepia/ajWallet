import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About'), 
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 120, 32, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 48,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'RootEXP',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: theme.textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'v0.3.0',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission Statement
                  Center(
                    child: Text(
                      'Privacy-First Financial Growth',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RootEXP is a secure, offline-first personal finance manager designed to give you absolute control over your money without ever compromising your privacy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Feature Highlights
                  _buildSectionTitle(context, 'CORE VALUES'),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(context),
                  
                  const SizedBox(height: 40),

                  // Developer Section
                  _buildSectionTitle(context, 'DEVELOPED BY'),
                  const SizedBox(height: 16),
                  _buildDeveloperCard(context),

                  const SizedBox(height: 40),

                  // Legal
                  _buildSectionTitle(context, 'LEGAL & COPYRIGHT'),
                  const SizedBox(height: 12),
                  Text(
                    'This application and its source code are the exclusive property of Alexandre Justin Repia. All rights reserved. Unauthorized copying, modification, or distribution is strictly prohibited.',
                    style: TextStyle(
                      fontSize: 12, 
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5), 
                      height: 1.5
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Built with ',
                              style: TextStyle(
                                fontSize: 12, 
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                              ),
                            ),
                            const Icon(Icons.favorite_rounded, color: Colors.red, size: 14),
                            Text(
                              ' using Flutter',
                              style: TextStyle(
                                fontSize: 12, 
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '© 2026 Alexandre Justin Repia',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.w900,
        fontSize: 10,
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildFeatureItem(context, Icons.security_rounded, '100% Offline', 'Your data never leaves your device.'),
        _buildFeatureItem(context, Icons.emoji_events_rounded, 'Gamified', 'Earn XP and level up as you save.'),
        _buildFeatureItem(context, Icons.auto_awesome_rounded, 'AI Insights', 'Smart suggestions for your growth.'),
        _buildFeatureItem(context, Icons.ads_click_rounded, 'Zero Ads', 'No distractions, just pure finance.'),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String desc) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 10, 
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                height: 1.2
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Alexandre Justin Repia',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Independent Flutter Developer',
            style: TextStyle(
              fontSize: 13, 
              color: onPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Follow the journey on GitHub',
              style: TextStyle(color: onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
