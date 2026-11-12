import 'package:onlyshrooms/domain/grzybiarz.dart';

abstract class AuthRepository {
  Grzybiarz? get currentUser;
  bool get isSignedIn;
  Stream<Grzybiarz?> get authStateChanges;

  Future<void> signInWithGoogle({bool register = false});
  Future<void> completeGoogleLogin(String token, {String? email});
  Future<void> signOut();
  Future<void> restoreSession();
}
