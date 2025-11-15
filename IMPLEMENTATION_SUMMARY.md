# DashboardScreen 專案管理與文件上傳功能實作總結

## 完成日期
2025-11-15

## 實作內容

### 1. ProjectService 擴充
**檔案**: `lib/services/project_service.dart`

新增方法：
```dart
Future<int> getProjectFileCount(String projectId) async {
  final snap = await _filesCol(projectId).count().get();
  return snap.count ?? 0;
}
```

**功能**: 獲取指定專案中的文件數量，用於檢查文件上傳限制。

---

### 2. DashboardScreen 改進
**檔案**: `lib/screens/dashboard_screen.dart`

#### 2.1 新增輔助方法：獲取專案數量與訂閱狀態

```dart
Future<({int count, Subscription sub})> _getUserProjectCountAndSubscription() async {
  final user = FirebaseAuth.instance.currentUser;
  final sub = await SubscriptionService().getUserSubscription(user?.uid ?? '');
  final projects = await ProjectService().watchProjectsByOwner(user!.uid).first;
  return (count: projects.length, sub: sub);
}
```

**功能**: 
- 獲取當前用戶的專案數量
- 獲取當前用戶的訂閱狀態
- 返回一個記錄 (Record) 包含兩個欄位

---

#### 2.2 完善 `_createNewProject()` - 實作專案數量限制

**新功能**:
1. 在建立專案前先檢查用戶登入狀態
2. 呼叫 `_getUserProjectCountAndSubscription()` 獲取當前狀態
3. 如果是免費或 Plus 用戶且已有 3 個專案，顯示提示對話框並中斷操作
4. 否則繼續原有的專案建立流程

**限制規則**:
- 免費方案：最多 3 個專案
- Plus 方案：最多 3 個專案
- Pro 方案：無限制

---

#### 2.3 新增專案選擇彈窗 `_promptProjectSelection()`

**取代**: 舊的 `_promptProjectId()` 方法

```dart
Future<Project?> _promptProjectSelection(BuildContext context, List<Project> projects) async
```

**功能**:
1. 如果沒有專案，顯示提示訊息「請先建立一個 Project」
2. 如果有專案，顯示一個列表供用戶選擇
3. 每個專案項目顯示：
   - 專案標題
   - 分類
   - 狀態標籤
4. 返回用戶選擇的 Project 物件，或 null（取消）

---

#### 2.4 完善 `_pickAndUploadFlow()` - 實作檔案限制與雙儲存上傳

**新增的檢查流程**:

1. **專案選擇**
   - 獲取用戶的所有專案
   - 呼叫 `_promptProjectSelection()` 讓用戶選擇專案
   - 如果未選擇則中斷

2. **單檔大小限制檢查 (10MB)**
   - 遍歷所有選取的檔案
   - 如果任何檔案超過 10MB，顯示 SnackBar 並中斷上傳
   - 訊息：「檔案大小超過 10MB 上限，已取消上傳。」

3. **專案檔案數量限制檢查 (10 個文件)**
   - 獲取用戶訂閱狀態
   - 使用 `ProjectService().getProjectFileCount()` 獲取當前專案的檔案數量
   - 如果是免費或 Plus 用戶，且現有檔案數 + 欲上傳檔案數 > 10：
     - 顯示升級提示 AlertDialog
     - 訊息：「免費/Plus 方案每個專案最多 10 個文件。請升級到 Ghote Pro 享受無限文件上傳。」
     - 中斷上傳

4. **上傳與儲存**
   - 使用選擇的 `selectedProject.id` 替代原有的 `projectId` 變數
   - 確保呼叫 `storage.uploadToCloudflare()` 時傳入 `subscription` 物件
   - Pro 用戶：上傳到 Cloudflare R2 (無限空間)
   - 免費/Plus 用戶：儲存到本地或 Firebase Storage (有限空間)

---

### 3. 付費方案限制總結

| 功能 | 免費方案 | Plus 方案 | Pro 方案 |
|------|---------|----------|---------|
| 專案數量 | 3 個 | 3 個 | 無限制 |
| 每個專案文件數 | 10 個 | 10 個 | 無限制 |
| 單檔大小限制 | 10MB | 10MB | 10MB |
| 儲存空間 | 有限 | 有限 | 無限 (R2) |

---

## 相關需求文件對應

- **FR-2.1**: 專案管理 - 建立、編輯、刪除專案
- **FR-3.1**: 文件上傳 - 支援多種文件格式
- **FR-3.2**: 檔案限制 - 單檔大小、數量限制
- **DEVELOPMENT_PLAN.md**: 付費方案限制

---

## 測試建議

1. **專案建立測試**
   - 免費用戶建立第 4 個專案時應被阻止
   - Pro 用戶可以建立超過 3 個專案

2. **檔案上傳測試**
   - 上傳超過 10MB 的檔案應被拒絕
   - 免費用戶上傳第 11 個檔案時應被阻止
   - 測試未選擇專案的情況
   - 測試沒有專案時的提示

3. **UI/UX 測試**
   - 專案選擇對話框正確顯示所有專案
   - 所有錯誤訊息都正確顯示中文提示
   - 取消操作不會造成錯誤

---

## 後續優化建議

1. 在專案列表中顯示實際的文件數量（目前顯示為 0）
2. 在上傳前顯示預計使用的空間
3. 增加批次上傳進度顯示
4. 支援拖放上傳功能
5. 增加檔案預覽功能

---

## 變更檔案清單

- `lib/services/project_service.dart` - 新增 `getProjectFileCount()` 方法
- `lib/screens/dashboard_screen.dart` - 完善專案管理與文件上傳功能
  - 新增 `_getUserProjectCountAndSubscription()` 方法
  - 修改 `_createNewProject()` 實作專案數量限制
  - 新增 `_promptProjectSelection()` 取代舊的 `_promptProjectId()`
  - 完善 `_pickAndUploadFlow()` 實作完整的檔案限制檢查
  - 新增 `../models/subscription.dart` 的 import

---

## 結論

所有要求的功能已完整實作，包括：
✅ 專案數量限制（3個，免費/Plus）
✅ 檔案數量限制（每個專案10個，免費/Plus）
✅ 單檔大小限制（10MB）
✅ 專案選擇介面
✅ 完整的錯誤提示與用戶引導
✅ 雙儲存策略（本地/雲端）

代碼無編譯錯誤，準備進行測試。
