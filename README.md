# AJ Wallet - Minimalist Offline Budget App

AJ Wallet is a professional, minimalist offline budget application built with Flutter. It prioritizes privacy, security, and a clean user experience with a monochromatic aesthetic and deep customization options.

## 🚀 Features

### 🔐 Security & Privacy
- **Offline First:** All data is stored locally on your device. No cloud sync, no tracking.
- **PIN Protection:** Secure your financial data with a mandatory 4-digit PIN.
- **Biometric Authentication:** Optional Fingerprint or Face ID login for supported devices.
- **Security Lockout:** Automatic temporary lockout after 5 failed PIN attempts.

### 💼 Account Management
- **Multi-Account Support:** Create and manage multiple budget accounts independently.
- **Account Listing:** A clean dashboard to view and switch between your wallets.
- **Easy Setup:** Streamlined first-time experience for new users.
- **Account Deletion:** Safely remove accounts with full data wipe confirmation.

### 🎨 Personalization
- **Dynamic Theming:** Instant switching between Light and Dark modes.
- **Custom Themes:** Create your own professional look by picking custom colors for Primary, Background, Text, and Card elements.
- **Theme Preview:** Real-time preview of your custom theme before applying.

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
