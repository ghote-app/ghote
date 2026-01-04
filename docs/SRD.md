# Group 1 軟體需求文件(SRD)

## 專案資訊
- **專案名稱**：Ghote 智慧學習輔助 App
- **撰寫日期**：2025/10/12
- **發展者**：專案團隊（5人）
    - Team Lead 梁祐嘉 、Full Stack Engineer 李孟修、Full Stack Engineer 楊泓立、Full Stack Engineer 楊皓鈞、Full Stack Engineer 蔡佩穎
- **GitHub Repository**: [ghote-app/ghote](https://github.com/ghote-app/ghote)
- **Trello 看板**: [專案管理看板](https://trello.com/b/YWoNO5Jg)
- **Firebase Project**: ghote-app

---

## 版次變更記錄

| 版次 | 變更項目 | 變更日期 |
|------|----------|----------|
| 0.1  | 初版需求擬定 (基於 Client-Server 架構) | 2025/10/01 |
| 0.2  | 架構調整為 Serverless (Firebase) 以降低維運成本 | 2025/10/15 |
| 0.3  | 詳細定義 AI 生成內容格式 (JSON Schema) | 2025/11/01 |
| 0.4  | 優化使用者介面流程與互動設計 | 2025/11/15 |
| 1.0  | 正式版需求確認 (與實作一致) | 2025/11/26 |
| 1.1  | docs: add SDD and SRD documentation (7209406) | 2025/12/22 |
| 1.2  | feat: add unit test infrastructure and tests (9f1a4a6) | 2025/12/22 |
| 1.3  | feat: implement Clean Architecture and SOLID principles (a5f5886) | 2025/12/23 |
| 1.4  | docs: rename flashcard to learn card (抽認卡 → 學習卡) | 2026/01/04 |

---

## 目錄
1. [接受準則 (Acceptance Criteria)](#section1)
2. [系統概述 (System Description)](#section2)
3. [操作概念 (Operational Concepts)](#section3)
4. [使用者故事地圖 (User Story Map)](#section4)
5. [使用者介面分析 (User Interface Analysis)](#section5)
6. [功能需求 (Functional Requirements)](#section6)
7. [非功能需求 (Non-functional Requirements)](#section7)

---

## <span id="section1">接受準則 (Acceptance Criteria of this document)</span>
- Clearly and properly stated（需求需清楚且適當的陳述）
- Complete（需求需完整）
- Consistent with each other（需求之間需維持一致性）
- Uniquely identified（每項需求有明確之識別）
- Appropriate to implement（需求需可被實作）
- Verifiable（需求需可被驗證）

---

## <span id="section2">系統概述 (System Description)</span>

### 系統目標
Ghote 旨在成為學生和終身學習者的智能學習夥伴，透過 AI 技術自動從學習資料中提取核心知識，並以多種形式呈現學習內容，包括重點筆記、選擇題、問答題及學習卡。用戶可以建立 Project 管理不同科目或主題的學習資料，AI 會自動分析並生成各種學習材料。

### 系統架構圖

```
┌──────────────────────────────────────────────────────────┐
│         Firebase Authentication (Google)                 │
│  - Email/Password 認證                                   │
│  - Google Sign-In                                        │
│  - Token 管理與刷新                                       │
│  成本：$0 (完全免費)                                      │
└──────────────────┬───────────────────────────────────────┘
                   │ Firebase ID Token / User UID
┌──────────────────▼───────────────────────────────────────┐
│              Frontend (Flutter App)                      │
│  - 用戶介面與互動                                          │
│  - 業務邏輯處理                                           │
│  - 狀態管理 (setState / StreamBuilder)                   │
│  - 路由管理 (GoRouter)                                    │
│  - 本地文件處理 (PDF/Docx 提取)                           │
└──────┬───────────────────────────────┬──────────────────┘
       │                               │
       │ Firestore SDK                 │ Gemini SDK
┌──────▼─────────────┐      ┌─────────▼────────────────┐
│  Cloud Firestore   │      │   Google Gemini API      │
│  (NoSQL Database)  │      │   - 文本分析              │
│  - 用戶資料         │      │   - 重點整理              │
│  - Projects        │      │   - 題目生成              │
│  - 學習內容         │      │   - 聊天互動              │
│  成本：$0 (免費額度) │      │   成本：$0 (Free Plan)    │
└────────────────────┘      └──────────────────────────┘
       │
       │ Firebase Storage SDK
┌──────▼─────────────┐
│  Firebase Storage  │
│  - 文件儲存 (PDF)   │
│  - 圖片儲存         │
│  成本：$0 (免費額度) │
└────────────────────┘

總成本：$0/月 (MVP 階段，使用 Firebase Spark Plan 與 Gemini Free Plan)
```

### 實作方案

**前端技術棧：**
- 框架：Flutter (Dart)
- 狀態管理：setState / StreamBuilder (原生)
- 路由：GoRouter
- HTTP 通訊：Dio (輔助), Firebase SDK (主要)
- 本地儲存：SharedPreferences
- 認證：Firebase Authentication SDK

**後端服務 (Serverless)：**
- 平台：Firebase
- 資料庫：Cloud Firestore (NoSQL)
- 文件儲存：Firebase Storage
- 託管：Firebase Hosting (Web 版)

**AI/ML 技術棧：**
- LLM 服務：Google Gemini API (透過 `google_generative_ai` SDK)
- 客戶端文件處理：
    - `syncfusion_flutter_pdf` (PDF 文字提取)
    - `docx_to_text` (Word 文字提取)
    - `google_mlkit_text_recognition` (圖片 OCR)

**DevOps：**
- 版本控制：Git / GitHub
- CI/CD：GitHub Actions
- 專案管理：Trello

---

## <span id="section3">操作概念 (Operational Concepts)</span>

### 主要使用情境

#### 情境一：學生上傳課程講義並生成學習材料

**角色：** 大學生小明

**故事描述：**
小明正在準備期中考試，他有一份 PDF 格式的資料結構課程講義。他打開 Ghote App，選擇「資料結構」這個 Project，點擊上傳按鈕，選擇講義檔案。上傳完成後，系統顯示「處理中」的動畫。約 30 秒後，系統通知處理完成。

小明可以選擇查看：
1. **重點筆記**：AI 自動整理的結構化筆記，包含重要概念與關鍵字
2. **選擇題**：20 題多選與單選題目，附帶詳細解析
3. **問答題**：10 題開放式問題，幫助深入理解
4. **學習卡**：50 張卡片，正面是問題，背面是答案

小明先閱讀重點筆記快速複習，然後使用選擇題自我測驗，最後用學習卡進行記憶訓練。系統會記錄他的學習進度，標記困難的題目供日後複習。

#### 情境二：終身學習者管理多個學習主題

**角色：** 職場工作者小華

**故事描述：**
小華同時在學習 Python 程式設計和數位行銷。她在 Ghote 中建立了兩個 Project：「Python 學習」和「數位行銷筆記」。

在「Python 學習」Project 中，她上傳了多份教學文件和程式碼範例。AI 為每份文件生成對應的學習材料。小華可以在 Project 內查看所有文件的學習進度，系統會提醒她哪些內容需要複習。

週末時，小華切換到「數位行銷筆記」Project，上傳新的行銷案例分析文件。系統同樣自動生成學習材料，讓她能夠有效管理不同領域的學習內容。

### 系統運作流程

**完整功能流程（Serverless 模式）：**

1. **使用者上傳文件**
   - 使用者在 App 中選擇文件
   - App 上傳原始檔案至 Firebase Storage
   - App 使用本地函式庫提取文字 (PDF/Docx/OCR)

2. **AI 內容生成 (Client-side)**
   - App 將提取的文字組裝成 Prompt
   - App 呼叫 `GeminiService` 發送請求至 Google Gemini API
   - 接收 AI 回傳的 JSON 格式資料

3. **資料儲存**
   - App 解析 JSON 資料
   - App 透過 `Firestore SDK` 將生成的筆記、題目、學習卡寫入 Cloud Firestore
   - 更新文件處理狀態為 `Completed`

4. **使用者查看內容**
   - App 透過 `StreamBuilder` 監聽 Firestore 資料變化
   - 介面即時更新顯示最新的學習材料

### 主要介面說明

- **登入/註冊頁面**：使用 Firebase Authentication 的認證介面，支援 Email 註冊與 Google Sign-In
- **Project 列表頁面**：顯示所有學習 Project，支援新增、編輯、刪除
- **Project 詳情頁面**：顯示該 Project 下所有文件與學習進度
- **文件上傳頁面**：支援拖曳上傳，文件儲存至 Firebase Storage，顯示上傳進度與處理狀態
- **內容選擇頁面**：選擇要查看的內容類型（四種）
- **筆記閱讀頁面**：結構化顯示 AI 生成的重點筆記
- **題目測驗頁面**：顯示選擇題或問答題，支援作答與查看解析
- **學習卡頁面**：支援卡片翻轉動畫，標記困難卡片

---

## <span id="section4">使用者故事地圖 (User Story Map)</span>

完整的使用者故事地圖請參考：[Miro Board](https://miro.com/app/board/uXjVJ_OWob0=/?share_link_id=609063714267)

以下為 **MVP (Minimum Viable Product)** 階段的核心使用者故事：

### Epic 1: 用戶認證系統

#### Story: AUTH-US-01 使用者註冊
- **故事**：作為一位新用戶，我希望能使用 Email 透過 Firebase 註冊帳號，以便開始使用 Ghote。
- **註記**：
  - 使用 Firebase Authentication 處理註冊
  - Firebase 自動驗證 Email 格式
  - 密碼需符合安全要求（至少 8 字元，由 Firebase 驗證）
  - 註冊成功後自動登入並取得 Firebase Token
  - 支援 Google Sign-In 快速註冊
- **測試方法**：
  - 驗證無效 Email 格式會顯示 Firebase 錯誤訊息
  - 驗證弱密碼會被 Firebase 拒絕
  - 確認註冊成功後能自動跳轉至主頁面
  - 確認後端能接收並驗證 Firebase Token
  - 驗證 Google Sign-In 流程正常

#### Story: AUTH-US-02 使用者登入
- **故事**：作為一位已註冊用戶，我希望能使用帳號密碼透過 Firebase 登入，以便存取我的學習資料。
- **註記**：
  - 使用 Firebase Authentication 處理登入
  - 登入成功後取得 Firebase ID Token
  - Token 儲存於本地，維持登入狀態
  - 每次 API 請求自動附帶 Token
  - 支援 Google Sign-In 快速登入
  - 錯誤登入需顯示明確提示
- **測試方法**：
  - 驗證正確帳密能成功登入
  - 驗證錯誤帳密顯示 Firebase 錯誤訊息
  - 確認 Token 正確儲存與使用
  - 確認後端能成功驗證 Firebase Token
  - 驗證 Google Sign-In 登入流程

### Epic 2: Project 管理

#### Story: PROJ-US-01 建立 Project
- **故事**：作為一位學習者，我希望能建立新的 Project，以便組織不同科目的學習資料。
- **註記**：
  - Project 需有名稱與可選的描述
  - 可選擇 Project 的顏色標籤
  - 建立後自動進入 Project 詳情頁面
- **測試方法**：
  - 驗證必填欄位為空時無法建立
  - 確認建立成功後出現在 Project 列表
  - 驗證 Project 詳情頁面正確顯示資訊

#### Story: PROJ-US-02 查看 Project 列表
- **故事**：作為一位用戶，我希望能查看所有我建立的 Project，以便快速切換學習主題。
- **註記**：
  - 顯示 Project 名稱、建立日期、文件數量
  - 支援搜尋與排序功能
  - 點擊進入 Project 詳情頁面
- **測試方法**：
  - 確認所有 Project 正確顯示
  - 驗證搜尋功能運作正常
  - 確認排序功能有效

#### Story: PROJ-US-03 刪除 Project
- **故事**：作為一位用戶，我希望能刪除不需要的 Project，以便保持清單整潔。
- **註記**：
  - 刪除前需要確認提示
  - 刪除會連同 Project 內所有文件與學習資料
  - 刪除為永久性操作
- **測試方法**：
  - 驗證刪除確認對話框顯示
  - 確認取消刪除不會執行操作
  - 驗證刪除後 Project 從列表消失

### Epic 3: 文件處理與分析

#### Story: FILE-US-01 上傳文件
- **故事**：作為一位學習者，我希望能上傳 PDF/TXT/DOCX 文件到 Project 中，以便 AI 分析內容。
- **註記**：
  - 支援拖曳上傳與按鈕選擇
  - 顯示上傳進度條
  - 限制單檔大小不超過 10MB
  - 上傳成功後自動開始處理
- **測試方法**：
  - 驗證支援的檔案格式能成功上傳
  - 驗證不支援的格式顯示錯誤訊息
  - 確認上傳進度正確顯示
  - 驗證超過大小限制的檔案被拒絕

#### Story: FILE-US-02 查看處理狀態
- **故事**：作為一位用戶，我希望能即時查看文件處理狀態，以便知道何時能開始學習。
- **註記**：
  - 顯示「處理中」動畫與預估時間
  - 處理完成後顯示通知
  - 處理失敗需顯示錯誤原因
- **測試方法**：
  - 確認處理中狀態正確顯示動畫
  - 驗證完成通知能即時顯示
  - 確認失敗訊息清楚說明原因

### Epic 4: AI 內容生成

#### Story: AI-US-01 生成重點筆記
- **故事**：作為一位學習者，我希望 AI 能自動生成文件的重點筆記，以便快速掌握核心內容。
- **註記**：
  - 筆記需結構化顯示（標題、內容、重要性）
  - 包含關鍵字標籤
  - 支援展開/收合功能
- **測試方法**：
  - 驗證筆記格式正確且易讀
  - 確認關鍵字標籤正確顯示
  - 驗證展開/收合功能運作正常

#### Story: AI-US-02 生成選擇題
- **故事**：作為一位學習者，我希望 AI 能生成選擇題，以便自我測驗理解程度。
- **註記**：
  - 包含題目、選項、正確答案、解析
  - 支援單選與多選題
  - 標示題目難度
- **測試方法**：
  - 確認題目格式完整
  - 驗證答案選擇功能正常
  - 確認解析在作答後顯示

#### Story: AI-US-03 生成問答題
- **故事**：作為一位學習者,我希望 AI 能生成開放式問答題，以便訓練深入思考能力。
- **註記**：
  - 包含問題與參考答案
  - 標示關鍵字與難度
  - 支援使用者輸入答案（未來功能）
- **測試方法**：
  - 確認問答題格式正確
  - 驗證參考答案顯示完整
  - 確認難度標示清楚

#### Story: AI-US-04 生成學習卡
- **故事**：作為一位學習者，我希望 AI 能生成學習卡，以便進行快速記憶訓練。
- **註記**：
  - 卡片正面顯示問題，背面顯示答案
  - 支援翻轉動畫
  - 可標記為「已掌握」或「需複習」
  - 包含標籤分類
- **測試方法**：
  - 確認卡片翻轉動畫流暢
  - 驗證標記功能正常運作
  - 確認標籤正確顯示

### Epic 5: 學習介面

#### Story: LEARN-US-01 查看內容類型選單
- **故事**：作為一位用戶，我希望能輕鬆選擇要查看的內容類型，以便切換學習方式。
- **註記**：
  - 顯示四種內容類型圖示與名稱
  - 顯示各類型的數量
  - 點擊進入對應頁面
- **測試方法**：
  - 確認四種類型皆正確顯示
  - 驗證數量統計準確
  - 確認點擊跳轉正確

#### Story: LEARN-US-02 學習卡學習模式
- **故事**：作為一位學習者，我希望能使用學習卡模式學習，以便高效記憶知識點。
- **註記**：
  - 支援左右滑動切換卡片
  - 點擊卡片翻轉查看答案
  - 可標記「已掌握」/「需複習」/「困難」
  - 顯示學習進度（已學習 X / 總數 Y）
- **測試方法**：
  - 確認滑動手勢流暢
  - 驗證翻轉動畫正確
  - 確認標記功能儲存成功
  - 驗證進度計算準確

---

## <span id="section5">使用者介面分析 (User Interface Analysis)</span>

### 主要介面流程圖

```
登入頁面 (Firebase Auth)
    ↓
Project 列表頁面 ←→ 新增 Project 對話框
    ↓
Project 詳情頁面 ←→ 文件上傳頁面
    ↓                    ↓
內容類型選擇頁面    處理狀態頁面
    ↓
┌───┬───┬───┬───┐
│筆記│選擇│問答│學習│
│閱讀│題  │題  │卡  │
└───┴───┴───┴───┘
```

### 核心介面設計說明

#### 1. 登入/註冊頁面
**設計要點：**
- 簡潔的單頁設計，可切換登入/註冊模式
- Email 與密碼輸入框，支援顯示/隱藏密碼
- 明顯的「登入」或「註冊」按鈕
- Google Sign-In 按鈕
- 錯誤訊息在輸入框下方紅字提示
- 使用 Firebase Authentication 處理所有認證邏輯

**關鍵元素：**
- Ghote Logo 與 App 名稱
- Email 輸入框（含驗證）
- 密碼輸入框（含強度提示）
- 登入/註冊切換按鈕
- Google Sign-In 按鈕
- 主要操作按鈕

**已實作功能（參考 login_screen.dart）：**
- Email/Password 登入與註冊
- Google Sign-In 整合
- 響應式設計
- 動畫效果
- 錯誤處理

#### 2. Project 列表頁面
**設計要點：**
- 頂部顯示用戶名稱與登出按鈕
- Project 以卡片形式顯示（顏色標籤、名稱、文件數量、最後更新時間）
- 右下角浮動按鈕「+ 新增 Project」
- 支援下拉重新整理
- 搜尋與篩選功能

**關鍵元素：**
- 搜尋欄
- Project 卡片列表
- 浮動新增按鈕
- 空狀態提示（無 Project 時）

**已實作功能（參考 dashboard_screen.dart）：**
- Project 卡片顯示
- 搜尋功能
- 篩選功能（All/Active/Completed/Archived）
- 統計資訊顯示
- 動畫效果

#### 3. Project 詳情頁面
**設計要點：**
- 頂部顯示 Project 名稱與設定選單（編輯/刪除）
- 文件列表顯示（檔名、上傳日期、處理狀態）
- 底部「下一題」按鈕

**關鍵元素：**
- 題號與進度條
- 題目文字
- 選項按鈕
- 答案回饋（正確/錯誤）
- 解析區域
- 導航按鈕

#### 4. 文件上傳頁面
**設計要點：**
- 大面積拖曳上傳區域
- 顯示支援的檔案格式（PDF, TXT, DOCX）
- 檔案大小限制提示（最大 10MB）
- 上傳進度條與百分比顯示
- 上傳成功後自動跳轉至處理狀態頁面

**關鍵元素：**
- 拖曳上傳區域
- 檔案選擇按鈕
- 進度指示器
- 錯誤提示訊息

#### 5. 處理狀態頁面
**設計要點：**
- 中央顯示動畫圖示（如旋轉的書本或 AI 圖標）
- 顯示「處理中...」文字與預估時間
- 處理完成後顯示成功訊息與「查看內容」按鈕
- 處理失敗顯示錯誤訊息與「重試」按鈕

**關鍵元素：**
- 動畫元件
- 狀態文字
- 進度指示（如果可取得）
- 操作按鈕

#### 6. 內容類型選擇頁面
**設計要點：**
- 四個大型卡片分別代表：重點筆記、選擇題、問答題、學習卡
- 每個卡片顯示圖示、名稱、數量
- 卡片支援點擊進入對應頁面
- 頂部顯示文件名稱

**關鍵元素：**
- 四種內容類型卡片
- 數量徽章
- 返回按鈕

#### 7. 筆記閱讀頁面
**設計要點：**
- 結構化顯示筆記（標題層級）
- 關鍵字以標籤形式顯示
- 重要度以顏色或圖示標示
- 支援展開/收合各段落
- 滾動閱讀

**關鍵元素：**
- 筆記標題
- 內容段落
- 關鍵字標籤
- 展開/收合控制

#### 8. 選擇題測驗頁面
**設計要點：**
- 頂部顯示題號與進度（如「1/20」）
- 題目文字清晰顯示
- 選項以卡片或按鈕形式呈現
- 選擇後顯示正確/錯誤回饋
- 顯示解析（可展開）
- 底部導航按鈕（上一題/下一題）

**關鍵元素：**
- 題號與進度條
- 題目文字
- 選項按鈕
- 答案回饋（正確/錯誤）
- 解析區域
- 導航按鈕

#### 9. 問答題頁面
**設計要點：**
- 顯示問題文字
- 顯示參考答案（可展開/收合）
- 標示關鍵字與難度
- 支援左右滑動切換題目
- 顯示題號與進度

**關鍵元素：**
- 問題文字
- 參考答案區域
- 關鍵字標籤
- 難度指示器
- 導航控制

#### 10. 學習卡頁面
**設計要點：**
- 大型卡片居中顯示
- 點擊卡片觸發翻轉動畫（3D 翻轉效果）
- 正面顯示問題，背面顯示答案
- 左右滑動切換卡片（滑動方向與學習進度對應）
- 底部顯示標記按鈕：「已掌握」、「需複習」、「困難」
- 頂部顯示進度（已學習 X / 總數 Y）

**關鍵元素：**
- 可翻轉的卡片元件
- 問題文字（正面）
- 答案文字（背面）
- 標記按鈕組
- 進度指示器
- 滑動手勢支援

---

## <span id="section6">功能需求 (Functional Requirements)</span>

### FR-1 用戶認證與授權

**FR-1.1** 系統應使用 Firebase Authentication 提供使用者 Email 和密碼進行註冊的功能。

**FR-1.2** 系統應驗證註冊時的 Email 格式，並要求密碼長度至少 8 個字元（由 Firebase 自動處理）。

**FR-1.3** 系統應提供使用者登入功能，並在驗證成功後由 Firebase 發放 ID Token。

**FR-1.4** 系統應支援 Google Sign-In 快速登入與註冊功能。

**FR-1.5** 系統應在 Firebase ID Token 過期後要求使用者重新登入或自動刷新 Token。

**FR-1.6** 系統應提供使用者登出功能，清除本地儲存的認證資訊與 Firebase Token。

**FR-1.7** 後端 API 應驗證每個請求的 Firebase ID Token，確保使用者身份合法。

**FR-1.8** 後端應在首次驗證 Firebase Token 後，自動在資料庫建立對應的使用者記錄。

### FR-2 Project 管理

**FR-2.1** 使用者可建立新的 Project，包含名稱（必填）與描述（選填）。

**FR-2.2** 使用者可查看所有自己建立的 Project 列表，顯示名稱、建立日期、文件數量。

**FR-2.3** 使用者可編輯 Project 的名稱與描述。

**FR-2.4** 使用者可刪除 Project，系統應在刪除前顯示確認對話框。

**FR-2.5** 刪除 Project 時，系統應同時刪除該 Project 下所有文件及相關學習內容。

**FR-2.6** 使用者可為 Project 設定顏色標籤，方便視覺區分。

**FR-2.7** 使用者可搜尋 Project，支援名稱模糊搜尋。

**FR-2.8** 使用者可對 Project 列表進行排序（依建立日期、名稱、最後更新時間）。

**FR-2.9** 使用者可篩選 Project 狀態（All/Active/Completed/Archived）。

### FR-3 文件上傳與管理

**FR-3.1** 使用者可在指定 Project 內上傳文件，支援格式包含 PDF、TXT、DOCX。

**FR-3.2** 系統應限制單個文件大小不超過 10MB。

**FR-3.3** 系統應在文件上傳過程中顯示即時進度。

**FR-3.4** 系統應在文件上傳成功後自動開始處理任務。

**FR-3.5** 使用者可查看文件處理狀態，包含：處理中、已完成、處理失敗。

**FR-3.6** 系統應在文件處理完成後發送通知給使用者。

**FR-3.7** 使用者可刪除已上傳的文件，系統應同時刪除該文件生成的所有學習內容。

**FR-3.8** 系統應儲存文件的元資料，包含檔名、上傳時間、文件大小、處理狀態。

**FR-3.9** 使用者可查看 Project 內所有文件的列表。

### FR-4 AI 內容生成

**FR-4.1** 系統應自動從上傳的文件中提取文本內容。

**FR-4.2** 系統應支援從 PDF、TXT、DOCX 格式文件中準確提取文本。

**FR-4.3** 系統應使用 Google Gemini API (Free Plan) 分析文件內容並生成重點筆記。

**FR-4.4** 生成的重點筆記應包含：標題、主要概念、詳細說明、重要性標記、關鍵字。

**FR-4.5** 系統應根據文件內容自動生成選擇題，包含題目、選項、正確答案、解析、難度。

**FR-4.6** 生成的選擇題應支援單選與多選題型。

**FR-4.7** 系統應根據文件內容生成開放式問答題，包含問題、參考答案、關鍵字、難度。

**FR-4.8** 系統應生成學習卡，包含問題（正面）、答案（背面）、標籤、難度。

**FR-4.9** 系統應為每種生成的內容類型分配唯一識別碼。

**FR-4.10** 系統應將所有生成的內容儲存至資料庫，並與對應文件關聯。

**FR-4.11** AI 生成過程應以非同步方式執行，避免阻塞使用者操作。

**FR-4.12** 系統應在 AI 生成失敗時記錄錯誤原因，並通知使用者。

**FR-4.13** 系統應優化 Gemini API 的 Token 使用量，保持在免費額度內（每天 100 萬 Tokens）。

### FR-5 重點筆記功能

**FR-5.1** 使用者可查看文件對應的重點筆記。

**FR-5.2** 系統應以結構化方式呈現筆記，包含標題層級與內容段落。

**FR-5.3** 系統應顯示筆記中的關鍵字標籤。

**FR-5.4** 系統應以視覺方式標示內容的重要性（高、中、低）。

**FR-5.5** 使用者可展開或收合筆記的各個段落。

**FR-5.6** 使用者可複製筆記內容。

### FR-6 選擇題測驗功能

**FR-6.1** 使用者可查看文件對應的選擇題列表。

**FR-6.2** 系統應顯示題號與總題數進度（如「1/20」）。

**FR-6.3** 使用者可選擇答案選項。

**FR-6.4** 系統應在使用者作答後立即顯示正確或錯誤的回饋。

**FR-6.5** 系統應在作答後顯示該題的詳細解析。

**FR-6.6** 使用者可切換至下一題或上一題。

**FR-6.7** 系統應標示題目的難度等級。

**FR-6.8** 系統應記錄使用者的作答結果（正確/錯誤）。

### FR-7 問答題功能

**FR-7.1** 使用者可查看文件對應的問答題列表。

**FR-7.2** 系統應清晰顯示問題文字。

**FR-7.3** 使用者可展開查看參考答案。

**FR-7.4** 系統應顯示該問題的關鍵字標籤。

**FR-7.5** 系統應標示題目的難度等級。

**FR-7.6** 使用者可切換至下一題或上一題。

### FR-8 學習卡學習功能

**FR-8.1** 使用者可查看文件對應的學習卡集合。

**FR-8.2** 系統應以卡片形式呈現內容，正面顯示問題，背面顯示答案。

**FR-8.3** 使用者可點擊卡片觸發翻轉動畫，查看另一面內容。

**FR-8.4** 使用者可透過左右滑動手勢切換至下一張或上一張卡片。

**FR-8.5** 使用者可將卡片標記為「已掌握」、「需複習」或「困難」。

**FR-8.6** 系統應記錄每張卡片的標記狀態。

**FR-8.7** 系統應顯示學習進度，包含已學習卡片數與總卡片數。

**FR-8.8** 系統應顯示卡片的標籤分類。

**FR-8.9** 使用者可篩選顯示特定標記狀態的卡片（如只顯示「需複習」的卡片）。

### FR-9 學習進度追蹤

**FR-9.1** 系統應記錄使用者對每個內容項目的學習狀態。

**FR-9.2** 系統應追蹤選擇題的作答正確率。

**FR-9.3** 系統應統計學習卡的學習進度（已掌握/需複習/困難的比例）。

**FR-9.4** 使用者可在 Project 詳情頁面查看整體學習進度。

**FR-9.5** 系統應記錄每個內容項目的最後查看時間。

### FR-10 內容查詢與篩選

**FR-10.1** 使用者可查詢特定文件生成的所有內容類型。

**FR-10.2** 系統應提供內容類型選擇介面，顯示四種類型及其數量。

**FR-10.3** 使用者可依難度篩選題目（簡單/中等/困難）。

**FR-10.4** 使用者可依標籤篩選內容。

**FR-10.5** 系統應支援跨文件的內容搜尋（在同一 Project 內）。

### FR-11 資料同步與快取

**FR-11.1** 系統應在網路可用時自動同步使用者資料至雲端。

**FR-11.2** 系統應在本地快取已下載的內容，支援離線查閱。

**FR-11.3** 系統應在網路恢復時自動上傳本地的學習進度記錄。

**FR-11.4** 使用者可手動觸發資料同步。

---

## <span id="section7">非功能需求 (Non-functional Requirements)</span>

### NFR-1 效能需求

**NFR-1.1** 文件上傳介面應在 **2 秒內** 完成載入並顯示上傳區域。

**NFR-1.2** 10MB 以內的文件上傳應在 **10 秒內** 完成（在標準 4G 網路環境下）。

**NFR-1.3** 文件處理（文本提取 + AI 生成）應在 **60 秒內** 完成（針對 10 頁以內的 PDF 文件）。

**NFR-1.4** API 查詢請求（如獲取筆記、選擇題）應在 **3 秒內** 返回結果。

**NFR-1.5** App 首頁（Project 列表）應在 **1.5 秒內** 完成渲染。

**NFR-1.6** 學習卡翻轉動畫應保持 **60 FPS** 的流暢度。

**NFR-1.7** 選擇題作答後的回饋應在 **500 毫秒內** 顯示。

**NFR-1.8** 處理狀態輪詢間隔為 **5 秒**，確保使用者能即時獲知處理進度。

**NFR-1.9** 系統應支援同時處理至少 **10 個** 文件上傳任務（Firebase Storage 並發數）。

**NFR-1.10** 資料庫查詢（如獲取 Project 列表）應在 **1 秒內** 完成（Firestore 索引優化）。

### NFR-2 可用性需求

**NFR-2.1** App 介面應支援繁體中文與英文兩種語言（優先支援繁體中文）。

**NFR-2.2** 所有按鈕與可點擊元素的最小觸控區域應為 **44x44 像素**（符合 Apple HIG 標準）。

**NFR-2.3** 錯誤訊息應以清晰、易懂的語言呈現，避免技術術語。

**NFR-2.4** 關鍵操作（如刪除 Project、刪除文件）應有確認對話框，防止誤操作。

**NFR-2.5** 系統應在網路斷線時顯示友善提示，並提供重試選項。

**NFR-2.6** 載入過程應有明確的進度指示（如進度條、動畫）。

**NFR-2.7** App 應支援深色模式與淺色模式，依據系統設定自動切換。

**NFR-2.8** 系統應在執行 AI 生成時顯示明確的載入動畫。

### NFR-3 可靠性需求

**NFR-3.1** 系統應保證 **99.9%** 的月度可用性（Firebase SLA）。

**NFR-3.2** 文件上傳失敗時，系統應提供自動重試機制（最多重試 3 次）。

**NFR-3.3** AI 生成任務失敗時，系統應記錄錯誤日誌並通知使用者。

**NFR-3.4** 資料庫應每日自動備份（Firestore 自動備份）。

**NFR-3.5** 系統應在偵測到異常流量或錯誤率上升時自動發送警報。

### NFR-4 安全性需求

**NFR-4.1** 使用者密碼由 Firebase Authentication 管理，自動使用安全的雜湊演算法儲存。

**NFR-4.2** API 通訊必須使用 **HTTPS** 加密。

**NFR-4.3** Firebase ID Token 有效期為 **1 小時**，過期後需刷新或重新登入。

**NFR-4.4** 系統應實施 API 呼叫頻率限制，防止濫用（如每分鐘最多 60 次請求）。

**NFR-4.5** 上傳的文件應掃描惡意內容，拒絕可疑檔案。

**NFR-4.6** 使用者只能存取自己建立的 Project 與文件，系統應透過 Firebase UID 實施嚴格的權限控制。

**NFR-4.7** 敏感操作（如刪除帳號）應要求二次驗證。

**NFR-4.8** 後端必須驗證每個請求的 Firebase Token，不得信任前端傳來的使用者資訊。

**NFR-4.9** Firebase Storage 的存取應設定 Security Rules，僅允許授權使用者存取自己的檔案。

### NFR-5 可維護性需求

**NFR-5.1** 程式碼應遵循團隊制定的編碼規範（如 PEP 8 for Python、Effective Dart for Flutter）。

**NFR-5.2** 所有 API 應提供完整的 Swagger/OpenAPI 文件。

**NFR-5.3** 關鍵業務邏輯應有單元測試覆蓋，測試覆蓋率應達 **70% 以上**。

**NFR-5.4** 系統應實施結構化日誌記錄，包含錯誤追蹤與效能監控。

**NFR-5.5** 資料庫 Schema 變更應使用遷移工具（如 Alembic），確保版本可追蹤。

**NFR-5.6** 程式碼審查（Code Review）應在合併至主分支前完成，使用 GitHub Actions 自動檢查。

### NFR-6 可擴展性需求

**NFR-6.1** 系統架構應支援水平擴展，Cloud Firestore 與 Firebase Functions (未來) 可自動處理流量增長。

**NFR-6.2** 客戶端 AI 處理應能利用裝置算力，減輕伺服器負擔。

**NFR-6.3** Firestore 支援自動擴展，無需手動管理伺服器資源。

**NFR-6.4** 系統應設計為微服務架構，便於未來模組化擴展（如新增語音辨識功能）。

### NFR-7 相容性需求

**NFR-7.1** Flutter App 應支援 **iOS 15.0** 及以上版本（配合 Firebase Auth 要求）。

**NFR-7.2** Flutter App 應支援 **Android 8.0 (API Level 26)** 及以上版本。

**NFR-7.3** 後端 API 應與主流 HTTP 客戶端相容（如 Dio、Axios、Postman）。

**NFR-7.4** 系統應支援主流瀏覽器（Chrome、Safari、Firefox、Edge）進行管理後台操作（未來功能）。

### NFR-8 可攜性需求

**NFR-8.1** App 應使用 Flutter 跨平台框架，確保 iOS 與 Android 版本功能一致。

**NFR-8.2** 後端服務使用 Firebase Serverless 架構，無需管理容器或伺服器。

**NFR-8.3** 系統應避免平台特定依賴，優先使用跨平台函式庫。

### NFR-9 資料需求

**NFR-9.1** 使用者上傳的文件應儲存於 Firebase Storage，保留期限為 **1 年**。

**NFR-9.2** AI 生成的內容應永久保存於 Cloud Firestore，除非使用者主動刪除。

**NFR-9.3** 使用者學習進度記錄應保留最近 **6 個月** 的歷史資料。

**NFR-9.4** 系統應符合 GDPR 與台灣個資法規範，使用者有權要求刪除所有個人資料。

**NFR-9.5** 刪除的資料應進行軟刪除（標記為已刪除但保留 30 天），以便誤刪後恢復。

### NFR-10 成本需求

**NFR-10.1** Google Gemini API 應使用 Free Plan，單次生成 Token 使用量應優化以保持在免費額度內（每天 100 萬 Tokens）。

**NFR-10.2** Firebase Storage 儲存空間應控制在 **5GB 免費額度**內（MVP 階段）。

**NFR-10.3** Cloud Firestore 讀寫次數應優化，避免頻繁無效讀取（免費額度：5萬次讀取/天）。

**NFR-10.5** Firebase Authentication 完全免費，無使用量限制。

**NFR-10.6** GitHub Actions CI/CD 應控制在每月 **2000 分鐘免費額度**內。

**NFR-10.7** 系統應實施資源監控，當接近免費額度上限時發送警報。

**NFR-10.8** MVP 階段總成本目標：**$0/月**（完全使用免費服務）。

---

## 附錄

### 附錄 A：AI 生成內容 JSON Schema 範例

#### 重點筆記格式
```json
{
  "summary": {
    "id": "summary_001",
    "title": "資料結構 - 陣列與鏈結串列",
    "key_points": [
      {
        "heading": "陣列的特性",
        "content": "陣列是連續記憶體空間，存取速度快但插入刪除效率低。",
        "importance": "high"
      },
      {
        "heading": "鏈結串列的優勢",
        "content": "鏈結串列使用指標連接節點，插入刪除效率高但存取速度較慢。",
        "importance": "medium"
      }
    ],
    "keywords": ["陣列", "鏈結串列", "時間複雜度", "空間複雜度"]
  }
}
```

#### 選擇題格式
```json
{
  "multiple_choice": [
    {
      "id": "mcq_001",
      "question": "陣列的時間複雜度為何？",
      "options": [
        "A. 存取 O(1), 插入 O(n)",
        "B. 存取 O(n), 插入 O(1)",
        "C. 存取 O(log n), 插入 O(n)",
        "D. 存取 O(1), 插入 O(1)"
      ],
      "correct_answer": "A",
      "explanation": "陣列使用索引直接存取元素，時間複雜度為 O(1)。但插入元素需移動後續元素，時間複雜度為 O(n)。",
      "difficulty": "medium"
    }
  ]
}
```

#### 問答題格式
```json
{
  "qa_questions": [
    {
      "id": "qa_001",
      "question": "請說明陣列與鏈結串列在記憶體配置上的差異",
      "answer": "陣列使用連續的記憶體空間儲存元素，記憶體位址是連續的。鏈結串列的節點分散在記憶體中，透過指標連接各節點。",
      "keywords": ["連續記憶體", "指標", "記憶體配置"],
      "difficulty": "hard"
    }
  ]
}
```

#### 學習卡格式
```json
{
  "flashcards": [
    {
      "id": "card_001",
      "front": "什麼是陣列？",
      "back": "陣列是一種線性資料結構，使用連續記憶體空間儲存相同類型的元素，可透過索引快速存取。",
      "tags": ["資料結構", "陣列"],
      "difficulty": "easy"
    }
  ]
}
```

### 附錄 B：資料存取模式 (Data Access Patterns)

由於採用 Serverless 架構，前端直接透過 Firebase SDK 操作 Firestore 與 Storage，無傳統 REST API 端點。

#### 認證 (Auth)
- `FirebaseAuth.instance.signInWithEmailAndPassword`
- `FirebaseAuth.instance.signInWithCredential` (Google)

#### Project 管理 (Firestore: `projects` collection)
- **Create**: `projects.add({...})`
- **Read List**: `projects.where('ownerId', isEqualTo: uid).snapshots()`
- **Read Detail**: `projects.doc(projectId).get()`
- **Update**: `projects.doc(projectId).update({...})`
- **Delete**: `projects.doc(projectId).delete()`

#### 文件管理 (Storage & Firestore)
- **Upload**: `storage.ref().putFile(file)`
- **Save Metadata**: `projects/{id}/files.add({...})`
- **Read Files**: `projects/{id}/files.snapshots()`

#### 內容查詢 (Firestore Sub-collections)
- **Summaries**: `projects/{id}/files/{fileId}/summary.get()`
- **Flashcards**: `projects/{id}/flashcards.where('fileId', isEqualTo: fileId).snapshots()`
- **Questions**: `projects/{id}/questions.where('fileId', isEqualTo: fileId).snapshots()`

### 附錄 C：資料庫 Schema 設計

#### Users 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| firebase_uid | VARCHAR(255) | Firebase User ID（唯一） |
| email | VARCHAR(255) | Email（唯一） |
| display_name | VARCHAR(255) | 顯示名稱（選填） |
| created_at | TIMESTAMP | 建立時間 |
| updated_at | TIMESTAMP | 更新時間 |

> 註：不再儲存密碼，認證完全由 Firebase 處理

#### Projects 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| user_id | UUID | 外鍵（Users） |
| name | VARCHAR(255) | Project 名稱 |
| description | TEXT | 描述 |
| color | VARCHAR(50) | 顏色標籤 |
| status | VARCHAR(50) | 狀態（Active/Completed/Archived） |
| created_at | TIMESTAMP | 建立時間 |
| updated_at | TIMESTAMP | 更新時間 |

#### Files 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| project_id | UUID | 外鍵（Projects） |
| filename | VARCHAR(255) | 檔案名稱 |
| file_size | INTEGER | 檔案大小（bytes） |
| file_type | VARCHAR(50) | 檔案類型 |
| storage_path | VARCHAR(500) | Firebase Storage Path |
| processing_status | ENUM | 處理狀態（pending/processing/completed/failed） |
| created_at | TIMESTAMP | 上傳時間 |
| processed_at | TIMESTAMP | 處理完成時間 |

#### Summaries 表（重點筆記）
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| file_id | UUID | 外鍵（Files） |
| content | JSONB | 筆記內容（JSON 格式） |
| created_at | TIMESTAMP | 生成時間 |

#### MultipleChoiceQuestions 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| file_id | UUID | 外鍵（Files） |
| content | JSONB | 題目內容（JSON 格式） |
| created_at | TIMESTAMP | 生成時間 |

#### QAQuestions 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| file_id | UUID | 外鍵（Files） |
| content | JSONB | 題目內容（JSON 格式） |
| created_at | TIMESTAMP | 生成時間 |

#### Flashcards 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| file_id | UUID | 外鍵（Files） |
| content | JSONB | 卡片內容（JSON 格式） |
| created_at | TIMESTAMP | 生成時間 |

#### LearningProgress 表
| 欄位 | 類型 | 說明 |
|------|------|------|
| id | UUID | 主鍵 |
| user_id | UUID | 外鍵（Users） |
| content_id | UUID | 內容 ID |
| content_type | VARCHAR(50) | 內容類型（summary/mcq/qa/flashcard） |
| status | VARCHAR(50) | 學習狀態（mastered/review/difficult） |
| last_reviewed | TIMESTAMP | 最後查看時間 |
| created_at | TIMESTAMP | 建立時間 |

### 附錄 D：外部連結

- **GitHub Repository**: [ghote-app/ghote](https://github.com/ghote-app/ghote)
- **Trello 專案管理看板**: [https://trello.com/b/YWoNO5Jg](https://trello.com/b/YWoNO5Jg)
- **User Story 詳細文件**: [Canva 連結](https://www.canva.com/design/DAG0DmFIRyE/mRCSVnJYGzAE0dW_Eszg6Q/edit?utm_content=DAG0DmFIRyE&utm_campaign=designshare&utm_medium=link2&utm_source=sharebutton)
- **User Story Map**: [Miro Board](https://miro.com/app/board/uXjVJ_OWob0=/?share_link_id=609063714267)
- **Firebase Console**: [ghote-app 專案](https://console.firebase.google.com/project/ghote-app)

### 附錄 E：開發環境設定

#### 前端開發環境（Flutter）
```bash
# 需求
- Flutter SDK 3.16+ (建議使用 FVM 管理版本)
- Android Studio (Android 開發)
- Xcode (iOS 開發，僅 macOS)
- VS Code / Android Studio

# 安裝依賴
flutter pub get

# 運行
flutter run

# 建置
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

#### 後端開發環境（Firebase）
無需本地 Python 環境，僅需安裝 Firebase CLI。

```bash
# 安裝 Firebase CLI
npm install -g firebase-tools

# 登入
firebase login

# 初始化 (如果需要修改 Firestore Rules 或 Functions)
firebase init
```

### 附錄 F：技術棧版本資訊

#### 前端依賴版本
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  google_sign_in: ^6.2.2
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  dio: ^5.7.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  google_fonts: ^6.2.1
  video_player: ^2.9.2
```

#### 後端依賴版本
無 (Serverless 架構)

### 附錄 G：部署檢查清單

#### Firebase 部署前檢查
- [x] 確認 `firebase_options.dart` 為最新
- [x] Firestore Rules 已設定且安全
- [x] Storage Rules 已設定且安全
- [x] Android/iOS App ID 配置正確
- [x] Google Sign-In SHA-1 指紋已新增至 Firebase Console

#### Firebase 設定
- [x] 啟用 Email/Password 認證
- [x] 啟用 Google Sign-In
- [x] 下載 Service Account Key
- [x] 配置 OAuth 同意畫面
- [x] 設定安全規則

#### GitHub Actions 設定
- [x] 配置 CI workflow
- [ ] 設定必要的 Secrets
- [x] 測試自動建置
- [x] 設定分支保護規則
- [x] 配置自動部署

### 附錄 H：成本監控與警告

#### 免費額度監控

**Gemini API (每日)**
- 閾值：800K tokens/day (80% of 1M)
- 警告機制：達到 80% 時發送通知
- 行動：優化 Prompt 或暫停新請求

**Cloud Firestore (每日)**
- 讀取：50,000 次 (免費額度)
- 寫入：20,000 次 (免費額度)
- 刪除：20,000 次 (免費額度)
- 警告機制：接近 80% 時發送通知

**Firebase Storage (總量)**
- 儲存：5 GB
- 下載頻寬：1 GB/天
- 警告機制：接近 80% 時發送通知

**GitHub Actions (每月)**
- 使用分鐘：1600 分鐘 (80% of 2000)
- 警告機制：每週檢查使用量
- 行動：優化 CI workflow

#### 升級路徑（當超過免費額度時）

**優先升級順序：**
1. **Firebase Blaze Plan** (Pay as you go)
   - 當 Firestore 讀寫或 Storage 用量超過免費額度時啟用。
2. **Gemini API** → 付費方案（$7/100萬 tokens）

**預估成本（500-1000 使用者）：**
- Firebase: ~$5-10/month (視流量而定)
- Gemini: ~$10/month
- **總計：~$15-20/month**

---

## 專案當前狀態

### 已完成功能（參考 GitHub）

**前端 (Flutter):**
- Firebase Authentication 整合
- Google Sign-In
- 登入/註冊頁面 UI
- Dashboard 頁面 UI
- Splash Screen 動畫
- 響應式設計
- 深色主題
- Project 列表顯示（假資料）
- 搜尋與篩選功能
- GitHub Actions CI/CD

**後端:**
- ⏳ 待開發（依照本文件規劃）

### 🚧 開發中功能

**前端:**
- 🔄 Project 詳情頁面
- 🔄 文件上傳頁面
- 🔄 API 整合

**後端:**
- 🔄 Firebase 專案設定
- 🔄 Firebase Token 驗證
- 🔄 Project CRUD API

### 📋 待開發功能

**優先級 P0 (MVP 必須):**
- [ ] 後端 API 基礎建設
- [ ] Project CRUD 完整功能
- [ ] 文件上傳與儲存
- [ ] AI 內容生成（四種類型）
- [ ] 內容查詢 API

**優先級 P1 (重要但非必須):**
- [ ] 學習進度追蹤
- [ ] 內容編輯功能
- [ ] 進階搜尋與篩選

**優先級 P2 (未來功能):**
- [ ] 內容匯出（PDF/DOCX）
- [ ] 協作功能
- [ ] 語音辨識

---

## 下一步行動計畫

### Week 1-2: 基礎建設與認證
1. 建立 Firebase 專案
2. 設定 Firestore 資料庫與 Security Rules
3. 整合 Firebase Auth (Email/Google)
4. 前端登入/註冊頁面實作

### Week 3-4: 專案與文件管理
1. 實作 Project CRUD (Firestore)
2. 設定 Firebase Storage
3. 實作文件上傳與本地文字提取 (PDF/Docx)
4. 整合 Dashboard 與 Project 詳情頁

### Week 5-6: AI 內容生成
1. 申請 Gemini API Key
2. 實作 `GeminiService` (Client-side)
3. 設計 Prompt 模板 (JSON Mode)
4. 實作四種內容生成與 Firestore 儲存

### Week 7-8: 學習介面與優化
1. 實作學習卡、測驗、聊天介面
2. 整合學習進度追蹤
3. UI/UX 優化與錯誤處理
4. 全面測試與部署

---

**文件結束**

> **版本資訊**: v1.4 - 2026/01/04
> 
> 本文件會隨專案進展持續更新，請定期檢查最新版本。部「上傳文件」按鈕
- 每個文件卡片顯示四種內容類型的數量

**關鍵元素：**
- Project 資訊區
- 文件列表（可點擊進入內容）
- 上傳按鈕
- 空狀態提示（無文件時）

