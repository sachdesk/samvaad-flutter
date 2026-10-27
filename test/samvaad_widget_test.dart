import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samvaad_widget/samvaad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('samvaad_widget');
  final List<MethodCall> calls = <MethodCall>[];
  Object? nextResult;

  setUp(() {
    calls.clear();
    nextResult = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return nextResult;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('configure sends tenantId and host', () async {
    await Samvaad.configure(
      tenantId: '6f1c2b8e-4a3d-4e2f-9b7a-1c5d8e0f2a34',
      host: 'yobruh.samvaads.com',
    );
    expect(calls, hasLength(1));
    expect(calls.single.method, 'configure');
    expect(calls.single.arguments, <String, Object?>{
      'tenantId': '6f1c2b8e-4a3d-4e2f-9b7a-1c5d8e0f2a34',
      'host': 'yobruh.samvaads.com',
    });
  });

  test('identify sends email, name and userHash', () async {
    await Samvaad.identify(
      email: 'asha@yobruh.in',
      name: 'Asha Verma',
      userHash: 'abc123',
    );
    expect(calls.single.method, 'identify');
    expect(calls.single.arguments, <String, Object?>{
      'email': 'asha@yobruh.in',
      'name': 'Asha Verma',
      'userHash': 'abc123',
    });
  });

  test('identify sends a null name when none is given', () async {
    await Samvaad.identify(email: 'asha@yobruh.in', userHash: 'abc123');
    expect(calls.single.arguments, <String, Object?>{
      'email': 'asha@yobruh.in',
      'name': null,
      'userHash': 'abc123',
    });
  });

  test('present sends the prefilled message', () async {
    await Samvaad.present(message: 'Help with order YB-1042');
    expect(calls.single.method, 'present');
    expect(calls.single.arguments, <String, Object?>{
      'message': 'Help with order YB-1042',
    });
  });

  test('present without a message sends null', () async {
    await Samvaad.present();
    expect(calls.single.arguments, <String, Object?>{'message': null});
  });

  test('logout', () async {
    await Samvaad.logout();
    expect(calls.single.method, 'logout');
    expect(calls.single.arguments, isNull);
  });

  test('setTheme sends the theme name', () async {
    await Samvaad.setTheme(SamvaadTheme.dark);
    await Samvaad.setTheme(SamvaadTheme.auto);
    expect(calls.map((MethodCall c) => c.method), <String>['setTheme', 'setTheme']);
    expect(calls[0].arguments, <String, Object?>{'theme': 'dark'});
    expect(calls[1].arguments, <String, Object?>{'theme': 'auto'});
  });

  test('unreadCount returns the native count', () async {
    nextResult = 3;
    expect(await Samvaad.unreadCount, 3);
    expect(calls.single.method, 'unreadCount');
  });

  test('unreadCount falls back to 0', () async {
    nextResult = null;
    expect(await Samvaad.unreadCount, 0);
  });

  test('setPushToken defaults to the fcm route', () async {
    await Samvaad.setPushToken('fcm-token-1');
    expect(calls.single.method, 'setPushToken');
    expect(calls.single.arguments, <String, Object?>{
      'token': 'fcm-token-1',
      'route': 'fcm',
    });
  });

  test('setPushToken with the apns route', () async {
    await Samvaad.setPushToken('0a1b2c3d', route: SamvaadPushRoute.apns);
    expect(calls.single.arguments, <String, Object?>{
      'token': '0a1b2c3d',
      'route': 'apns',
    });
  });

  test('handlePush passes the data and returns the native result', () async {
    nextResult = true;
    const Map<String, dynamic> data = <String, dynamic>{
      'samvaad': '1',
      'tenant_id': 't1',
      'session_id': 's1',
    };
    expect(await Samvaad.handlePush(data), isTrue);
    expect(calls.single.method, 'handlePush');
    expect(calls.single.arguments, <String, Object?>{'data': data});
  });

  test('handlePush returns false for a push that is not ours', () async {
    nextResult = false;
    expect(await Samvaad.handlePush(<String, dynamic>{'other': 'x'}), isFalse);
  });

  test('handlePush treats a null result as false', () async {
    nextResult = null;
    expect(await Samvaad.handlePush(<String, dynamic>{'samvaad': '1'}), isFalse);
  });

  test('native errors surface as PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      throw PlatformException(code: 'no_activity', message: 'No activity');
    });
    await expectLater(
      Samvaad.present(),
      throwsA(isA<PlatformException>()
          .having((PlatformException e) => e.code, 'code', 'no_activity')),
    );
  });
}
