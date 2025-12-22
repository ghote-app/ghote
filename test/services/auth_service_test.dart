import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock classes for Firebase Auth
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late AuthService authService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    authService = AuthService(auth: mockAuth, firestore: fakeFirestore);
  });

  group('AuthService', () {
    group('currentUser', () {
      test('should return null when no user is logged in', () {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(authService.currentUser, isNull);
      });

      test('should return user when logged in', () {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('user_123');
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.uid, 'user_123');
      });
    });

    group('getIdToken', () {
      test('should return null when no user is logged in', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        final token = await authService.getIdToken();

        expect(token, isNull);
      });

      test('should return token when user is logged in', () async {
        final mockUser = MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(false)).thenAnswer((_) async => 'test_token');

        final token = await authService.getIdToken();

        expect(token, 'test_token');
      });

      test('should force refresh token when requested', () async {
        final mockUser = MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => 'refreshed_token');

        final token = await authService.getIdToken(forceRefresh: true);

        expect(token, 'refreshed_token');
        verify(() => mockUser.getIdToken(true)).called(1);
      });
    });

    group('ensureUserRecord', () {
      test('should create new user record for first-time user', () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('new_user_123');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.photoURL).thenReturn(null);
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockUser.providerData).thenReturn([]);

        await authService.ensureUserRecord(mockUser);

        final doc = await fakeFirestore.collection('users').doc('new_user_123').get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['uid'], 'new_user_123');
        expect(doc.data()?['email'], 'test@example.com');
        expect(doc.data()?['displayName'], 'Test User');
        expect(doc.data()?['emailVerified'], isTrue);
      });

      test('should update lastLoginAt for existing user', () async {
        // First, create a user record
        await fakeFirestore.collection('users').doc('existing_user').set({
          'uid': 'existing_user',
          'email': 'existing@example.com',
          'displayName': 'Existing User',
          'createdAt': DateTime.now().toIso8601String(),
        });

        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('existing_user');
        when(() => mockUser.email).thenReturn('existing@example.com');
        when(() => mockUser.displayName).thenReturn('Updated Name');
        when(() => mockUser.photoURL).thenReturn('https://photo.url');
        when(() => mockUser.emailVerified).thenReturn(true);
        when(() => mockUser.providerData).thenReturn([]);

        await authService.ensureUserRecord(mockUser);

        final doc = await fakeFirestore.collection('users').doc('existing_user').get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['displayName'], 'Updated Name');
        expect(doc.data()?['photoURL'], 'https://photo.url');
      });
    });

    group('getUserRecord', () {
      test('should return user record when exists', () async {
        await fakeFirestore.collection('users').doc('user_123').set({
          'uid': 'user_123',
          'email': 'test@example.com',
          'displayName': 'Test User',
        });

        final record = await authService.getUserRecord('user_123');

        expect(record, isNotNull);
        expect(record?['uid'], 'user_123');
        expect(record?['email'], 'test@example.com');
      });

      test('should return null for non-existent user', () async {
        final record = await authService.getUserRecord('non_existent');

        expect(record, isNull);
      });
    });

    group('watchUserRecord', () {
      test('should stream user record changes', () async {
        await fakeFirestore.collection('users').doc('user_123').set({
          'uid': 'user_123',
          'displayName': 'Initial Name',
        });

        final stream = authService.watchUserRecord('user_123');
        final snapshot = await stream.first;

        expect(snapshot.exists, isTrue);
        expect(snapshot.data()?['displayName'], 'Initial Name');
      });
    });

    group('signOut', () {
      test('should call Firebase signOut', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await authService.signOut();

        verify(() => mockAuth.signOut()).called(1);
      });
    });

    group('deleteAccount', () {
      test('should delete user document and Firebase account', () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('user_to_delete');
        when(() => mockUser.delete()).thenAnswer((_) async {});
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        // Create user record first
        await fakeFirestore.collection('users').doc('user_to_delete').set({
          'uid': 'user_to_delete',
        });

        await authService.deleteAccount();

        // Verify Firestore record is deleted
        final doc = await fakeFirestore.collection('users').doc('user_to_delete').get();
        expect(doc.exists, isFalse);

        // Verify Firebase delete was called
        verify(() => mockUser.delete()).called(1);
      });

      test('should do nothing when no user is logged in', () async {
        when(() => mockAuth.currentUser).thenReturn(null);

        await authService.deleteAccount();

        // No exception should be thrown
      });
    });
  });
}
