import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onlyshrooms/data/auth/keycloak_auth_manager.dart';
import 'package:onlyshrooms/data/auth/keycloak_auth_repository.dart';

void main() {
  late FakeKeycloakAuthManager manager;
  late Dio api;
  late KeycloakAuthRepository repository;
  late Map<String, dynamic> apiResponse;
  var requestCount = 0;
  RequestOptions? request;

  setUp(() {
    manager = FakeKeycloakAuthManager();
    apiResponse = {
      'keycloakId': 'api-user-1',
      'imie': 'Ada',
      'nazwisko': 'Kowalska',
      'email': 'ada@example.test',
    };
    requestCount = 0;
    request = null;
    api = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
    api.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestCount++;
          request = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: apiResponse,
            ),
          );
        },
      ),
    );
    repository = KeycloakAuthRepository(manager, api);
  });

  tearDown(() async {
    await manager.close();
    api.close(force: true);
  });

  test('maps current user claims and auth state changes', () async {
    manager.currentUser = const KeycloakIdentity(
      id: 'keycloak-user-1',
      claims: {
        'given_name': 'Ada',
        'family_name': 'Kowalska',
        'email': 'ada@example.test',
      },
    );

    expect(repository.isSignedIn, isTrue);
    expect(repository.currentUser?.id, 'keycloak-user-1');
    expect(repository.currentUser?.displayName, 'Ada Kowalska');
    expect(repository.currentUser?.email, 'ada@example.test');

    final events = <dynamic>[];
    final subscription = repository.authStateChanges.listen(events.add);
    manager.userChangesController.add(null);
    manager.userChangesController.add(manager.currentUser);
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(events, hasLength(2));
    expect(events.first, isNull);
    expect(events.last.id, 'keycloak-user-1');
  });

  test(
    'Google sign-in provisions user with token and maps API response',
    () async {
      manager.currentUser = const KeycloakIdentity(
        id: 'keycloak-user-1',
        claims: {
          'given_name': 'Ada',
          'family_name': 'Kowalska',
          'email': 'ada@example.test',
        },
      );

      final user = await repository.signInWithGoogle();

      expect(manager.signInCalls, 1);
      expect(user.id, 'api-user-1');
      expect(user.displayName, 'Ada Kowalska');
      expect(user.email, 'ada@example.test');
      expect(requestCount, 1);
      expect(request!.path, '/api/auth/me');
      expect(request!.data, {
        'keycloakId': 'keycloak-user-1',
        'email': 'ada@example.test',
        'imie': 'Ada',
        'nazwisko': 'Kowalska',
      });
      expect(
        request!.headers['Authorization'],
        ['Bear', 'er test-access-token'].join(''),
      );
    },
  );

  test('restore initializes and provisions an existing session', () async {
    manager.currentUser = const KeycloakIdentity(
      id: 'keycloak-user-1',
      claims: {'email': 'ada@example.test'},
    );

    await repository.restoreSession();

    expect(manager.initCalls, 1);
    expect(requestCount, 1);
    expect(
      request!.headers['Authorization'],
      ['Bear', 'er test-access-token'].join(''),
    );
  });

  test('restore initializes without provisioning when signed out', () async {
    await repository.restoreSession();

    expect(manager.initCalls, 1);
    expect(requestCount, 0);
  });

  test('fails without an access token and skips the API request', () async {
    manager.currentUser = const KeycloakIdentity(
      id: 'keycloak-user-1',
      claims: {},
    );
    manager.accessToken = null;

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<StateError>()),
    );

    expect(requestCount, 0);
  });

  test('fails when Google sign-in completes without a user', () async {
    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<StateError>()),
    );

    expect(requestCount, 0);
  });

  test('fails when the API response does not contain a user id', () async {
    manager.currentUser = const KeycloakIdentity(
      id: 'keycloak-user-1',
      claims: {},
    );
    apiResponse = {'email': 'ada@example.test'};

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<StateError>()),
    );

    expect(requestCount, 1);
  });

  test('signOut delegates to the OIDC manager', () async {
    await repository.signOut();
    expect(manager.logoutCalls, 1);
  });
}

class FakeKeycloakAuthManager implements KeycloakAuthManager {
  final userChangesController = StreamController<KeycloakIdentity?>.broadcast();
  @override
  KeycloakIdentity? currentUser;
  String? accessToken = 'test-access-token';
  var initCalls = 0;
  var signInCalls = 0;
  var logoutCalls = 0;

  Future<void> close() => userChangesController.close();

  @override
  Stream<KeycloakIdentity?> get userChanges => userChangesController.stream;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<KeycloakIdentity?> signInWithGoogle() async {
    signInCalls++;
    return currentUser;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}
