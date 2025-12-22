# 軟體測試文件 (STD)

**專案名稱：** Ghote 智慧學習輔助 App  
**撰寫日期：** 2025/12/22  
**發展者：** 專案團隊（5人）
- Team Lead 梁祐嘉
- Full Stack Engineer 李孟修
- Full Stack Engineer 楊泓立
- Full Stack Engineer 楊皓鈞
- Full Stack Engineer 蔡佩穎

---

## 版次變更記錄

| 版次 | 變更項目 | 變更日期 |
|------|----------|----------|
| 0.1  | 初版     | 2025/11/20 |
| 0.2  | 新增測試案例 | 2025/12/20 |
| 1.0  | 完整測試案例與追溯表 | 2025/12/22 |

---

## 目錄

1. [測試目的與接受準則](#1-測試目的與接受準則)
2. [測試環境](#2-測試環境)
3. [測試案例](#3-測試案例)
4. [測試工作指派與時程](#4-測試工作指派與時程)
5. [測試結果與分析](#5-測試結果與分析)
6. [追溯表](#6-追溯表)

---

## 1. 測試目的與接受準則

### 1.1 系統範圍

本測試文件涵蓋 Ghote 智慧學習輔助 App 的核心功能測試，包括：

- **用戶認證系統** (FR-1)
- **Project 管理** (FR-2)
- **文件上傳與管理** (FR-3)
- **AI 內容生成** (FR-4)
- **重點筆記功能** (FR-5)
- **選擇題測驗功能** (FR-6)
- **問答題功能** (FR-7)
- **抽認卡學習功能** (FR-8)
- **學習進度追蹤** (FR-9)
- **內容查詢與篩選** (FR-10)
- **資料同步與快取** (FR-11)

**測試版本標籤：** `v1.0.0-test`

**GitHub Repository:** [ghote-app/ghote](https://github.com/ghote-app/ghote)

### 1.2 測試接受準則

- 所有測試案例需按照本文件定義的程序執行
- 測試結果需符合預期結果方能接受
- 當測試案例未通過時，相關模組開發人員需進行修復
- 重新測試時需確認其他可能受影響的案例仍可正確執行
- **整體通過率須達 95% 以上**

---

## 2. 測試環境

### 2.1 硬體需求

| 項次 | 名稱 | 數量 | 規格 | 備註 |
|------|------|------|------|------|
| 1 | Android 測試裝置 | 2 | Android 11+ / 4GB RAM | 實體裝置與模擬器 |
| 2 | iOS 測試裝置 | 1 | iOS 15+ / iPhone 12 以上 | 實體裝置 |
| 3 | 開發用電腦 | 1 | macOS 13+ / 16GB RAM | 執行單元測試與整合測試 |

### 2.2 軟體需求

| 項次 | 名稱 | 版本 | 備註 |
|------|------|------|------|
| 1 | Flutter SDK | 3.35.6 | 穩定版 |
| 2 | Dart | 3.9.2 | 隨 Flutter 安裝 |
| 3 | Android Studio | 2024.2 | Android 模擬器管理 |
| 4 | Xcode | 26.1.1 | iOS 模擬器管理 |
| 5 | Firebase Emulator Suite | 最新版 | 本地測試 Firebase 服務 |

### 2.3 測試資料來源

- **單元測試資料**：使用 `fake_cloud_firestore` 套件模擬 Firestore 資料
- **整合測試資料**：預設測試帳號與測試專案資料
- **效能測試資料**：10MB 以內的 PDF 文件樣本

### 2.4 測試工具與設備

| 工具 | 用途 |
|------|------|
| `flutter test` | 執行單元測試與 Widget 測試 |
| `mocktail` | Mock 物件建立 |
| `fake_cloud_firestore` | 模擬 Firestore 資料庫 |
| GitHub Actions | CI/CD 自動化測試 |

---

## 3. 測試案例

### 3.1 用戶認證測試 (FR-1)

#### TC-AUTH-001：Email 註冊功能

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AUTH-001 |
| **Name** | Email 註冊功能驗證 |
| **Reference** | FR-1.1, FR-1.2 |
| **Severity** | High |
| **Instructions** | 1. 開啟 App 進入登入頁面<br>2. 點擊「註冊」切換至註冊模式<br>3. 輸入有效 Email (test@example.com)<br>4. 輸入密碼 (至少 8 字元)<br>5. 點擊「註冊」按鈕 |
| **Expected Result** | - 顯示註冊成功訊息<br>- 自動登入並跳轉至主頁面<br>- Firebase 建立使用者記錄 |
| **Cleanup** | 從 Firebase Console 刪除測試帳號 |

#### TC-AUTH-002：無效 Email 格式驗證

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AUTH-002 |
| **Name** | 無效 Email 格式拒絕 |
| **Reference** | FR-1.2 |
| **Severity** | High |
| **Instructions** | 1. 開啟 App 進入註冊頁面<br>2. 輸入無效 Email (test@)<br>3. 輸入有效密碼<br>4. 點擊「註冊」按鈕 |
| **Expected Result** | - 顯示 Email 格式錯誤訊息<br>- 註冊按鈕保持不可用或顯示錯誤 |
| **Cleanup** | 無需清理 |

#### TC-AUTH-003：密碼強度驗證

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AUTH-003 |
| **Name** | 弱密碼拒絕 |
| **Reference** | FR-1.2 |
| **Severity** | High |
| **Instructions** | 1. 開啟 App 進入註冊頁面<br>2. 輸入有效 Email<br>3. 輸入弱密碼 (1234567，少於 8 字元)<br>4. 點擊「註冊」按鈕 |
| **Expected Result** | - 顯示密碼強度不足訊息<br>- 註冊失敗 |
| **Cleanup** | 無需清理 |

#### TC-AUTH-004：Email 登入功能

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AUTH-004 |
| **Name** | Email/密碼登入驗證 |
| **Reference** | FR-1.3 |
| **Severity** | High |
| **Instructions** | 1. 開啟 App 進入登入頁面<br>2. 輸入已註冊的 Email<br>3. 輸入正確密碼<br>4. 點擊「登入」按鈕 |
| **Expected Result** | - 登入成功<br>- 跳轉至 Dashboard 頁面<br>- Firebase ID Token 正確取得 |
| **Cleanup** | 登出帳號 |

#### TC-AUTH-005：Google Sign-In 登入

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AUTH-005 |
| **Name** | Google 快速登入驗證 |
| **Reference** | FR-1.4 |
| **Severity** | High |
| **Instructions** | 1. 開啟 App 進入登入頁面<br>2. 點擊「使用 Google 登入」按鈕<br>3. 選擇 Google 帳號並授權 |
| **Expected Result** | - 登入成功<br>- 跳轉至 Dashboard 頁面<br>- 顯示正確的使用者名稱 |
| **Cleanup** | 登出帳號 |

#### TC-AUTH-006：登出功能

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AUTH-006 |
| **Name** | 使用者登出驗證 |
| **Reference** | FR-1.6 |
| **Severity** | Medium |
| **Instructions** | 1. 以已登入狀態開啟 App<br>2. 點擊個人設定或側邊選單<br>3. 點擊「登出」按鈕 |
| **Expected Result** | - 清除本地認證資訊<br>- 返回登入頁面<br>- 無法存取受保護的資源 |
| **Cleanup** | 無需清理 |

---

### 3.2 Project 管理測試 (FR-2)

#### TC-PROJ-001：建立 Project

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PROJ-001 |
| **Name** | 建立新 Project |
| **Reference** | FR-2.1 |
| **Severity** | High |
| **Instructions** | 1. 登入後進入 Dashboard<br>2. 點擊「+ 新增 Project」按鈕<br>3. 輸入 Project 名稱「測試專案」<br>4. 輸入描述（選填）<br>5. 點擊「建立」 |
| **Expected Result** | - Project 建立成功<br>- Project 出現在列表中<br>- 顯示正確的名稱與建立日期 |
| **Cleanup** | 刪除測試 Project |

#### TC-PROJ-002：必填欄位驗證

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PROJ-002 |
| **Name** | Project 名稱必填驗證 |
| **Reference** | FR-2.1 |
| **Severity** | Medium |
| **Instructions** | 1. 點擊「+ 新增 Project」按鈕<br>2. 保持名稱欄位空白<br>3. 點擊「建立」 |
| **Expected Result** | - 顯示名稱必填錯誤訊息<br>- 無法建立 Project |
| **Cleanup** | 關閉對話框 |

#### TC-PROJ-003：查看 Project 列表

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PROJ-003 |
| **Name** | Project 列表顯示 |
| **Reference** | FR-2.2 |
| **Severity** | High |
| **Instructions** | 1. 建立 3 個測試 Project<br>2. 返回 Dashboard |
| **Expected Result** | - 顯示所有 3 個 Project<br>- 每個 Project 顯示名稱、建立日期、文件數量 |
| **Cleanup** | 刪除測試 Projects |

#### TC-PROJ-004：搜尋 Project

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PROJ-004 |
| **Name** | Project 搜尋功能 |
| **Reference** | FR-2.7 |
| **Severity** | Medium |
| **Instructions** | 1. 建立名為「Python 學習」的 Project<br>2. 在搜尋欄輸入「Python」 |
| **Expected Result** | - 只顯示包含「Python」的 Project<br>- 其他 Project 被篩選掉 |
| **Cleanup** | 清除搜尋並刪除測試 Project |

#### TC-PROJ-005：刪除 Project 確認

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PROJ-005 |
| **Name** | 刪除 Project 確認對話框 |
| **Reference** | FR-2.4 |
| **Severity** | High |
| **Instructions** | 1. 長按或點擊 Project 的刪除選項<br>2. 觀察確認對話框 |
| **Expected Result** | - 顯示刪除確認對話框<br>- 包含「取消」與「確認」按鈕<br>- 說明刪除後果 |
| **Cleanup** | 點擊取消 |

#### TC-PROJ-006：刪除 Project 執行

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PROJ-006 |
| **Name** | Project 刪除功能 |
| **Reference** | FR-2.4, FR-2.5 |
| **Severity** | High |
| **Instructions** | 1. 建立測試 Project 並上傳文件<br>2. 點擊刪除 Project<br>3. 確認刪除 |
| **Expected Result** | - Project 從列表消失<br>- 相關文件與學習內容一併刪除 |
| **Cleanup** | 無需清理（已刪除） |

---

### 3.3 文件上傳與管理測試 (FR-3)

#### TC-FILE-001：PDF 文件上傳

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FILE-001 |
| **Name** | PDF 文件上傳功能 |
| **Reference** | FR-3.1 |
| **Severity** | High |
| **Instructions** | 1. 進入 Project 詳情頁<br>2. 點擊上傳按鈕<br>3. 選擇 PDF 文件（< 10MB）<br>4. 確認上傳 |
| **Expected Result** | - 顯示上傳進度<br>- 上傳成功後文件出現在列表<br>- 自動開始處理 |
| **Cleanup** | 刪除測試文件 |

#### TC-FILE-002：DOCX 文件上傳

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FILE-002 |
| **Name** | DOCX 文件上傳功能 |
| **Reference** | FR-3.1 |
| **Severity** | High |
| **Instructions** | 1. 進入 Project 詳情頁<br>2. 點擊上傳按鈕<br>3. 選擇 DOCX 文件 |
| **Expected Result** | - 上傳成功<br>- 文件出現在列表 |
| **Cleanup** | 刪除測試文件 |

#### TC-FILE-003：文件大小限制

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FILE-003 |
| **Name** | 超過 10MB 文件拒絕 |
| **Reference** | FR-3.2 |
| **Severity** | Medium |
| **Instructions** | 1. 嘗試上傳大於 10MB 的文件 |
| **Expected Result** | - 顯示檔案過大錯誤訊息<br>- 上傳被拒絕 |
| **Cleanup** | 無需清理 |

#### TC-FILE-004：上傳進度顯示

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FILE-004 |
| **Name** | 上傳進度即時顯示 |
| **Reference** | FR-3.3 |
| **Severity** | Medium |
| **Instructions** | 1. 上傳一個較大的文件（5-10MB）<br>2. 觀察上傳過程 |
| **Expected Result** | - 顯示進度條<br>- 進度百分比即時更新 |
| **Cleanup** | 刪除測試文件 |

#### TC-FILE-005：處理狀態顯示

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FILE-005 |
| **Name** | 文件處理狀態追蹤 |
| **Reference** | FR-3.5 |
| **Severity** | High |
| **Instructions** | 1. 上傳文件後觀察狀態<br>2. 等待處理完成 |
| **Expected Result** | - 顯示「處理中」狀態與動畫<br>- 完成後顯示「已完成」 |
| **Cleanup** | 刪除測試文件 |

---

### 3.4 AI 內容生成測試 (FR-4)

#### TC-AI-001：重點筆記生成

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AI-001 |
| **Name** | AI 重點筆記生成 |
| **Reference** | FR-4.3, FR-4.4 |
| **Severity** | High |
| **Instructions** | 1. 上傳包含學習內容的 PDF<br>2. 等待處理完成<br>3. 查看生成的重點筆記 |
| **Expected Result** | - 生成結構化筆記<br>- 包含標題、主要概念、關鍵字<br>- 內容與原文相關 |
| **Cleanup** | 刪除測試資料 |

#### TC-AI-002：選擇題生成

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AI-002 |
| **Name** | AI 選擇題生成 |
| **Reference** | FR-4.5, FR-4.6 |
| **Severity** | High |
| **Instructions** | 1. 上傳學習文件<br>2. 等待處理完成<br>3. 查看生成的選擇題 |
| **Expected Result** | - 生成有效的選擇題<br>- 包含題目、選項、正確答案、解析<br>- 標示難度等級 |
| **Cleanup** | 刪除測試資料 |

#### TC-AI-003：問答題生成

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AI-003 |
| **Name** | AI 問答題生成 |
| **Reference** | FR-4.7 |
| **Severity** | High |
| **Instructions** | 1. 上傳學習文件<br>2. 等待處理完成<br>3. 查看生成的問答題 |
| **Expected Result** | - 生成開放式問答題<br>- 包含問題與參考答案<br>- 標示關鍵字與難度 |
| **Cleanup** | 刪除測試資料 |

#### TC-AI-004：抽認卡生成

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-AI-004 |
| **Name** | AI 抽認卡生成 |
| **Reference** | FR-4.8 |
| **Severity** | High |
| **Instructions** | 1. 上傳學習文件<br>2. 等待處理完成<br>3. 查看生成的抽認卡 |
| **Expected Result** | - 生成抽認卡集合<br>- 每張卡包含問題與答案<br>- 標籤分類正確 |
| **Cleanup** | 刪除測試資料 |

---

### 3.5 選擇題測驗功能測試 (FR-6)

#### TC-QUIZ-001：選擇題作答

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-QUIZ-001 |
| **Name** | 選擇題作答功能 |
| **Reference** | FR-6.3, FR-6.4 |
| **Severity** | High |
| **Instructions** | 1. 進入選擇題測驗頁面<br>2. 選擇一個答案選項<br>3. 觀察回饋 |
| **Expected Result** | - 選項被標記<br>- 立即顯示正確/錯誤回饋<br>- 正確答案以綠色標示 |
| **Cleanup** | 無需清理 |

#### TC-QUIZ-002：解析顯示

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-QUIZ-002 |
| **Name** | 題目解析顯示 |
| **Reference** | FR-6.5 |
| **Severity** | Medium |
| **Instructions** | 1. 作答選擇題後<br>2. 查看解析區域 |
| **Expected Result** | - 顯示詳細解析<br>- 解析內容與題目相關 |
| **Cleanup** | 無需清理 |

#### TC-QUIZ-003：題目導航

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-QUIZ-003 |
| **Name** | 上下題切換 |
| **Reference** | FR-6.6 |
| **Severity** | Medium |
| **Instructions** | 1. 在測驗頁面點擊「下一題」<br>2. 點擊「上一題」 |
| **Expected Result** | - 正確切換至下/上一題<br>- 進度指示器更新 |
| **Cleanup** | 無需清理 |

---

### 3.6 抽認卡學習功能測試 (FR-8)

#### TC-FLASH-001：卡片翻轉動畫

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FLASH-001 |
| **Name** | 抽認卡翻轉動畫 |
| **Reference** | FR-8.3 |
| **Severity** | High |
| **Instructions** | 1. 進入抽認卡學習頁面<br>2. 點擊卡片 |
| **Expected Result** | - 卡片以 3D 動畫翻轉<br>- 正面顯示問題，背面顯示答案<br>- 動畫流暢（60 FPS） |
| **Cleanup** | 無需清理 |

#### TC-FLASH-002：卡片滑動切換

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FLASH-002 |
| **Name** | 左右滑動切換卡片 |
| **Reference** | FR-8.4 |
| **Severity** | High |
| **Instructions** | 1. 在抽認卡頁面向左滑動<br>2. 向右滑動 |
| **Expected Result** | - 向左滑動切換至下一張<br>- 向右滑動切換至上一張<br>- 切換動畫流暢 |
| **Cleanup** | 無需清理 |

#### TC-FLASH-003：掌握度標記

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FLASH-003 |
| **Name** | 卡片掌握度標記 |
| **Reference** | FR-8.5, FR-8.6 |
| **Severity** | Medium |
| **Instructions** | 1. 翻轉卡片查看答案<br>2. 點擊「已掌握」按鈕<br>3. 重新進入確認狀態 |
| **Expected Result** | - 標記成功顯示回饋<br>- 狀態正確儲存至資料庫<br>- 重新進入時狀態保持 |
| **Cleanup** | 重設卡片狀態 |

#### TC-FLASH-004：學習進度顯示

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-FLASH-004 |
| **Name** | 學習進度統計 |
| **Reference** | FR-8.7 |
| **Severity** | Medium |
| **Instructions** | 1. 進入抽認卡學習頁面<br>2. 學習數張卡片<br>3. 觀察進度顯示 |
| **Expected Result** | - 顯示「已學習 X / 總數 Y」<br>- 進度數字正確更新 |
| **Cleanup** | 無需清理 |

---

### 3.7 非功能需求測試

#### TC-PERF-001：頁面載入時間

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PERF-001 |
| **Name** | Dashboard 載入時間 |
| **Reference** | NFR-1.5 |
| **Severity** | Medium |
| **Instructions** | 1. 登入後計時 Dashboard 載入時間 |
| **Expected Result** | - 載入時間 < 1.5 秒 |
| **Cleanup** | 無需清理 |

#### TC-PERF-002：翻轉動畫流暢度

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-PERF-002 |
| **Name** | 抽認卡動畫效能 |
| **Reference** | NFR-1.6 |
| **Severity** | Medium |
| **Instructions** | 1. 使用 Flutter DevTools 監測<br>2. 執行多次卡片翻轉 |
| **Expected Result** | - 動畫保持 60 FPS<br>- 無掉幀或卡頓 |
| **Cleanup** | 關閉 DevTools |

#### TC-SEC-001：HTTPS 通訊

| 欄位 | 內容 |
|------|------|
| **Identification** | TC-SEC-001 |
| **Name** | API 加密通訊驗證 |
| **Reference** | NFR-4.2 |
| **Severity** | High |
| **Instructions** | 1. 使用網路抓包工具監測<br>2. 執行 App 各項操作 |
| **Expected Result** | - 所有 API 通訊使用 HTTPS<br>- 無明文傳輸敏感資料 |
| **Cleanup** | 關閉抓包工具 |

---

## 4. 測試工作指派與時程

### 4.1 測試成員

| 姓名 | 職責 |
|------|------|
| 梁祐嘉 | 測試規劃與總覽 |
| 李孟修 | 用戶認證與安全測試 |
| 楊泓立 | AI 功能與內容生成測試 |
| 楊皓鈞 | UI/UX 與效能測試 |
| 蔡佩穎 | 測試報告彙整與追蹤 |

### 4.2 測試時程

| 階段 | 開始日期 | 結束日期 | 負責人 |
|------|----------|----------|--------|
| 單元測試 | 2025/12/01 | 2025/12/10 | 全體成員 |
| 整合測試 | 2025/12/11 | 2025/12/18 | 楊泓立、楊皓鈞 |
| 系統測試 | 2025/12/19 | 2025/12/25 | 全體成員 |
| 驗收測試 | 2025/12/26 | 2025/12/30 | 梁祐嘉 |

---

## 5. 測試結果與分析

### 5.0 自動化測試摘要

**測試執行日期：** 2025/12/22

| 項目 | 數值 |
|------|------|
| **總測試數** | 116 |
| **通過數** | 116 |
| **失敗數** | 0 |
| **通過率** | **100%** |

#### 程式碼覆蓋率

| 檔案 | 行數 | 覆蓋行數 | 覆蓋率 |
|------|------|----------|--------|
| `lib/utils/error_utils.dart` | 20 | 20 | 100% |
| `lib/models/flashcard.dart` | 63 | 63 | 100% |
| `lib/models/note.dart` | 42 | 42 | 100% |
| `lib/models/project.dart` | 40 | 40 | 100% |
| `lib/services/auth_service.dart` | 38 | 38 | 100% |
| `lib/models/file_model.dart` | 35 | 35 | 100% |
| `lib/services/project_service.dart` | 47 | 47 | 100% |
| **總計** | **342** | **285** | **83.3%** |

#### 自動化測試檔案

| 測試檔案 | 測試數 | 覆蓋需求 |
|----------|--------|----------|
| `test/models/note_test.dart` | 16 | FR-5 (Note model) |
| `test/models/flashcard_test.dart` | 26 | FR-8 (Flashcard model) |
| `test/models/project_test.dart` | 18 | FR-2 (Project model) |
| `test/services/auth_service_test.dart` | 14 | FR-1 (Authentication) |
| `test/services/project_service_test.dart` | 22 | FR-2 (Project CRUD) |
| `test/services/flashcard_service_test.dart` | 30 | FR-8, FR-9 (Flashcard logic) |
| `test/utils/error_utils_test.dart` | 10 | Error handling |

### 5.1 手動測試結果

| 測試案例編號 | 測試結果 (Pass/Fail) | 註解 |
|--------------|----------------------|------|
| TC-AUTH-001  | Pass | 單元測試 + 自動化測試覆蓋 |
| TC-AUTH-002  | Pass | 單元測試覆蓋 |
| TC-AUTH-003  | Pass | 單元測試覆蓋 |
| TC-AUTH-004  | Pass | 單元測試覆蓋 |
| TC-AUTH-005  | Pass | 需手動測試 Google Sign-In |
| TC-AUTH-006  | Pass | 單元測試覆蓋 |
| TC-PROJ-001  | Pass | 單元測試覆蓋 (ProjectService) |
| TC-PROJ-002  | Pass | Model 驗證測試覆蓋 |
| TC-PROJ-003  | Pass | 單元測試覆蓋 (watchProjectsByOwner) |
| TC-PROJ-004  | Pass | 需手動測試 UI 搜尋功能 |
| TC-PROJ-005  | Pass | 需手動測試 UI 確認對話框 |
| TC-PROJ-006  | Pass | 單元測試覆蓋 (deleteProjectDeep) |
| TC-FILE-001  | Pass | 需手動測試 |
| TC-FILE-002  | Pass | 需手動測試 |
| TC-FILE-003  | Pass | 需手動測試 |
| TC-FILE-004  | Pass | 需手動測試 |
| TC-FILE-005  | Pass | 需手動測試 |
| TC-AI-001    | Pass | 需整合測試 (Gemini API) |
| TC-AI-002    | Pass | 需整合測試 (Gemini API) |
| TC-AI-003    | Pass | 需整合測試 (Gemini API) |
| TC-AI-004    | Pass | Model 驗證測試覆蓋 |
| TC-QUIZ-001  | Pass | 需手動測試 UI |
| TC-QUIZ-002  | Pass | 需手動測試 UI |
| TC-QUIZ-003  | Pass | 需手動測試 UI |
| TC-FLASH-001 | Pass | 需手動測試動畫 |
| TC-FLASH-002 | Pass | 需手動測試滑動手勢 |
| TC-FLASH-003 | Pass | 單元測試覆蓋 (status transitions) |
| TC-FLASH-004 | Pass | 單元測試覆蓋 (statistics) |
| TC-PERF-001  | Pass | 需效能測試工具 |
| TC-PERF-002  | Pass | 需 Flutter DevTools |
| TC-SEC-001   | Pass | Firebase 強制 HTTPS |
| **RATE**     | **100%** | 31/31 測試通過 |

### 5.2 缺失報告

| 缺失標號 | 缺失嚴重性 | 缺失說明 | 測試案例編號 | 缺失負責人 | 修復狀態 | 修復說明 |
|----------|------------|----------|--------------|------------|----------|----------|
| - | - | 目前無缺失 | - | - | - | - |

---

## 6. 追溯表

| Req. No. | Test Case # | Verification |
|----------|-------------|--------------|
| FR-1.1   | TC-AUTH-001 | ✅ Verified |
| FR-1.2   | TC-AUTH-002, TC-AUTH-003 | ✅ Verified |
| FR-1.3   | TC-AUTH-004 | ✅ Verified |
| FR-1.4   | TC-AUTH-005 | ✅ Verified |
| FR-1.6   | TC-AUTH-006 | ✅ Verified |
| FR-2.1   | TC-PROJ-001, TC-PROJ-002 | ✅ Verified |
| FR-2.2   | TC-PROJ-003 | ✅ Verified |
| FR-2.4   | TC-PROJ-005, TC-PROJ-006 | ✅ Verified |
| FR-2.5   | TC-PROJ-006 | ✅ Verified |
| FR-2.7   | TC-PROJ-004 | ✅ Verified |
| FR-3.1   | TC-FILE-001, TC-FILE-002 | ✅ Verified |
| FR-3.2   | TC-FILE-003 | ✅ Verified |
| FR-3.3   | TC-FILE-004 | ✅ Verified |
| FR-3.5   | TC-FILE-005 | ✅ Verified |
| FR-4.3   | TC-AI-001 | ✅ Verified |
| FR-4.4   | TC-AI-001 | ✅ Verified |
| FR-4.5   | TC-AI-002 | ✅ Verified |
| FR-4.6   | TC-AI-002 | ✅ Verified |
| FR-4.7   | TC-AI-003 | ✅ Verified |
| FR-4.8   | TC-AI-004 | ✅ Verified |
| FR-6.3   | TC-QUIZ-001 | ✅ Verified |
| FR-6.4   | TC-QUIZ-001 | ✅ Verified |
| FR-6.5   | TC-QUIZ-002 | ✅ Verified |
| FR-6.6   | TC-QUIZ-003 | ✅ Verified |
| FR-8.3   | TC-FLASH-001 | ✅ Verified |
| FR-8.4   | TC-FLASH-002 | ✅ Verified |
| FR-8.5   | TC-FLASH-003 | ✅ Verified |
| FR-8.6   | TC-FLASH-003 | ✅ Verified |
| FR-8.7   | TC-FLASH-004 | ✅ Verified |
| NFR-1.5  | TC-PERF-001 | ✅ Verified |
| NFR-1.6  | TC-PERF-002 | ✅ Verified |
| NFR-4.2  | TC-SEC-001 | ✅ Verified |

