import 'package:flutter/material.dart';

class Institution {
  final String name;
  final String logoPath;
  final String category;

  Institution({
    required this.name,
    required this.logoPath,
    required this.category,
  });
}

class InstitutionSelector extends StatelessWidget {
  InstitutionSelector({super.key});

  final List<Institution> institutions = [
    // Banks
    Institution(
      name: 'BDO',
      logoPath: 'assets/images/banks/bdo_logo.jpg',
      category: 'Bank',
    ),
    Institution(
      name: 'BPI',
      logoPath: 'assets/images/banks/bpi_logo.png',
      category: 'Bank',
    ),
    Institution(
      name: 'Chinabank',
      logoPath: 'assets/images/banks/chinabank_logo.jpg',
      category: 'Bank',
    ),
    Institution(
      name: 'Landbank',
      logoPath: 'assets/images/banks/landbank_logo.webp',
      category: 'Bank',
    ),
    Institution(
      name: 'Metrobank',
      logoPath: 'assets/images/banks/metrobank_logo.png',
      category: 'Bank',
    ),
    Institution(
      name: 'RCBC',
      logoPath: 'assets/images/banks/rcbc_logo.png',
      category: 'Bank',
    ),
    Institution(
      name: 'PNB',
      logoPath: 'assets/images/banks/pnb_logo.png',
      category: 'Bank',
    ),
    Institution(
      name: 'UnionBank',
      logoPath: 'assets/images/banks/unionbank_logo.jpg',
      category: 'Bank',
    ),
    Institution(
      name: 'AUB',
      logoPath: 'assets/images/banks/aub_logo.png',
      category: 'Bank',
    ),
    Institution(
      name: 'Security Bank',
      logoPath: 'assets/images/banks/securitybank_logo.jpg',
      category: 'Bank',
    ),
    Institution(
      name: 'EastWest',
      logoPath: 'assets/images/banks/eastwest_logo.png',
      category: 'Bank',
    ),

    // E-Wallets
    Institution(
      name: 'GCash',
      logoPath: 'assets/images/e-wallets/gcash_logo.jpg',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'Maya',
      logoPath: 'assets/images/e-wallets/maya_logo.jpg',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'Coins.ph',
      logoPath: 'assets/images/e-wallets/coinsph_logo.jpg',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'GrabPay',
      logoPath: 'assets/images/e-wallets/grabpay_logo.png',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'PalawanPay',
      logoPath: 'assets/images/e-wallets/palawanpay_logo.png',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'ShopeePay',
      logoPath: 'assets/images/e-wallets/shopeepay_logo.webp',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'MariBank',
      logoPath: 'assets/images/e-wallets/maribank_logo.png',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'SeaBank',
      logoPath: 'assets/images/e-wallets/seabank_logo.png',
      category: 'E-Wallet',
    ),
    Institution(
      name: 'Tonik',
      logoPath: 'assets/images/e-wallets/tonik_logo.png',
      category: 'E-Wallet',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banks = institutions.where((i) => i.category == 'Bank').toList();
    final eWallets = institutions
        .where((i) => i.category == 'E-Wallet')
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Institution',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your bank or e-wallet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.5),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'E-Wallets'),
                      Tab(text: 'Banks'),
                    ],
                    indicatorColor: theme.primaryColor,
                    labelColor: theme.primaryColor,
                    unselectedLabelColor: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha:0.5),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGrid(context, eWallets),
                        _buildGrid(context, banks),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Institution> list) {
    final theme = Theme.of(context);
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return InkWell(
          onTap: () => Navigator.pop(context, item),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(item.logoPath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
