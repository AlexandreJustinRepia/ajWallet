# RootEXP - Nature-Inspired Financial Management

RootEXP is a premium, offline-first personal finance application that transforms budgeting into a living ecosystem. By combining a professional-grade accounting engine with nature-inspired gamification, RootEXP makes managing your wealth a visually stunning and rewarding experience.

## 🚀 Key Features

### 🌳 Nature-Inspired Gamification

- **Financial Tree Visualizer:** Your wealth is represented by a living tree on your dashboard that grows branches and leaves as your balance increases.
- **Tree Skin System:** Customize your experience with unique themes like **Sakura**, **Autumn**, **Winter Frost**, **Wealth Oak**, **Golden Money**, and the futuristic **Tech Tree**.
- **Live Previews:** Test-drive any skin in the Rewards Shop with a real-time animated preview dialog.
- **Health Mechanics:** The tree reacts to your financial habits—saving makes it bloom, while overspending causes it to react dynamically.
- **Rewards Shop:** Earn and spend currency to unlock premium tree skins and cosmetic upgrades.

### 🎓 Intelligent Interactive Onboarding

- **Multi-Screen Guided Tour:** A seamless, spotlight-driven tutorial that navigates between the Dashboard, Transactions, Wallets, and Planning hubs.
- **Live Tooltips:** Interactive callouts that highlight real-life UI components, teaching you how to manage transactions and budgets in context.
- **Adaptive Positioning:** A smart overlay system that automatically positions itself to ensure clarity on any screen size and avoids navigation bar blockage.

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

### 🛒 Smart Shopping Lists

- **Multi-List Management:** Create and track separate lists for groceries, electronics, travel essentials, and more.
- **Drafting & Autosave:** Start a list and save it as a draft. Your progress is preserved so you can pick up where you left off at the store.
- **Integrated Settlement:** Settle your shopping lists directly with your wallets. The app automatically handles the transaction recording for you.
- **Insufficient Funds Guard:** Smart logic prevents you from settling a list that exceeds your available wallet balance, ensuring your records stay accurate.

### 🏷️ Customizable Category Engine

- **Full Creative Control:** Add, edit, or delete categories to match your unique lifestyle.
- **Visual Icon Library:** Choose from a curated set of professional icons for each category.
- **Manual Sorting:** Arrange your categories in any order you prefer using a simple drag-and-drop interface to prioritize your most used labels.
- **Smart Category Sync:** Core financial categories like **Lend**, **Borrow**, and **Repayments** are protected and automatically synced to ensure accounting integrity.

### 🤝 Advanced Debts & Loans

- **Integrated Workflow:** Debt management is now a part of your daily transaction flow. Selecting "Lend" or "Borrow" categories automatically triggers debt tracking.
- **Quick Select Contacts:** Save time with intelligent suggestions for existing contacts, allowing for one-tap name entry.
- **Repayment Specialization:** Dedicated categories for **Received Payment** and **Debt Payment** clearly distinguish initial loans from subsequent repayments.
- **Overpayment Safeguard:** The app prevents you from recording payments that exceed the total outstanding balance, keeping your debt records 100% accurate.
- **Status Badges:** Fully settled debts are instantly marked with a green **"PAID"** status and moved to a completed state.

### 💾 Backup & Data Portability

- **Encrypted Backups:** Export your entire financial history, including wallets, transactions, debts, and shopping lists, into a secure backup file.
- **Seamless Restore:** Migrating to a new device? Use the Import feature to restore your data in seconds with a single click.
- **Automated Loading Indicators:** Safe, non-dismissible loading states during data operations ensure your database remains corruption-free during imports.

### 👥 Squads & Group Expenses

- **Create and Manage Squads:** Easily create groups for roommates, travel buddies, or project teams.
- **Dynamic Activities:** Log expenses within your squads and distribute costs using flexible split types (Equal, Percentage, or Specific Amounts).
- **Premium Digital Receipts:** Share stunning, high-contrast digital receipts for any squad activity featuring "Carbon Dark" design with secure verification details and clear member breakdowns.

### 📔 Visual Bookkeeping

- **Transaction Attachments:** Attach photos, receipts, or documents to any transaction for better record-keeping.
- **In-App Gallery:** Preview attachments in a horizontal list during creation and view them full-screen later in the transaction details.
- **Secure Local Storage:** All attachments are stored privately in your app data, ensuring your proof of payment is always accessible even if deleted from your device's gallery.

### 📊 Professional Export Tools

- **Microsoft Excel (.xlsx):** Generate fully formatted spreadsheets with transaction history and calculated summaries.
- **PDF Reports:** Export beautifully designed, printer-friendly documents with category charts and spending insights.
- **CSV Support:** Clean data exports for integration with other accounting software.

### 🎨 Premium Personalization & UI

- **Dynamic Design System:** Modern, premium aesthetics featuring glassmorphism, smooth gradients, and vibrant color presets.
- **Customization Lab:** Tweak every aspect of the UI for a truly bespoke financial environment.
- **Tactile Feedback:** Subtle micro-animations and haptic-inspired interactions for a high-end feel.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev/)
- **Local Storage:** [Hive](https://pub.dev/packages/hive) (High-performance NoSQL)
  State Management:\*\* `ValueNotifier` for lightweight reactive UI updates.
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
   git clone https://github.com/AlexandreJustinRepia/RootEXP.git
   ```
2. Navigate to the project directory:
   ```bash
   cd RootEXP
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

_(Add your screenshots here later)_

---

## 📜 License

Copyright © 2026 **Alexandre Justin Repia**. All rights reserved.

This project and its source code are proprietary. Unauthorized use, reproduction, or distribution is strictly prohibited.

Built with ❤️ for privacy-conscious budgeters.
