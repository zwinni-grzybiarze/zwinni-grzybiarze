import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/auth/auth_repository.dart';
import 'package:onlyshrooms/domain/grzybiarz.dart';
import 'package:onlyshrooms/features/auth/auth_controller.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('init restores session and marks controller ready', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.init();

    expect(repository.restoreCalls, 1);
    expect(controller.ready, isTrue);
    expect(notifications, 1);
  });

  test('sign-in forwards register flag and reports busy state', () async {
    final signIn = Completer<Grzybiarz>();
    repository.signInResult = signIn.future;
    final busyStates = <bool>[];
    controller.addListener(() => busyStates.add(controller.busy));

    final operation = controller.signInWithGoogle(register: true);
    expect(controller.busy, isTrue);

    signIn.complete(
      const Grzybiarz(id: 'user-1', imie: 'Ada', nazwisko: 'Kowalska'),
    );
    await operation;

    expect(repository.registerValues, [true]);
    expect(controller.busy, isFalse);
    expect(busyStates, [true, false]);
  });

  test('clears busy state and notifies listeners when sign-in fails', () async {
    repository.signInResult = Future<Grzybiarz>.error(StateError('failed'));
    var notifications = 0;
    controller.addListener(() => notifications++);

    await expectLater(
      controller.signInWithGoogle(),
      throwsA(isA<StateError>()),
    );

    expect(controller.busy, isFalse);
    expect(notifications, 2);
  });

  test('sign-out delegates and notifies listeners', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.signOut();

    expect(repository.signOutCalls, 1);
    expect(notifications, 1);
  });

  test('notifies listeners when auth state changes', () async {
    await controller.init();
    var notifications = 0;
    controller.addListener(() => notifications++);

    repository.authStateController.add(
      const Grzybiarz(id: 'user-1', imie: 'Ada', nazwisko: 'Kowalska'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 1);
  });
}

class FakeAuthRepository implements AuthRepository {
  final authStateController = StreamController<Grzybiarz?>.broadcast();
  Future<Grzybiarz> signInResult = Future.value(
    const Grzybiarz(id: 'user-1', imie: 'Ada', nazwisko: 'Kowalska'),
  );
  final registerValues = <bool>[];
  var restoreCalls = 0;
  var signOutCalls = 0;

  Future<void> close() => authStateController.close();

  @override
  Grzybiarz? get currentUser => null;

  @override
  bool get isSignedIn => false;

  @override
  Stream<Grzybiarz?> get authStateChanges => authStateController.stream;

  @override
  Future<void> restoreSession() async {
    restoreCalls++;
  }

  @override
  Future<Grzybiarz> signInWithGoogle({bool register = false}) {
    registerValues.add(register);
    return signInResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}
