# Ghote

## Product intro / 產品介紹

Ghote is an AI-powered learning assistant that extracts key knowledge from your materials, organizes it, and helps you master it via active recall.

Ghote 是一個由 AI 驅動的智能學習輔助 App，能從你的學習資料中提取核心知識、結構化整理，並透過主動回憶工具強化記憶。

Modern Flutter app with a clean, responsive UI and smooth animations.

## Features / 功能特色

- AI Knowledge Extraction | AI 智能知識提取
  - Upload PDFs/DOCX/notes; get distilled key points, MCQs, Q&A, and flashcards.
  - 上傳 PDF/DOCX/筆記，AI 自動產出重點摘要、選擇題、問答題與抽認卡。
- Project-based Organization | 專案式管理
  - Manage subjects/topics as projects; track progress at a glance.
  - 以 Project 管理不同科目/主題，掌握學習狀態。
- Fast Search & Filters | 智能搜尋與篩選
  - Built-in All/Active/Completed/Archived filters to find content instantly.
  - 內建 All/Active/Completed/Archived 篩選快速定位內容。
- Active Recall Tools | 主動回憶工具
  - Practice with generated MCQs, Q&A, spaced-repetition flashcards.
  - 練習模式：選擇題／問答題／間隔重複抽認卡。
- Authentication | 安全登入
  - Firebase Authentication with Email/Password and Google Sign-In.
  - 使用 Firebase Auth（Email/Password、Google 登入）。
- Modern UI | 現代化介面
  - Dark theme, glass morphism, smooth animations, fully responsive.
  - 深色主題、玻璃擬態、流暢動畫、完整響應式。

## Prerequisites

- Flutter SDK (stable)
- Xcode (for iOS)
- Android Studio (for Android)
- macOS (for iOS simulator)

### Firebase Google Sign-In（Android）SHA 設定
為了讓 Android 上的 Google 登入正常運作，請在 Firebase Console 的 Android App 設定中加入 Debug/Release 的 SHA-1 與 SHA-256：

1) 取得 Debug keystore 指紋（常用於本機開發）
```bash
# Android Studio/Gradle 產生的 debug keystore（最常見）
./gradlew signingReport

# 或使用 keytool（如需）：
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```

2) 取得 Release keystore 指紋（發版/測試用，若有設定簽章）
```bash
keytool -list -v -alias <your_release_alias> -keystore <path_to_your_release_keystore.jks>
```

3) 前往 Firebase Console → 專案設定 → 您的 Android App → 在「SHA 識別碼」中新增上述 SHA-1 與 SHA-256。

4) 下載更新後的 `google-services.json`，放到 `android/app/google-services.json` 並重新執行：
```bash
flutter clean && flutter pub get
```

備註：iOS 不需要 SHA；若更換或新增 SHA，請務必重新下載 `google-services.json`。

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

## Official Website / 官方網站

本專案內含以 Flutter Web 建置的官方網站（首頁、服務條款、隱私政策），並透過 GitHub Pages 自動部署。

### 網站功能特色
- 首頁：展示 Ghote 應用程式的特色和功能
- 服務條款：完整的服務使用條款內容
- 隱私政策：完整的隱私保護政策
- 響應式設計：支援各種裝置尺寸
- 現代化 UI：玻璃擬態設計，深色主題

### 本地開發（Website）
```bash
# 安裝依賴
flutter pub get

# 在 Chrome 中運行網站
flutter run -d chrome --web-port 8080
```
開啟網址：`http://localhost:8080`

### 部署到 GitHub Pages（Actions 自動部署）
1. 確保儲存庫啟用 Pages，來源選擇「GitHub Actions」
2. 推送到 `main` 分支後，Actions 會自動 build 並部署
3. 部署完成後可於以下網址存取：
   - `https://ghote-app.github.io/ghote/`

手動部署可使用 `./deploy.sh` 生成 `build/web` 後，推送至 `gh-pages` 分支（若採用此流程）。

### 網站檔案結構
```
lib/website/
├── main.dart                  # 網站主程式
├── router.dart                # 路由配置（/、/terms、/privacy）
├── home_page.dart             # 首頁
├── terms_of_service_page.dart # 服務條款
└── privacy_policy_page.dart   # 隱私政策
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

Assets：
- App Icon：`assets/AppIcon/Ghote_icon_white_background_removed.png`
- Splash 動畫：`assets/AppIcon/splash_animation.gif`

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

### 2025-10-13: Website 法務頁面 i18n 完成
- 新增隱私政策與服務條款之完整英文/中文鍵於 `lib/website/i18n.dart`
- 頁面改為使用 `t('...')` 取得文案
- 切換語言時，法務頁面內容將自動對應顯示

### 2025-10-12: 官方網站上線 (PR #18)
- 使用 Flutter Web 建立的官方網站
- 完整的服務條款和隱私政策
- GitHub Actions 自動部署到 GitHub Pages
- 響應式設計，支援各種裝置尺寸

### 2025-10-12: Google 登入功能整合 (PR #13)
- 整合 Android 和 iOS 的 Google 登入功能
- 配置 Google Services 和 Firebase Auth
- 應用程式圖標更新和啟動畫面優化
- UI 改進和資源管理優化

### 2025-10-12: 登入畫面修復 (PR #12)
- 修復登入畫面鍵盤彈出時的溢位問題
- 改善不同螢幕尺寸的顯示效果

### 2025-10-12: Firebase 整合 (PR #11)
- 將 Firebase 整合到 Android 專案中
- 更新 Android 建置配置和依賴項目

### 2025-10-12: 身份驗證功能 (PR #10)
- 加入身份驗證功能
- 解決 Firebase Auth 的 iOS 建置問題
- 將 iOS 部署目標從 13.0 更新到 15.0

### 2025-10-11: 團隊協作環境完善
- 啟用 main 分支保護，要求 PR 和 CI 檢查
- 當 CI 通過時自動合併 PR
- 合併後自動刪除功能分支
- 提供 PR 模板、Issue 模板和自動標籤功能

### 2025-10-11: 程式碼重構
- 移除平台特定尺寸，改用 MediaQuery 相對尺寸
- 移除 PlatformUtils，簡化程式碼
- 移除 liquid_glass_renderer，改用標準 Flutter 組件
- 新增統一的響應式尺寸管理

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
