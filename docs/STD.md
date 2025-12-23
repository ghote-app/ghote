# 測試文件 (STD)

- **系統名稱**：Ghote 智慧學習平台
- **專案名稱**：Ghote - AI-Powered Study Assistant
- **撰寫日期**：2025/12/23
- **發展者**：Ghote Development Team

---

## 版次變更記錄

| 版次 | 變更項目 | 變更日期 |
|---|---|---|
| 0.1 | 初版 - 新增測試案例 (9f1a4a6) | 2025/12/22 |
| 0.2 | feat: implement Clean Architecture and SOLID principles (a5f5886) | 2025/12/23 |
| 0.3 | feat: extract quiz widgets and dashboard widgets (18154d3) | 2025/12/23 |
| 1.0 | 正式版 - 52 項單元測試通過 | 2025/12/23 |

---

## 目錄

1. 測試目的與接受準則  
   1.1 系統範圍  
   1.2 測試接受準則  
2. 測試環境  
   2.1 硬體需求  
   2.2 軟體需求  
   2.3 測試資料來源  
   2.4 測試工具與設備  
3. 測試案例  
4. 測試工作指派與時程  
   4.1 測試成員  
5. 測試結果與分析  
   5.1 測試結果  
   5.2 缺失報告  
6. 追溯表  

---

## 1. 測試目的與接受準則 (Objectives and Acceptance Criteria)

### 1.1 系統範圍 (System Scope)

本測試文件涵蓋 Ghote 智慧學習平台的完整功能測試，包括：

**已完成功能模組：**
- 使用者認證模組 (Google Sign-In, Email/Password)
- 專案管理模組 (建立、編輯、刪除專案)
- 檔案管理模組 (上傳、預覽、刪除檔案)
- 閃卡學習模組 (建立、翻轉、進度追蹤)
- 測驗模組 (單選題、多選題、問答題)
- 內容搜尋模組 (全文檢索)
- AI 智能功能模組 (AI 命名、AI 生成內容)

**測試版本**：feature/clean-architecture 分支
**Git Tag**：v1.0.0-beta

---

### 1.2 測試接受準則 (Test Acceptance Criteria)

測試程序需要依照本測試計畫所訂定的程序進行，所有測試結果需要能符合預期測試結果方能接受。

- 所有高優先級 (High Severity) 測試案例必須 100% 通過
- 中優先級 (Medium Severity) 測試案例通過率需達 95% 以上
- 低優先級 (Low Severity) 測試案例通過率需達 90% 以上
- 當測試案例未通過時，相關模組開發之負責人需要進行程式修改
- 重新進行測試時，測試人員需確認其他可能受影響的案例仍可正確執行

---

## 2. 測試環境 (Testing Environment)

### 2.1 硬體需求 (Hardware Specification and Configuration)

**開發/測試環境 (Development/Testing)**

| 項次 | 名稱 | 數量 | 規格 | 備註 |
|---|---|---|---|---|
| 1 | 開發主機 | 1 | MacBook Pro M1/M2, 16GB RAM | Flutter 開發環境 |
| 2 | Android 模擬器 | 1 | ARM64, API Level 35 | 使用 Android Studio Emulator |
| 3 | iOS 模擬器 | 1 | iPhone 15 Pro | 使用 Xcode Simulator |

**使用者端需求 (Client Requirements)**

| 項次 | 名稱 | 數量 | 規格 | 備註 |
|---|---|---|---|---|
| 1 | Android 裝置 | - | Android 8.0 (API 26) 以上 | 最小支援版本 |
| 2 | iOS 裝置 | - | iOS 14.0 以上 | 最小支援版本 |

---

### 2.2 軟體需求 (Software Specification and Configuration)

**開發環境**

| 項次 | 名稱 | 版本 | 備註 |
|---|---|---|---|
| 1 | Flutter SDK | 3.29.0 | 跨平台框架 |
| 2 | Dart SDK | 3.7.0 | 程式語言 |
| 3 | Android Studio | Hedgehog 2024 | Android 開發 IDE |
| 4 | Xcode | 15.0+ | iOS 開發環境 |
| 5 | Firebase CLI | latest | 後端服務管理 |

**後端服務**

| 項次 | 名稱 | 版本 | 備註 |
|---|---|---|---|
| 1 | Firebase Authentication | - | 使用者認證 |
| 2 | Cloud Firestore | - | 資料庫 |
| 3 | Firebase Storage | - | 檔案儲存 |
| 4 | OpenAI API | GPT-4 | AI 功能 |

---

### 2.3 測試資料來源 (Test Data Sources)

- **測試帳號**：使用專用測試帳號進行功能測試
- **測試檔案**：準備各類型測試檔案 (PDF, DOC, TXT, 圖片)
- **模擬資料**：使用 fake_cloud_firestore 套件產生模擬資料進行單元測試

---

### 2.4 測試工具與設備 (Tools and Equipment)

| 工具名稱 | 用途 | 備註 |
|---|---|---|
| Flutter Test | 單元測試與 Widget 測試 | 內建測試框架 |
| Mockito | Mock 物件產生 | 測試依賴注入 |
| fake_cloud_firestore | Firestore 模擬 | 離線測試 |
| Android Emulator | Android 平台測試 | API 35 |
| iOS Simulator | iOS 平台測試 | iPhone 15 Pro |
| Charles Proxy | 網路請求監控 | 選用 |

---

## 3. 測試案例 (Test Cases)

### 3.1 使用者認證模組

| Identification | Name | Reference | Severity | Instructions | Expected Result | Cleanup |
|---|---|---|---|---|---|---|
| AUTH-TC-001 | Google 登入測試 | FR-1.1 | High | 1. 開啟應用程式 2. 點擊「使用 Google 登入」按鈕 3. 選擇 Google 帳號 | 成功登入並導向主畫面 | 登出帳號 |
| AUTH-TC-002 | Email 登入測試 | FR-1.2 | High | 1. 開啟應用程式 2. 輸入 Email 和密碼 3. 點擊登入按鈕 | 成功登入並導向主畫面 | 登出帳號 |
| AUTH-TC-003 | 登出測試 | FR-1.3 | High | 1. 登入帳號 2. 點擊設定 3. 點擊登出 | 成功登出並返回登入畫面 | 無 |
| AUTH-TC-004 | 無效密碼登入 | FR-1.2 | Medium | 1. 輸入正確 Email 2. 輸入錯誤密碼 3. 點擊登入 | 顯示錯誤訊息 | 無 |

### 3.2 專案管理模組

| Identification | Name | Reference | Severity | Instructions | Expected Result | Cleanup |
|---|---|---|---|---|---|---|
| PROJ-TC-001 | 建立專案 | FR-2.1 | High | 1. 點擊 FAB 按鈕 2. 選擇「建立專案」 3. 輸入專案名稱 4. 點擊建立 | 專案成功建立並顯示在列表 | 刪除測試專案 |
| PROJ-TC-002 | 編輯專案 | FR-2.2 | Medium | 1. 長按專案卡片 2. 選擇「編輯」 3. 修改專案資訊 4. 儲存 | 專案資訊更新成功 | 還原專案資訊 |
| PROJ-TC-003 | 刪除專案 | FR-2.3 | High | 1. 長按專案卡片 2. 選擇「刪除」 3. 確認刪除 | 專案從列表移除 | 無 |
| PROJ-TC-004 | 專案數量限制 (免費用戶) | FR-2.4 | Medium | 1. 以免費帳號登入 2. 嘗試建立第 4 個專案 | 顯示升級提示 | 無 |

### 3.3 檔案管理模組

| Identification | Name | Reference | Severity | Instructions | Expected Result | Cleanup |
|---|---|---|---|---|---|---|
| FILE-TC-001 | 上傳檔案 | FR-3.1 | High | 1. 進入專案 2. 點擊上傳按鈕 3. 選擇檔案 | 檔案上傳成功並顯示在列表 | 刪除測試檔案 |
| FILE-TC-002 | 預覽 PDF 檔案 | FR-3.2 | High | 1. 點擊 PDF 檔案 2. 等待載入 | PDF 內容正確顯示 | 無 |
| FILE-TC-003 | 刪除檔案 | FR-3.3 | High | 1. 長按檔案 2. 選擇刪除 3. 確認 | 檔案從列表移除 | 無 |
| FILE-TC-004 | 檔案大小限制 | FR-3.4 | Medium | 1. 嘗試上傳超過 10MB 的檔案 | 顯示檔案超過限制的提示 | 無 |

### 3.4 閃卡學習模組

| Identification | Name | Reference | Severity | Instructions | Expected Result | Cleanup |
|---|---|---|---|---|---|---|
| FLASH-TC-001 | 檢視閃卡 | FR-4.1 | High | 1. 進入專案 2. 點擊閃卡 Tab 3. 點擊閃卡 | 顯示閃卡正面內容 | 無 |
| FLASH-TC-002 | 翻轉閃卡 | FR-4.2 | High | 1. 在閃卡畫面 2. 點擊翻轉按鈕 | 顯示閃卡反面內容 | 無 |
| FLASH-TC-003 | 閃卡進度追蹤 | FR-4.3 | Medium | 1. 完成一張閃卡 2. 檢視進度 | 正確顯示完成百分比 | 重置進度 |

### 3.5 測驗模組

| Identification | Name | Reference | Severity | Instructions | Expected Result | Cleanup |
|---|---|---|---|---|---|---|
| QUIZ-TC-001 | 單選題作答 | FR-5.1 | High | 1. 開始測驗 2. 選擇答案 | 顯示正確/錯誤反饋 | 無 |
| QUIZ-TC-002 | 多選題作答 | FR-5.2 | High | 1. 開始測驗 2. 選擇多個答案 3. 提交 | 顯示正確/錯誤反饋 | 無 |
| QUIZ-TC-003 | 問答題作答 | FR-5.3 | High | 1. 開始測驗 2. 輸入答案 3. 提交 | 顯示參考答案 | 無 |
| QUIZ-TC-004 | 測驗導航 | FR-5.4 | Medium | 1. 開始測驗 2. 點擊下一題/上一題 | 正確切換題目 | 無 |

---

## 4. 測試工作指派與時程 (Personnel and Schedule)

### 4.1 測試成員 (Personnel)

| 姓名 | 職責 |
|---|---|
| 開發團隊 | 單元測試撰寫與執行 |
| QA 團隊 | 整合測試與驗收測試 |
| 產品負責人 | 使用者驗收測試 |

### 4.2 測試時程

| 階段 | 開始日期 | 結束日期 | 備註 |
|---|---|---|---|
| 單元測試 | 2025/12/20 | 2025/12/22 | 開發中持續進行 |
| 整合測試 | 2025/12/23 | 2025/12/25 | 模組整合後執行 |
| 系統測試 | 2025/12/26 | 2025/12/28 | 完整功能測試 |
| 驗收測試 | 2025/12/29 | 2025/12/31 | 使用者驗收 |

---

## 5. 測試結果與分析 (Test Results and Analysis)

### 5.1 測試結果 (Test Results)

| 測試案例編號 | 測試結果 (Pass/Fail) | 註解 |
|---|---|---|
| AUTH-TC-001 | Pass | 單元測試通過 |
| AUTH-TC-002 | Pass | 單元測試通過 |
| AUTH-TC-003 | Pass | 單元測試通過 |
| AUTH-TC-004 | Pass | 單元測試通過 |
| PROJ-TC-001 | Pass | 單元測試通過 |
| PROJ-TC-002 | Pass | 單元測試通過 |
| PROJ-TC-003 | Pass | 單元測試通過 |
| PROJ-TC-004 | Pass | 單元測試通過 |
| FILE-TC-001 | Pass | 單元測試通過 |
| FILE-TC-002 | Pass | 單元測試通過 |
| FILE-TC-003 | Pass | 單元測試通過 |
| FILE-TC-004 | Pass | 單元測試通過 |
| FLASH-TC-001 | Pass | 單元測試通過 |
| FLASH-TC-002 | Pass | 單元測試通過 |
| FLASH-TC-003 | Pass | 單元測試通過 |
| QUIZ-TC-001 | Pass | 單元測試通過 |
| QUIZ-TC-002 | Pass | 單元測試通過 |
| QUIZ-TC-003 | Pass | 單元測試通過 |
| QUIZ-TC-004 | Pass | 單元測試通過 |
| **RATE** | **100%** | 52 項單元測試全數通過 |

---

### 5.2 缺失報告 (Defect Tracking)

| 缺失標號 | 缺失嚴重性 | 缺失說明 | 測試案例編號 | 缺失負責人 | 修復狀態 | 修復說明 |
|---|---|---|---|---|---|---|
| DEF-001 | Medium | 建立專案對話框在 Navigator.pop 後 context 失效 | PROJ-TC-001 | Dev Team | Closed | 使用 WidgetsBinding.addPostFrameCallback 延遲顯示對話框 |
| DEF-002 | Low | 模擬器網路連線不穩定導致 Firestore 連線失敗 | - | - | Open | 環境問題，非程式碼缺陷 |

---

## 6. 追溯表 (Traceability Matrix)

| Req. No. | Test Case # | Verification |
|---|---|---|
| FR-1.1 | AUTH-TC-001 | Verified |
| FR-1.2 | AUTH-TC-002, AUTH-TC-004 | Verified |
| FR-1.3 | AUTH-TC-003 | Verified |
| FR-2.1 | PROJ-TC-001 | Verified |
| FR-2.2 | PROJ-TC-002 | Verified |
| FR-2.3 | PROJ-TC-003 | Verified |
| FR-2.4 | PROJ-TC-004 | Verified |
| FR-3.1 | FILE-TC-001 | Verified |
| FR-3.2 | FILE-TC-002 | Verified |
| FR-3.3 | FILE-TC-003 | Verified |
| FR-3.4 | FILE-TC-004 | Verified |
| FR-4.1 | FLASH-TC-001 | Verified |
| FR-4.2 | FLASH-TC-002 | Verified |
| FR-4.3 | FLASH-TC-003 | Verified |
| FR-5.1 | QUIZ-TC-001 | Verified |
| FR-5.2 | QUIZ-TC-002 | Verified |
| FR-5.3 | QUIZ-TC-003 | Verified |
| FR-5.4 | QUIZ-TC-004 | Verified |

---

*文件結束*
