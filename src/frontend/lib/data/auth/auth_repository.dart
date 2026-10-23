import 'package:onlyshrooms/domain/grzybiarz.dart';

/// Auth abstraction. Stub this sprint - real Google/JWT next sprint (#8, #39).
abstract class AuthRepository {
  Grzybiarz? get currentUser;

  bool get isSignedIn;

  Stream<Grzybiarz?> get authStateChanges;

  /// Instant fake session for UI demos —-replace with Google OAuth later.
  Future<Grzybiarz> signInWithGoogle({bool register = false});

  Future<void> signOut();

  Future<void> restoreSession();
}
