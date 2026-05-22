# AppDev 2026 - Personal Finance Tracker

A robust and intuitive personal finance tracking application built with **Flutter** and **Firebase**. Keep track of your daily expenses, set budget goals, and visualize your financial health with interactive charts and real-time syncing.

---

## 📱 Features

* **Expense and Income Tracking:** Log your financial transactions effortlessly and categorize them.
* **Authentication:** Secure sign-in utilizing **Firebase Authentication** (including Google Sign-In).
* **Real-time Syncing:** All data is safely stored and synced across devices in real-time using **Cloud Firestore**.
* **Financial Dashboards & Analytics:** Interactive charts (using `fl_chart`) to visualize your cash flow and spending models.
* **Multi-Currency Support:** Convert and display your finances in different currencies based on user preferences.
* **Notifications:** Local notifications (`flutter_local_notifications`) to keep you reminded of upcoming bills and budget alerts.
* **Cross-Platform:** Write once, run seamlessly on Android, iOS, Web, Windows, macOS, and Linux.

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart) 
* **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore DB)
* **State Management:** `provider`
* **UI/UX components:** `cupertino_icons`, `iconsax`, `google_fonts`, `flutter_svg`, `fl_chart`

## 📁 Project Structure

```text
lib/
├── auth/            # Authentication logic and screens
├── controllers/     # Controller logic mapping UI and state
├── models/          # Data models (Transactions, Budgets, Users, etc.)
├── screens/         # UI screens (Home, Profile, Transactions, Splash, etc.)
├── services/        # Firebase services, Notification setup, API clients
├── widgets/         # Reusable UI widgets and components
├── app_navigator.dart
├── firebase_options.dart
├── main.dart
└── theme_controller.dart
```

## 🚀 Getting Started

Follow these instructions to get a local copy of this project up and running.

### Prerequisites

* Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.11.0 or higher recommended)
* Install [Dart SDK](https://dart.dev/get-dart)
* Active Firebase project (for configuration)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MAhmed-23L-0733/app-dev-2026.git
   cd app-dev-2026/appdev2026
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Application:**
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](https://github.com/MAhmed-23L-0733/app-dev-2026/issues) if you want to contribute.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
