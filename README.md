# Ghote

hihihi猜猜我是誰


Modern Flutter app with a clean, responsive UI and smooth animations.

## Features

- 📱 **Responsive Layout**: Works across iOS/Android with proportional sizing
- 🎬 **Splash Animation**: Video-based intro with fade-in
- 🔐 **Google Sign-In**: Secure authentication with Google accounts
- 🔑 **Modern Login**: Animated form with frosted-style visuals (pure Flutter)
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
- `google_sign_in` - Google Sign-In authentication
- `firebase_core` - Firebase core functionality
- `firebase_auth` - Firebase authentication
- `video_player` - Video playback for splash animation


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
- 保護 `main`：只允許 PR 合併、CI 綠燈（無需 reviewer 批准）
- 禁止直接 push 到 `main`
- 啟用必須更新為最新 `main` 後才能合併（避免舊基礎合併）

## Collaboration guide / 協作指南（Collaborators）

### 加入專案（被加入 Collaborator 後）
1. 接受邀請（Email 或 GitHub 通知）
2. Clone 專案（建議用 SSH）：
   ```bash
   git clone git@github.com:ghote-app/ghote.git
   cd ghote
   ```
3. 安裝依賴：`flutter pub get`
4. 確保 Flutter 版本一致（建議使用 3.35.6）：
   ```bash
   flutter --version   # 確認版本
   ```

### 日常開發流程（Collaborator）
1. 從最新 `main` 建立功能分支：
   ```bash
   git switch main && git pull
   git switch -c feature/<your-feature>
   ```
2. 開發並提交（保持小步、明確訊息）：
   ```bash
   git add -A
   git commit -m "feat: <summary>"
   git push -u origin feature/<your-feature>
   ```
3. 建立 Pull Request：目標 `ghote-app/ghote` 的 `main`
4. 等待 CI 綠燈（Actions 自動跑 analyze/build）
5. 等待 CI 檢查通過 → 自動合併

### 自動合併流程
- CI 檢查通過後自動合併：
  - Analyze 檢查通過
  - Build 檢查通過（Android/iOS）
  - 無需 reviewer 批准
- 合併後自動刪除功能分支
- 保持線性提交歷史

### 團隊協作（可選）
- 在 PR 頁面留言意見或建議（非強制）
- 本地試跑（可選）：
  ```bash
  git fetch origin pull/<PR_NUMBER>/head:pr/<PR_NUMBER>
  git switch pr/<PR_NUMBER>
  flutter pub get && flutter run
  ```

### 環境一致性（Everyone）
- Flutter 版本：建議使用 3.35.6（與 CI 同步）
- Android：使用專案內 `gradle-wrapper`；JDK 版本為 17
- iOS：使用 `Podfile.lock`；如需 CocoaPods，請以 `Gemfile` 釘住版本
- 依賴鎖：提交 `pubspec.lock`（App 專案）
- CI：GitHub Actions 使用 Flutter 3.35.6

### 常見問題
- PR 無法合併？請先同步最新 `main`：
  ```bash
  git fetch origin && git switch feature/<branch>
  git merge origin/main   # 或 git rebase origin/main
  ```
- CI 版本不一致？請確認使用 Flutter 3.35.6。

## Product intro / 產品介紹

Ghote 是一個專注學習與知識整理的輕量工具：
- 以專案為單位管理文件與進度條，快速掌握學習狀態
- 內建搜尋與篩選（All/Active/Completed/Archived）
- 現代化深色主題與流暢動畫，讓使用體驗更專注

Assets（示意用）：
- App Icon：`assets/AppIcon/Ghote_icon_white_background_removed.png`
- Splash 動畫：`assets/AppIcon/splash_animation.gif`
  - 可將產品簡介 GIF/截圖放在 `assets/AppIcon/`，並在此 README 以連結的方式展示

## Screenshots / 產品截圖

<p align="center">
  <img src="assets/AppIcon/Ghote_icon_white_background_removed.png" alt="App Icon" width="120" />
  <img src="assets/AppIcon/Ghote_icon_black_background.png" alt="App Icon Dark" width="120" />
</p>

<p align="center">
  <em>App Icons - 淺色與深色版本</em>
</p>

<p align="center">
  <img src="assets/AppIcon/splash_animation.gif" alt="Splash Animation" width="320" />
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

## Recent Updates / 最近更新

### 🔐 **2025-10-12: Google 登入功能整合 (PR #13)**
- ✅ **Google Sign-In**: 整合 Android 和 iOS 的 Google 登入功能
- ✅ **Firebase 認證**: 配置 Google Services 和 Firebase Auth
- ✅ **應用程式圖標更新**: 使用新的 Ghote 品牌圖標
- ✅ **啟動畫面優化**: 使用 MP4 影片替換 GIF 動畫，提升效能
- ✅ **UI 改進**: 修復文字溢位問題，改善響應式設計
- ✅ **資源管理**: 重新組織 AppIcon 資源目錄結構

### 🐛 **2025-10-12: 登入畫面修復 (PR #12)**
- ✅ **鍵盤溢位修復**: 修復登入畫面鍵盤彈出時的溢位問題
- ✅ **響應式設計**: 改善不同螢幕尺寸的顯示效果

### 🔥 **2025-10-12: Firebase 整合 (PR #11)**
- ✅ **Firebase 整合**: 將 Firebase 整合到 Android 專案中
- ✅ **依賴管理**: 更新 Android 建置配置和依賴項目

### 🔑 **2025-10-12: 身份驗證功能 (PR #10)**
- ✅ **身份驗證**: 加入身份驗證功能
- ✅ **iOS 建置修復**: 解決 Firebase Auth 的 iOS 建置問題
- ✅ **部署目標更新**: 將 iOS 部署目標從 13.0 更新到 15.0

### 📝 **2025-10-11: 註冊按鈕功能 (PR #9)**
- ✅ **Sign Up 按鈕**: 加入註冊按鈕功能
- ✅ **使用者體驗**: 改善登入流程

### 🎬 **2025-10-11: 啟動畫面優化 (PR #8)**
- ✅ **Splash GIF 改善**: 改善啟動畫面 GIF 動畫
- ✅ **搜尋列樣式**: 優化搜尋列樣式設計

### 🔧 **2025-10-11: 程式碼品質 (PR #7)**
- ✅ **Linter 修復**: 解決所有 linter 警告
- ✅ **程式碼品質**: 提升程式碼品質和一致性

### 📚 **2025-10-11: 文檔更新 (PR #6)**
- ✅ **README 最終更新**: 移除所有 reviewer 要求
- ✅ **文檔完善**: 完善專案文檔

### 🔄 **2025-10-11: 工作流程修復 (PR #5)**
- ✅ **工作流程描述**: 最終修復工作流程描述
- ✅ **自動化流程**: 反映無需 reviewer 要求的流程

### 📖 **2025-10-11: 協作指南 (PR #4)**
- ✅ **團隊協作設定**: 新增最近更新部分記錄團隊協作設定
- ✅ **工作流程文檔**: 更新工作流程描述

### 🚀 **2025-10-11: 團隊協作環境完善**
- ✅ **分支保護規則**: 啟用 main 分支保護，要求 PR 和 CI 檢查
- ✅ **Auto-merge 功能**: 當 CI 通過時自動合併 PR（無需 reviewer 批准）
- ✅ **自動分支清理**: 合併後自動刪除功能分支
- ✅ **CODEOWNERS**: 自動指派 @ghote-app @itsYoga @tina6662 @matthew930823 @wonogfsocry 為 reviewer
- ✅ **PR 模板**: 提供中英雙語 PR 模板和合併指南
- ✅ **Issue 模板**: 標準化 bug 報告和功能請求模板
- ✅ **自動標籤**: 根據檔案變更自動為 PR 添加標籤
- ✅ **Release 工作流程**: 標籤驅動的自動 APK 生成

### 🔧 **2025-10-11: 程式碼重構**
- ✅ **響應式佈局**: 移除平台特定尺寸，改用 MediaQuery 相對尺寸
- ✅ **移除 PlatformUtils**: 簡化程式碼，統一跨平台體驗
- ✅ **移除 liquid_glass_renderer**: 解決 Android 渲染問題，改用標準 Flutter 組件
- ✅ **Responsive 工具類**: 新增統一的響應式尺寸管理

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both iOS and Android
5. Submit a pull request

### 協作流程 / Collaboration Workflow
- **建立 PR** → **CI 檢查** → **自動合併**（無需 reviewer 批准）
- 詳細流程請參考 [CONTRIBUTING.md](CONTRIBUTING.md)

## License

This project is licensed under the MIT License.
