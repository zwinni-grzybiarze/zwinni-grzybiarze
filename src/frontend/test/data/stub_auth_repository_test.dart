import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/auth/stub_auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StubAuthRepository auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = StubAuthRepository();
  });

  tearDown(() {
    auth.dispose();
  });

  test('signInWithGoogle sets session instantly', () async {
    expect(auth.isSignedIn, isFalse);

    final user = await auth.signInWithGoogle();
    expect(auth.isSignedIn, isTrue);
    expect(auth.currentUser?.email, 'demo@onlyshrooms.app');
    expect(user.displayName, contains('Grzybiarz'));
  });

  test('register flag changes stub name', () async {
    final user = await auth.signInWithGoogle(register: true);
    expect(user.imie, 'Nowy');
  });

  test('session restores after sign-in', () async {
    await auth.signInWithGoogle();
    auth.dispose();

    final again = StubAuthRepository();
    addTearDown(again.dispose);
    await again.restoreSession();

    expect(again.isSignedIn, isTrue);
    expect(again.currentUser?.email, 'demo@onlyshrooms.app');
  });

  test('signOut clears session', () async {
    await auth.signInWithGoogle();
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    expect(auth.currentUser, isNull);

    final again = StubAuthRepository();
    addTearDown(again.dispose);
    await again.restoreSession();
    expect(again.isSignedIn, isFalse);
  });
}
