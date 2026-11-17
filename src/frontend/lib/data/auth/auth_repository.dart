import 'package:onlyshrooms/domain/grzybiarz.dart';

abstract class AuthRepository {
  Grzybiarz? get currentUser;
  bool get isSignedIn;
  Stream<Grzybiarz?> get authStateChanges;

  Future<void> signInWithGoogle({bool register = false});
  Future<void> completeGoogleLogin(String token, {String? email});
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String imie,
    required String nazwisko,
  });
  Future<void> confirmEmail(String token);
  Future<void> loginWithEmail({
    required String email,
    required String password,
  });
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<void> signOut();
  Future<void> restoreSession();
}
