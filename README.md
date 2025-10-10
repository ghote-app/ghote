# Ghote

Modern Flutter app with a clean, responsive UI and smooth animations.

## Features

- 📱 **Responsive Layout**: Works across iOS/Android with proportional sizing
- 🎬 **Splash Animation**: Video-based intro with fade-in
- 🔐 **Modern Login**: Animated form with frosted-style visuals (pure Flutter)
- 📊 **Dashboard**: Sliver-based scrolling, filters, and animated cards
- 🌙 **Dark Theme**: Polished dark palette (Material 3)

## Prerequisites

- Flutter SDK (stable)
- Xcode (for iOS)
- Android Studio (for Android)
- macOS (for iOS simulator)

### Recommended toolchain pinning
- Flutter version manager: FVM or asdf（提交專案的版本檔，確保團隊一致）
- Android: 使用專案內 `gradle-wrapper` 啟動
- iOS: 使用 `Podfile.lock` 釘住 Pods；可加上 `Gemfile` 固定 CocoaPods

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
│   ├── login_screen.dart     # Animated login
│   └── dashboard_screen.dart # Main dashboard interface
├── widgets/
│   ├── glass_button.dart     # Reusable button (pure Flutter)
│   └── glass_container.dart  # Reusable container (pure Flutter)
└── theme/
    └── app_theme.dart       # App theming
```

## Dependencies

- `google_fonts` - Custom typography
- `video_player` - Splash screen animation
- `flutter_launcher_icons` - App icon generation

## Changelog

### 2025-10-09
- Dashboard: 以 MediaQuery 改寫 `SliverAppBar` 的 `expandedHeight`，由固定值改為 `screenHeight * 0.25`，改善在多尺寸裝置的表現。
- Dashboard: 將專案清單 Grid 由 `childAspectRatio` 改為 `mainAxisExtent`，以螢幕高度推導卡片高度並加上合理夾限，避免在不同寬高比裝置上溢位或留白不均。
- Dashboard: 去除 `SliverAppBar.bottom` 與搜尋列底部間距的平臺分支，改為一致的相對/固定安全值，避免 Android/iOS 之間版面偏移。
 - 全面移除 `liquid_glass_renderer`，改以純 Flutter 實作（避免 Android 上渲染異常）。

## Team workflow

### Git
- Repo root: `ghote/`
- Default branch: `main`
- 提交規範（建議）：`feat|fix|chore|refactor|docs: ...`
- 新功能請用分支：`feature/<name>` → PR 合併至 `main`

### Coding standards
- 嚴格避免平台分支引導版面尺寸；使用 `MediaQuery`/`LayoutBuilder`/`Responsive` helper
- 保持 Widget 無狀態或最小狀態，盡量使用組件化與可重用樣式
- 保留 `analysis_options.yaml` 中的規則，確保 lints 為 0

### Branch protection（建議）
- 保護 `main`：只允許 PR 合併、至少 1 位 Reviewer 通過、CI 綠燈
- 禁止直接 push 到 `main`
- 啟用必須更新為最新 `main` 後才能合併（避免舊基礎合併）

## Product intro / 產品介紹

Ghote 是一個專注學習與知識整理的輕量工具：
- 以專案為單位管理文件與進度條，快速掌握學習狀態
- 內建搜尋與篩選（All/Active/Completed/Archived）
- 現代化深色主題與流暢動畫，讓使用體驗更專注

Assets（示意用）：
- App Icon：`assets/images/Ghote_icon_black_background.png`
- Splash 動畫：`assets/images/Ghote_opening_animation.mp4`
  - 可將產品簡介 GIF/截圖放在 `assets/images/`，並在此 README 以連結的方式展示

## Screenshots / 產品截圖

<p align="center">
  <img src="assets/images/Ghote_icon_black_background.png" alt="App Icon" width="120" />
  <img src="assets/images/Ghote_icon_white_background.png" alt="App Icon White" width="120" />
</p>

<p align="center">
  <em>App Icons - 深色與淺色版本</em>
</p>

<p align="center">
  <img src="assets/images/splash_animation.gif" alt="Splash Animation" width="320" />
</p>

<p align="center">
  <em>Splash Animation - 開場動畫</em>
</p>

English
- Ghote is a lightweight tool for learning and knowledge organization.
- Project-based progress tracking with search and filters.
- Modern dark theme with smooth animations.
- Put screenshots/GIFs under `assets/images/` and reference them here for showcase.

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
- Google Fonts 需要網路；離線時請改用本地字型

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both iOS and Android
5. Submit a pull request

## License

This project is licensed under the MIT License.
