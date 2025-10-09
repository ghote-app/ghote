# Ghote

A modern Flutter application with beautiful glass morphism effects and smooth animations.

## Features

- 🎨 **Glass Morphism UI** - Stunning liquid glass effects throughout the app
- 📱 **Responsive Design** - Optimized for both iOS and Android
- 🎬 **Splash Animation** - Video-based splash screen with smooth transitions
- 🔐 **Modern Login** - Glass-effect login screen with animations
- 📊 **Dashboard** - Dynamic scrolling interface with project management
- 🌙 **Dark Theme** - Elegant dark color scheme

## Prerequisites

- Flutter SDK (latest stable version)
- Xcode (for iOS development)
- Android Studio (for Android development)
- macOS (for iOS Simulator)

## Getting Started

### 1. Clone the repository
```bash
git clone <repository-url>
cd ghote
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run on iOS Simulator (macOS)

#### Option A: Using Xcode
1. Open Xcode
2. Go to **Xcode > Open Developer Tool > Simulator**
3. Choose your preferred iOS device simulator
4. Run the app:
```bash
flutter run
```

#### Option B: Using Command Line
```bash
# List available simulators
flutter emulators

# Launch iOS Simulator
open -a Simulator

# Run the app
flutter run
```

### 4. Run on Android Emulator

#### Option A: Using Android Studio
1. Open Android Studio
2. Go to **Tools > AVD Manager**
3. Create a new Virtual Device or use existing one
4. Start the emulator
5. Run the app:
```bash
flutter run
```

#### Option B: Using Command Line
```bash
# List available Android emulators
flutter emulators

# Launch Android emulator (replace with your emulator name)
flutter emulators --launch Medium_Phone_API_35

# Run the app
flutter run
```

### 5. Run on Physical Device

#### iOS Device
1. Connect your iPhone/iPad via USB
2. Trust the computer on your device
3. Run:
```bash
flutter run
```

#### Android Device
1. Enable Developer Options and USB Debugging on your Android device
2. Connect via USB
3. Run:
```bash
flutter run
```

## Development Commands

```bash
# Hot reload during development
r

# Hot restart
R

# Quit the app
q

# List all available commands
h
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── splash_screen.dart    # Animated splash screen
│   ├── login_screen.dart     # Glass morphism login
│   └── dashboard_screen.dart # Main dashboard interface
├── widgets/
│   ├── glass_button.dart     # Reusable glass button
│   └── glass_container.dart  # Reusable glass container
└── theme/
    └── app_theme.dart       # App theming
```

## Dependencies

- `liquid_glass_renderer` - Glass morphism effects
- `google_fonts` - Custom typography
- `video_player` - Splash screen animation
- `flutter_launcher_icons` - App icon generation

## Changelog

### 2025-10-09
- Dashboard: 以 MediaQuery 改寫 `SliverAppBar` 的 `expandedHeight`，由固定值改為 `screenHeight * 0.25`，改善在多尺寸裝置的表現。
- Dashboard: 將專案清單 Grid 由 `childAspectRatio` 改為 `mainAxisExtent`，以螢幕高度推導卡片高度並加上合理夾限，避免在不同寬高比裝置上溢位或留白不均。
- Dashboard: 去除 `SliverAppBar.bottom` 與搜尋列底部間距的平臺分支，改為一致的相對/固定安全值，避免 Android/iOS 之間版面偏移。

## Troubleshooting

### iOS Issues
- Make sure Xcode is installed and updated
- Check that iOS Simulator is running
- Verify code signing if running on physical device

### Android Issues
- Ensure Android SDK is properly installed
- Check that Android emulator is running
- Verify USB debugging is enabled for physical devices

### Network Issues
- The app uses Google Fonts which requires internet connection
- For offline development, consider using local fonts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both iOS and Android
5. Submit a pull request

## License

This project is licensed under the MIT License.
