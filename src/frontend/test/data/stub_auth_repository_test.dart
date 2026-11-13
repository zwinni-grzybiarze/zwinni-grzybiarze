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
    expect(user.id, matches(r'^stub-google-[0-9a-f]{6}$'));
    expect(user.email, matches(r'^demo-[0-9a-f]{6}@onlyshrooms\.app$'));
    expect(user.displayName, contains('Grzybiarz-'));
  });

  test('signInWithGoogle assigns distinct ids across logins', () async {
    final first = await auth.signInWithGoogle();
    await auth.signOut();
    final second = await auth.signInWithGoogle();
    expect(second.id, isNot(first.id));
  });

  test('register flag changes stub name', () async {
    final user = await auth.signInWithGoogle(register: true);
    expect(user.imie, 'Nowy');
  });

  test('session restores after sign-in', () async {
    final signedIn = await auth.signInWithGoogle();
    auth.dispose();

    final again = StubAuthRepository();
    addTearDown(again.dispose);
    await again.restoreSession();

    expect(again.isSignedIn, isTrue);
    expect(again.currentUser?.id, signedIn.id);
    expect(again.currentUser?.email, signedIn.email);
  });

  test('restoreSession upgrades legacy fixed stub identity', () async {
    SharedPreferences.setMockInitialValues({
      'onlyshrooms_stub_user':
          'stub-google-1|Demo|Grzybiarz|demo@onlyshrooms.app',
    });
    final again = StubAuthRepository();
    addTearDown(again.dispose);

    await again.restoreSession();

    expect(again.isSignedIn, isTrue);
    expect(again.currentUser?.id, isNot('stub-google-1'));
    expect(again.currentUser?.id, matches(r'^stub-google-[0-9a-f]{6}$'));
    expect(again.currentUser?.displayName, contains('Grzybiarz-'));
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
