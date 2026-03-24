# AJ Wallet - Minimalist Offline Budget App

AJ Wallet is a professional, minimalist offline budget application built with Flutter. It prioritizes privacy, security, and a clean user experience with a monochromatic aesthetic and deep customization options.

## 🚀 Features

### 🔐 Security & Privacy
- **Offline First:** All data is stored locally on your device. No cloud sync, no tracking.
- **PIN Protection:** Secure your financial data with a mandatory 4-digit PIN.
- **Biometric Authentication:** Optional Fingerprint or Face ID login for supported devices.
- **Security Lockout:** Automatic temporary lockout after 5 failed PIN attempts.

### 🧠 Proactive AI Financial Coach
- **Predictive Insights:** Forecasts your **Cashflow Runway** (detects when you might run out of money).
- **Scenario Simulation:** Ask "What if...?" questions to model the impact of savings or spending changes.
- **Debt Risk Awareness:** Warns you if debt payments threaten your near-term cashflow.
- **Payoff Optimization:** Suggests strategies to become debt-free faster based on spare cash.
- **Adaptive Tone:** The AI shifts its personality (Calm, Strict, Encouraging) based on your financial health.
- **Guided Onboarding:** Interactive tutorial for first-time users to discover AI features.

### 🎯 Planning Hub & Goals
- **Savings Strategy:** Track multiple goals with different strategies (Default vs. Aggressive).
- **Debt Management:** Specialized tools for tracking money owed and money borrowed.
- **Quick Shortcuts:** Instant transaction entry directly from the Planning Hub for goals and debts.
- **Gamified Achievements:** Unlock badges like 'AI Explorer' and 'Debt Slayer' as you progress.

### 🎨 Premium Personalization
- **Simplified Theme Engine:** Modern 'System / Light / Dark' toggle with auto-applying preset palettes.
- **Advanced Custom Lab:** Tweak every color (Primary, Background, etc.) for a truly unique look.
- **Tactile UI:** Rounded layouts, subtle shadows, and a "Bottom-Up" chat-inspired AI assistant.

### 📱 User Experience
- **Minimalist Design:** Clean, professional aesthetic using black, white, and gray tones.
- **Interactive UI:** Subtle animations for field focus and button presses.
- **Profile Menu:** Quick access to theme settings and logout from the dashboard.

## 🛠️ Tech Stack
- **Framework:** [Flutter](https://flutter.dev/)
- **Local Storage:** [Hive](https://pub.dev/packages/hive) (High-performance NoSQL)
- **State Management:** `ValueNotifier` for lightweight reactive UI updates.
- **Biometrics:** `local_auth` for secure hardware-level authentication.
- **Color Picking:** `flutter_colorpicker` for theme customization.

## 🏁 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- A physical device or emulator (biometrics require a physical device or a configured emulator)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/aj_wallet.git
   ```
2. Navigate to the project directory:
   ```bash
   cd aj_wallet
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 📸 Screenshots
*(Add your screenshots here later)*

---
## 📜 License

Copyright © 2026 **Alexandre Justin Repia**. All rights reserved.

This project and its source code are proprietary. Unauthorized use, reproduction, or distribution is strictly prohibited.

Built with ❤️ for privacy-conscious budgeters.
