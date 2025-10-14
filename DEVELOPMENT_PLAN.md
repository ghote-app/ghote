# Ghote App - Container/專案功能開發規劃

## 專案概述
建立一個靈活的「Container」或「專案」功能，讓使用者可以上傳、管理並分析自己的學習材料，是 Ghote App 進化的核心功能。

### 💎 付費機制設計

#### 免費用戶（Ghote Free）
- ✅ 檔案只能儲存在**本地端**（裝置儲存空間）
- ✅ 建立最多 **3 個專案**
- ✅ 每個專案最多 **10 個檔案**
- ✅ 基本 AI 分析功能（每月 50 次）
- ✅ 檔案總大小限制：**500MB**
- ⚠️ 換裝置後檔案**不會同步**

#### 付費用戶（Ghote Pro）
- 🌟 檔案儲存在 **Cloudflare R2 雲端**
- 🌟 **無限專案數量**
- 🌟 每個專案**無限檔案數量**
- 🌟 進階 AI 分析功能（每月 500 次）
- 🌟 檔案總儲存空間：**10GB**
- 🌟 **跨裝置同步**
- 🌟 檔案**協作與共享功能**
- 🌟 **優先客服支援**

#### 價格方案
- **月付**：NT$ 149/月
- **年付**：NT$ 1,490/年（省 17%）

---

## 開發策略：分步進行

### 步驟 0：建立訂閱管理系統 🆕
**目標**：實作付費訂閱和權限控制

#### A. 訂閱狀態模型
```dart
// lib/models/subscription.dart
class Subscription {
  final String userId;
  final String plan; // 'free' or 'pro'
  final DateTime? proStartDate;
  final DateTime? proEndDate;
  final bool isActive;
  final String? paymentProvider; // 'stripe', 'google_play', 'app_store'
  
  bool get isPro => plan == 'pro' && isActive;
  bool get isFree => !isPro;
}
```

#### B. 權限管理服務
```dart
// lib/services/subscription_service.dart
class SubscriptionService {
  // 檢查用戶訂閱狀態
  Future<Subscription> getUserSubscription(String userId);
  
  // 驗證用戶是否可以執行某項操作
  bool canUploadToCloud(Subscription sub) => sub.isPro;
  bool canCreateProject(int currentCount, Subscription sub) {
    return sub.isPro || currentCount < 3;
  }
  bool canAddFile(int currentCount, Subscription sub) {
    return sub.isPro || currentCount < 10;
  }
  
  // 升級到 Pro
  Future<void> upgradeToPro(String userId, String paymentToken);
}
```

#### 實作任務：
- [ ] 建立 `lib/models/subscription.dart` 訂閱模型
- [ ] 建立 `lib/services/subscription_service.dart` 訂閱服務
- [ ] 在 Firestore 建立 `users/{userId}/subscription` 集合
- [ ] 整合支付系統（Stripe / Google Play / App Store）
- [ ] 建立訂閱管理 UI 頁面
- [ ] 實作權限檢查中介層

---

### 步驟 1：建立資料模型與雲端資料庫 (Data Model & Firestore)
**目標**：建立穩固的資料結構基礎

#### A. 資料模型設計

**Project 模型**：
- `id`: 專案的唯一 ID
- `title`: 專案標題 (例如: "機器學習期末考")
- `description`: 專案描述
- `ownerId`: 建立者的 Firebase User ID
- `collaboratorIds`: 協作者的 User ID 列表（**僅 Pro 用戶可用**）
- `createdAt`: 建立時間
- `lastUpdatedAt`: 最後更新時間
- `status`: 專案狀態 ('Active', 'Completed', 'Archived')
- `category`: 專案分類

**File 模型**：
- `id`: 檔案的唯一 ID
- `projectId`: 所屬專案 ID
- `name`: 檔案名稱
- `type`: 檔案類型 ('pdf', 'png', 'txt', 'docx')
- `sizeBytes`: 檔案大小
- **`storageType`**: **'local' 或 'cloud'** 🆕
- `localPath`: 本地端路徑（免費用戶）🆕
- `cloudPath`: Cloudflare R2 路徑（Pro 用戶）🆕
- `downloadUrl`: 雲端下載連結（Pro 用戶）🆕
- `uploaderId`: 上傳者的 User ID
- `uploadedAt`: 上傳時間
- `metadata`: 額外資訊（頁數、解析度等）

#### B. Firestore 資料結構
```
/users/{userId}/
  - subscription: {...} <-- 訂閱資訊
  
/projects/{projectId}/ <-- 專案集合
  - title: "機器學習期末考"
  - ownerId: "user_abc"
  - collaboratorIds: ["user_xyz"] // 僅 Pro 可用
  - status: "Active"
  - category: "Education"
  - ...
  
  /files/{fileId}/ <-- 檔案子集合
    - name: "lecture_01.pdf"
    - type: "pdf"
    - storageType: "cloud" // 或 "local"
    - cloudPath: "/files/user_abc/project_123/lecture_01.pdf"
    - downloadUrl: "https://r2.cloudflarestorage.com/..."
    - ...
```

#### 實作任務：
- [ ] 建立 `lib/models/project.dart` 模型檔案
- [ ] 建立 `lib/models/file_model.dart` 模型檔案（更新為雙儲存系統）
- [ ] 在 Firebase 控制台啟用 Cloud Firestore 資料庫
- [ ] 設定 Firestore 安全規則（含訂閱權限檢查）

---

### 步驟 2：實現檔案選擇功能 (File Picking)
**目標**：讓使用者可以從手機中選擇檔案

#### A. 加入依賴套件
在 `pubspec.yaml` 中加入：
```yaml
dependencies:
  file_picker: ^8.0.0
  path_provider: ^2.1.0  # 用於本地端儲存
```

#### B. 建立檔案選擇功能（含權限檢查）
```dart
// 範例程式碼
Future<void> pickAndUploadFiles() async {
  // 1. 檢查用戶訂閱狀態
  final subscription = await SubscriptionService().getUserSubscription(userId);
  
  // 2. 檢查檔案數量限制
  final currentFileCount = await getProjectFileCount(projectId);
  if (!subscription.isPro && currentFileCount >= 10) {
    showUpgradeDialog('檔案數量已達上限，升級到 Pro 享受無限檔案！');
    return;
  }
  
  // 3. 選擇檔案
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.custom,
    allowedExtensions: ['jpg', 'pdf', 'doc', 'docx', 'png', 'txt'],
  );
  
  if (result != null) {
    // 4. 根據訂閱狀態決定儲存方式
    if (subscription.isPro) {
      await uploadToCloudflare(result.files);
    } else {
      await saveToLocal(result.files);
    }
  }
}
```

#### 實作任務：
- [ ] 更新 `pubspec.yaml` 加入所需套件
- [ ] 執行 `flutter pub get`
- [ ] 在 `dashboard_screen.dart` 加入檔案選擇按鈕
- [ ] 實作檔案選擇邏輯（含訂閱狀態檢查）
- [ ] 實作檔案大小檢查（免費用戶 500MB 限制）
- [ ] 建立升級提示 Dialog

---

### 步驟 3：實現雙儲存系統 (Local + Cloudflare R2) 🆕
**目標**：根據用戶訂閱狀態，儲存到本地或雲端

#### A. 加入依賴套件
```yaml
dependencies:
  http: ^1.2.1  # 用於 API 請求
```

#### B. 建立儲存服務
```dart
// lib/services/storage_service.dart
class StorageService {
  // 免費用戶：儲存到本地端
  Future<String> saveToLocal(File file, String projectId) async {
    final directory = await getApplicationDocumentsDirectory();
    final localPath = '${directory.path}/ghote/$projectId/${file.path.split('/').last}';
    await file.copy(localPath);
    return localPath;
  }
  
  // Pro 用戶：上傳到 Cloudflare R2
  Future<Map<String, String>> uploadToCloudflare(
    File file,
    String projectId,
    String userId,
  ) async {
    // 1. 向後端 API 請求預簽名 URL
    final response = await http.post(
      Uri.parse('https://your-api.render.com/api/upload/presigned-url'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await getFirebaseToken()}',
      },
      body: jsonEncode({
        'fileName': file.path.split('/').last,
        'projectId': projectId,
        'userId': userId,
      }),
    );
    
    final data = jsonDecode(response.body);
    final presignedUrl = data['uploadUrl'];
    final cloudPath = data['path'];
    
    // 2. 上傳到 Cloudflare R2
    await http.put(
      Uri.parse(presignedUrl),
      body: await file.readAsBytes(),
    );
    
    return {
      'cloudPath': cloudPath,
      'downloadUrl': data['downloadUrl'],
    };
  }
  
  // 讀取檔案（自動判斷來源）
  Future<Uint8List> getFileContent(FileModel file) async {
    if (file.storageType == 'local') {
      return await File(file.localPath!).readAsBytes();
    } else {
      final response = await http.get(Uri.parse(file.downloadUrl!));
      return response.bodyBytes;
    }
  }
}
```

#### 實作任務：
- [ ] 建立 `lib/services/storage_service.dart`
- [ ] 實作本地端儲存邏輯
- [ ] 實作 Cloudflare R2 上傳邏輯（透過後端 API）
- [ ] 建立後端 API endpoint (`/api/upload/presigned-url`)
- [ ] 實作檔案讀取邏輯（自動判斷來源）
- [ ] 加入上傳進度顯示

---

### 步驟 4：在 App 中顯示並預覽檔案
**目標**：讓使用者可以看到專案中的檔案並能預覽

#### A. 顯示檔案列表（含儲存位置標示）
```dart
// 檔案列表項目顯示儲存位置
Widget buildFileListItem(FileModel file) {
  return ListTile(
    leading: Icon(getFileIcon(file.type)),
    title: Text(file.name),
    subtitle: Row(
      children: [
        Icon(
          file.storageType == 'cloud' 
            ? Icons.cloud_done 
            : Icons.phone_android,
          size: 14,
        ),
        SizedBox(width: 4),
        Text(file.storageType == 'cloud' ? '雲端' : '本機'),
        SizedBox(width: 8),
        Text(file.formattedSize),
      ],
    ),
    trailing: IconButton(
      icon: Icon(Icons.more_vert),
      onPressed: () => showFileOptions(file),
    ),
  );
}
```

#### B. 檔案預覽功能
根據檔案類型和儲存位置實作預覽：
- **本地端檔案**：直接讀取並顯示
- **雲端檔案**：透過 downloadUrl 載入

#### 實作任務：
- [ ] 建立 `ProjectDetailsScreen` Widget
- [ ] 實作從 Firestore 讀取檔案列表
- [ ] 建立檔案列表 UI（顯示儲存位置標示）
- [ ] 加入 `flutter_pdfview` 套件處理 PDF
- [ ] 加入 `url_launcher` 套件處理其他檔案
- [ ] 實作各種檔案類型的預覽功能
- [ ] 加入檔案下載功能（Pro 用戶）

---

### 步驟 5：實現協作與共享功能（僅 Pro 用戶）🆕
**目標**：讓 Pro 用戶可以與他人共享專案和檔案

#### A. Firestore 安全規則（含訂閱檢查）
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isPro(userId) {
      let sub = get(/databases/$(database)/documents/users/$(userId)/subscription);
      return sub.data.plan == 'pro' && sub.data.isActive == true;
    }
    
    function isProjectMember(projectId) {
      let project = get(/databases/$(database)/documents/projects/$(projectId));
      return request.auth.uid == project.data.ownerId ||
             request.auth.uid in project.data.collaboratorIds;
    }
    
    match /projects/{projectId} {
      allow create: if isSignedIn();
      allow read: if isProjectMember(projectId);
      allow update, delete: if request.auth.uid == resource.data.ownerId;
      
      // 只有 Pro 用戶可以新增協作者
      allow update: if isPro(request.auth.uid) && 
                       request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['collaboratorIds', 'lastUpdatedAt']);
      
      match /files/{fileId} {
        allow read, create: if isProjectMember(projectId);
        allow delete: if request.auth.uid == resource.data.uploaderId ||
                         request.auth.uid == get(/databases/$(database)/documents/projects/$(projectId)).data.ownerId;
      }
    }
  }
}
```

#### B. 協作 UI
- 顯示「升級到 Pro 解鎖協作功能」的提示（免費用戶）
- Pro 用戶可以邀請協作者（透過 Email）

#### 實作任務：
- [ ] 設定 Firestore 安全規則（含訂閱檢查）
- [ ] 在 `ProjectDetailsScreen` 加入協作者管理按鈕
- [ ] 建立邀請協作者的 UI（僅 Pro 可見）
- [ ] 實作根據 Email 邀請協作者的邏輯
- [ ] 免費用戶點擊時顯示升級提示
- [ ] 實作協作者權限管理（唯讀 vs 編輯）

---

### 步驟 6：整合 AI 分析功能
**目標**：將現有的 AI 功能與新的檔案選擇系統結合

#### A. AI 分析限制
- **免費用戶**：每月 50 次
- **Pro 用戶**：每月 500 次

#### 實作任務：
- [ ] 在檔案列表中加入多選功能 (Checkbox)
- [ ] 建立「分析選取檔案」按鈕
- [ ] 實作 AI 使用次數檢查
- [ ] 實作獲取檔案內容的邏輯（本地 + 雲端）
- [ ] 整合現有的 AI 分析服務
- [ ] 實作 AI 分析結果的顯示
- [ ] 超過限制時顯示升級提示

---

### 步驟 7：本地端資料遷移功能 🆕
**目標**：免費用戶升級到 Pro 時，自動將本地檔案遷移到雲端

#### 實作邏輯
```dart
// lib/services/migration_service.dart
class MigrationService {
  Future<void> migrateLocalFilesToCloud(String userId) async {
    // 1. 獲取所有本地檔案
    final localFiles = await getLocalFiles(userId);
    
    // 2. 顯示進度對話框
    showMigrationProgress(localFiles.length);
    
    // 3. 逐一上傳到 Cloudflare R2
    for (var file in localFiles) {
      await uploadToCloudflare(file);
      await updateFileMetadata(file.id, storageType: 'cloud');
      updateProgress();
    }
    
    // 4. 完成後清理本地檔案（可選）
    await cleanupLocalFiles();
  }
}
```

#### 實作任務：
- [ ] 建立 `lib/services/migration_service.dart`
- [ ] 實作本地檔案掃描功能
- [ ] 實作批次上傳邏輯
- [ ] 建立遷移進度 UI
- [ ] 實作失敗重試機制
- [ ] 升級完成後自動觸發遷移

---

## 技術架構

### 新增的依賴套件
```yaml
dependencies:
  file_picker: ^8.0.0
  path_provider: ^2.1.0  # 本地端儲存
  http: ^1.2.1
  flutter_pdfview: ^1.3.2
  url_launcher: ^6.2.5
  
  # 支付系統（擇一）
  in_app_purchase: ^3.1.13  # iOS/Android 內購
  # 或
  stripe_flutter: ^9.4.0  # Stripe 支付
```

### 新增的檔案結構
```
lib/
├── models/
│   ├── project.dart
│   ├── file_model.dart
│   └── subscription.dart  🆕
├── services/
│   ├── storage_service.dart （雙儲存系統）
│   ├── subscription_service.dart  🆕
│   ├── migration_service.dart  🆕
│   └── project_service.dart
├── screens/
│   ├── project_details_screen.dart
│   ├── file_preview_screen.dart
│   ├── subscription_screen.dart  🆕
│   └── upgrade_screen.dart  🆕
└── widgets/
    ├── file_list_item.dart
    ├── file_upload_button.dart
    ├── storage_indicator.dart  🆕
    └── upgrade_dialog.dart  🆕
```

---

## 後端 API 需求（Render）

### 必要的 Endpoints

```
POST /api/upload/presigned-url
- 生成 Cloudflare R2 預簽名上傳 URL
- 驗證用戶是否為 Pro
- 輸入：{ fileName, projectId, userId }
- 輸出：{ uploadUrl, path, downloadUrl }

POST /api/subscription/verify
- 驗證訂閱狀態（防止客戶端偽造）
- 輸入：{ userId, paymentToken }
- 輸出：{ isPro, expiresAt }

GET /api/files/download/{fileId}
- 生成檔案下載連結
- 驗證用戶權限
- 輸出：{ downloadUrl, expiresIn }
```

---

## 開發時程

- **第 1 週**：步驟 0-1（訂閱系統 + 資料模型）
- **第 2 週**：步驟 2-3（檔案選擇 + 雙儲存系統）
- **第 3 週**：步驟 4-5（檔案顯示 + 協作功能）
- **第 4 週**：步驟 6-7（AI 分析 + 資料遷移）
- **第 5 週**：測試與優化 + 支付系統整合

---

## 用戶體驗設計

### 升級提示時機
1. 建立第 4 個專案時
2. 上傳第 11 個檔案時
3. 檔案總大小超過 500MB 時
4. 點擊「協作」按鈕時
5. AI 分析次數用完時

### 升級提示內容
```
🌟 解鎖 Ghote Pro 功能

✓ 雲端儲存 10GB（跨裝置同步）
✓ 無限專案與檔案
✓ 協作與共享功能
✓ AI 分析 500 次/月
✓ 優先客服支援

💰 NT$ 149/月 或 NT$ 1,490/年

[立即升級] [稍後再說]
```

---

## 注意事項

1. **安全性**：
   - Firestore 安全規則必須檢查訂閱狀態
   - 後端 API 要二次驗證用戶權限
   - 支付驗證要在伺服器端進行

2. **效能**：
   - 本地檔案使用快取機制
   - 雲端檔案實作斷點續傳
   - 大型檔案上傳顯示進度

3. **錯誤處理**：
   - 網路中斷時的重試機制
   - 儲存空間不足的提示
   - 支付失敗的處理流程

4. **使用者體驗**：
   - 清楚標示檔案儲存位置
   - 升級提示要有吸引力
   - 免費用戶不能感覺被「逼迫」升級

5. **法律合規**：
   - App Store / Google Play 內購政策
   - 自動續訂條款
   - 退款政策

---

## 測試清單

### 免費用戶測試
- [ ] 可以建立最多 3 個專案
- [ ] 每個專案最多 10 個檔案
- [ ] 檔案儲存在本地端
- [ ] 超過限制時顯示升級提示
- [ ] 無法使用協作功能

### Pro 用戶測試
- [ ] 可以建立無限專案
- [ ] 檔案上傳到 Cloudflare R2
- [ ] 檔案跨裝置同步
- [ ] 可以邀請協作者
- [ ] AI 分析次數正確計算

### 遷移測試
- [ ] 升級後自動遷移本地檔案
- [ ] 遷移進度正確顯示
- [ ] 遷移失敗可以重試
- [ ] 遷移完成後檔案可正常存取

---

## 更新記錄

- **2025-01-XX**：建立初始開發規劃
- **2025-01-XX**：加入付費機制和雙儲存系統設計
- **待更新**：各步驟完成後更新進度

---

*此文件將隨著開發進度持續更新*