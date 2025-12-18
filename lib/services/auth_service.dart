import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// FR-1 用戶認證服務
/// 
/// 處理用戶認證相關功能，包括：
/// - FR-1.7: API Token 驗證
/// - FR-1.8: 首次登入時自動建立用戶記錄
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// 取得當前用戶
  User? get currentUser => _auth.currentUser;

  /// 監聽認證狀態變化
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 監聽用戶變化（包含 profile 更新）
  Stream<User?> get userChanges => _auth.userChanges();

  /// FR-1.7: 取得有效的 ID Token
  /// 
  /// 如果 Token 過期會自動刷新
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('AuthService.getIdToken error: $e');
      return null;
    }
  }

  /// FR-1.7: 取得 ID Token 結果（包含 claims）
  Future<IdTokenResult?> getIdTokenResult({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      return await user.getIdTokenResult(forceRefresh);
    } catch (e) {
      debugPrint('AuthService.getIdTokenResult error: $e');
      return null;
    }
  }

  /// FR-1.8: 確保用戶記錄存在於 Firestore
  /// 
  /// 首次驗證 Firebase Token 後，自動在資料庫建立對應的使用者記錄。
  /// 如果記錄已存在，則更新 lastLoginAt。
  Future<void> ensureUserRecord(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // 首次登入，建立用戶記錄
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'emailVerified': user.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'provider': _getAuthProvider(user),
        });
        debugPrint('AuthService: Created new user record for ${user.uid}');
      } else {
        // 已存在，更新最後登入時間
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          // 同步更新可能變更的資料
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'emailVerified': user.emailVerified,
        });
        debugPrint('AuthService: Updated lastLoginAt for ${user.uid}');
      }
    } catch (e) {
      debugPrint('AuthService.ensureUserRecord error: $e');
      // 不拋出錯誤，避免阻斷登入流程
    }
  }

  /// 取得用戶的認證提供者
  String _getAuthProvider(User user) {
    if (user.providerData.isEmpty) return 'unknown';
    
    for (final provider in user.providerData) {
      if (provider.providerId == 'google.com') return 'google';
      if (provider.providerId == 'password') return 'email';
      if (provider.providerId == 'apple.com') return 'apple';
    }
    
    return user.providerData.first.providerId;
  }

  /// 取得用戶記錄
  Future<Map<String, dynamic>?> getUserRecord(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('AuthService.getUserRecord error: $e');
      return null;
    }
  }

  /// 監聽用戶記錄變化
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserRecord(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// 更新用戶 profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 更新 Firebase Auth profile
      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // 同步更新 Firestore 用戶記錄
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      debugPrint('AuthService.updateUserProfile error: $e');
      rethrow;
    }
  }

  /// FR-1.6: 登出
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 刪除用戶帳號和相關資料
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 刪除 Firestore 用戶記錄
      await _firestore.collection('users').doc(user.uid).delete();
      
      // 刪除 Firebase Auth 帳號
      await user.delete();
    } catch (e) {
      debugPrint('AuthService.deleteAccount error: $e');
      rethrow;
    }
  }
}
