import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/src/api/api.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/plumber.dart';

import 'fixtures/api_responses.dart';
import 'helpers/test_helpers.dart';

class MockRiveApi extends Mock implements RiveApi {
  final host = '';
}

void main() {
  group('User Manager ', () {
    MockRiveApi riveApi;
    MeApi mockedMeApi;
    UserManager userManager;
    setUp(() {
      riveApi = MockRiveApi();
      when(riveApi.getFromPath('/api/me'))
          .thenAnswer((_) async => successMeResponse);
      mockedMeApi = MeApi(riveApi);
      userManager = UserManager.tester(mockedMeApi);
    });
    tearDown(() {
      Plumber().reset();
    });

    test('load me', () async {
      final testComplete = Completer();

      Plumber().getStream<Me>().listen((event) {
        expect(event.name, 'MaxMax');
        testComplete.complete();
      });

      userManager.loadMe();

      await testComplete.future;
    });

    test('logout', () async {
      final testComplete = testStream(Plumber().getStream<Me>(), [
        (Me me) => me.isEmpty,
        (Me me) => me.name == 'MaxMax',
        (Me me) => me.isEmpty,
      ]);

      // Send empty user first.
      await userManager.logout();
      await userManager.loadMe();
      await userManager.logout();

      await testComplete.future;
    });

    test('sequence', () async {
      final testComplete = testStream(Plumber().getStream<Me>(), [
        (Me me) => me.name == 'MaxMax',
        (Me me) => me.isEmpty,
        (Me me) => me.name == 'MaxMax',
      ]);

      await userManager.loadMe();
      await userManager.logout();
      await userManager.loadMe();

      await testComplete.future;
    });
  });
}
