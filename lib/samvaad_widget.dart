/// Samvaad chat for Flutter apps.
///
/// A thin binding over the native Samvaad iOS and Android SDKs. The chat screen
/// itself is shown by the native SDK.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// Light / dark look of the chat screen.
enum SamvaadTheme {
  /// Follow the app's light / dark mode (default).
  auto,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// Which push service a token belongs to.
enum SamvaadPushRoute {
  /// A Firebase Cloud Messaging registration token (Android, or iOS apps using Firebase).
  fcm,

  /// An APNs device token as a hex string (iOS only).
  apns,
}

/// The Samvaad chat SDK.
///
/// Call [configure] once at startup, before anything else.
class Samvaad {
  Samvaad._();

  static const MethodChannel _channel = MethodChannel('samvaad_widget');
  static const EventChannel _unreadChannel = EventChannel('samvaad_widget/unread');

  static Stream<int>? _unreadStream;

  /// Sets up the SDK.
  ///
  /// [tenantId] is your Samvaad tenant id. [host] is the host serving your chat
  /// widget, e.g. `yobruh.samvaads.com`. Both are required.
  static Future<void> configure({
    required String tenantId,
    required String host,
  }) {
    return _channel.invokeMethod<void>('configure', <String, Object?>{
      'tenantId': tenantId,
      'host': host,
    });
  }

  /// Tells the chat who the signed-in customer is.
  ///
  /// [userHash] is HMAC-SHA256 of the lower-cased email, keyed with your identity
  /// secret, as hex. Compute it on your backend. Never put the identity secret
  /// in the app.
  static Future<void> identify({
    required String email,
    String? name,
    required String userHash,
  }) {
    return _channel.invokeMethod<void>('identify', <String, Object?>{
      'email': email,
      'name': name,
      'userHash': userHash,
    });
  }

  /// Opens the chat screen.
  ///
  /// [message] is optional text to prefill in the message box (not sent).
  static Future<void> present({String? message}) {
    return _channel.invokeMethod<void>('present', <String, Object?>{
      'message': message,
    });
  }

  /// The customer signed out of your app: forget them in the chat.
  ///
  /// The device push token is kept and registered again with the next chat.
  static Future<void> logout() {
    return _channel.invokeMethod<void>('logout');
  }

  /// Sets the light / dark look of the chat screen. Default [SamvaadTheme.auto].
  static Future<void> setTheme(SamvaadTheme theme) {
    return _channel.invokeMethod<void>('setTheme', <String, Object?>{
      'theme': theme.name,
    });
  }

  /// Agent replies the customer hasn't seen yet, as last reported by the chat.
  static Future<int> get unreadCount async {
    final int? count = await _channel.invokeMethod<int>('unreadCount');
    return count ?? 0;
  }

  /// Unread count changes. The current count is sent when you start listening.
  static Stream<int> get onUnreadChange {
    return _unreadStream ??= _unreadChannel
        .receiveBroadcastStream()
        .map((dynamic count) => (count as num).toInt());
  }

  /// Gives the SDK this device's push token. The chat registers it for push.
  ///
  /// With [SamvaadPushRoute.fcm] (default), [token] is a Firebase Cloud
  /// Messaging registration token. With [SamvaadPushRoute.apns] (iOS only),
  /// [token] is the APNs device token as a hex string.
  static Future<void> setPushToken(
    String token, {
    SamvaadPushRoute route = SamvaadPushRoute.fcm,
  }) {
    return _channel.invokeMethod<void>('setPushToken', <String, Object?>{
      'token': token,
      'route': route.name,
    });
  }

  /// Handles a push payload (FCM `RemoteMessage.data`, or the APNs `userInfo`).
  ///
  /// Returns `false` when it isn't a Samvaad push (handle it yourself);
  /// otherwise opens the chat and returns `true`.
  static Future<bool> handlePush(Map<String, dynamic> data) async {
    final bool? handled =
        await _channel.invokeMethod<bool>('handlePush', <String, Object?>{
      'data': data,
    });
    return handled ?? false;
  }
}
