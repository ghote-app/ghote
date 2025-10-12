# Ghote 官方網站

這是 Ghote 應用程式的官方網站，使用 Flutter Web 建置，包含服務條款和隱私政策頁面。

## 功能特色

- 🏠 **首頁**：展示 Ghote 應用程式的特色和功能
- 📋 **服務條款**：詳細的服務使用條款
- 🔒 **隱私政策**：完整的隱私保護政策
- 📱 **響應式設計**：支援各種裝置尺寸
- 🎨 **現代化 UI**：使用玻璃擬態設計風格

## 本地開發

### 前置需求

- Flutter SDK (3.24.0 或更高版本)
- Chrome 瀏覽器（用於測試）

### 運行網站

```bash
# 安裝依賴項
flutter pub get

# 在 Chrome 中運行網站
flutter run -d chrome --web-port 8080
```

網站將在 `http://localhost:8080` 開啟。

## 部署到 GitHub Pages

### 方法一：使用 GitHub Actions（推薦）

1. 確保您的 GitHub 儲存庫已啟用 Pages
2. 推送程式碼到 main 分支
3. GitHub Actions 會自動建置並部署網站

### 方法二：手動部署

1. 執行部署腳本：
```bash
./deploy.sh
```

2. 將 `build/web` 目錄的內容推送到 `gh-pages` 分支

3. 在 GitHub 儲存庫設定中啟用 Pages，並設定為從 `gh-pages` 分支部署

### 部署後存取

部署完成後，網站將可在以下網址存取：
```
https://[您的GitHub用戶名].github.io/ghote/
```

## 專案結構

```
lib/website/
├── main.dart              # 網站主程式
├── router.dart            # 路由配置
├── home_page.dart         # 首頁
├── terms_of_service_page.dart  # 服務條款頁面
└── privacy_policy_page.dart    # 隱私政策頁面
```

## 技術棧

- **Flutter Web**：跨平台 Web 開發框架
- **Go Router**：聲明式路由管理
- **Google Fonts**：字體服務
- **Material Design**：UI 設計系統

## 自訂化

### 修改內容

1. **首頁內容**：編輯 `lib/website/home_page.dart`
2. **服務條款**：編輯 `lib/website/terms_of_service_page.dart`
3. **隱私政策**：編輯 `lib/website/privacy_policy_page.dart`

### 修改樣式

所有頁面都使用 Google Fonts 和 Material Design，可以在各個頁面檔案中修改樣式。

## 故障排除

### 常見問題

1. **建置失敗**：確保 Flutter SDK 版本正確
2. **依賴項問題**：執行 `flutter clean && flutter pub get`
3. **路由問題**：檢查 `router.dart` 中的路由配置

### 除錯

```bash
# 清理專案
flutter clean

# 重新安裝依賴項
flutter pub get

# 檢查依賴項
flutter pub deps

# 分析程式碼
flutter analyze
```

## 貢獻

歡迎提交 Pull Request 來改善網站！

## 授權

本專案使用與 Ghote 應用程式相同的授權條款。
