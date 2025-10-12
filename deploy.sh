#!/bin/bash

# Ghote Website Deployment Script
echo "🚀 開始部署 Ghote 網站到 GitHub Pages..."

# 檢查是否在 ghote 目錄中
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 請在 ghote 專案根目錄中執行此腳本"
    exit 1
fi

# 清理之前的建置
echo "🧹 清理之前的建置..."
flutter clean

# 獲取依賴項
echo "📦 安裝依賴項..."
flutter pub get

# 建置 Web 版本
echo "🔨 建置 Web 版本..."
flutter build web --release --base-href "/ghote/"

# 檢查建置是否成功
if [ ! -d "build/web" ]; then
    echo "❌ 建置失敗"
    exit 1
fi

echo "✅ 建置完成！"
echo "📁 建置檔案位於: build/web"
echo ""
echo "🌐 要部署到 GitHub Pages："
echo "1. 將 build/web 目錄的內容推送到 gh-pages 分支"
echo "2. 或在 GitHub 上啟用 Pages 並設定為從 gh-pages 分支部署"
echo ""
echo "🔗 部署後，網站將可在以下網址存取："
echo "https://[您的GitHub用戶名].github.io/ghote/"
