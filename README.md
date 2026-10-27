# Samvaad for Flutter

Samvaad chat for Flutter apps. This plugin is a thin binding over the Samvaad iOS and
Android SDKs: they open your Samvaad website chat full screen inside your app, sign your
customer in, report the unread count and handle push.

Version 0.1.0. Flutter 3.16+, iOS 15+, Android 7.0 (API 24)+.

## Install

```yaml
dependencies:
  samvaad_widget:
    git:
      url: https://github.com/sachdesk/samvaad-flutter.git
      ref: v0.1.0
```

**iOS:** nothing extra. Flutter runs `pod install` for you, which pulls the `Samvaad`
pod (~> 0.1.0). Set `platform :ios, '15.0'` (or higher) in `ios/Podfile`.

Customers can attach photos and files in the chat, so add these to `ios/Runner/Info.plist`:

- `NSCameraUsageDescription`, e.g. "Take a photo to send to Yobruh support."
- `NSPhotoLibraryUsageDescription`, e.g. "Choose a photo to send to Yobruh support."

**Android:** the plugin depends on `com.samvaads:widget:0.1.0`. Until it is on Maven
Central, add the repository that hosts it to `android/build.gradle` (or
`android/settings.gradle`): see the Android SDK README. Set `minSdk` to 24 or higher.

## Configure

Call once at startup, before anything else:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Samvaad.configure(
    tenantId: '6f1c2b8e-4a3d-4e2f-9b7a-1c5d8e0f2a34', // your tenant id
    host: 'yobruh.samvaads.com',
  );
  runApp(const YobruhShopApp());
}
```

`host` is required: the host serving your chat widget, as `yobruh.samvaads.com` or
`https://yobruh.samvaads.com`. It must be https.

## Identify the customer

When the customer is signed in to your app:

```dart
await Samvaad.identify(
  email: 'asha@yobruh.in',
  name: 'Asha Verma',
  userHash: hashFromYourBackend,
);
```

`userHash` is HMAC-SHA256 of the lower-cased email, keyed with your identity secret, as hex.

**Compute `userHash` on your backend. Never put the identity secret in the app.**

Node example for your backend:

```js
const crypto = require('crypto')

function samvaadUserHash(email) {
  return crypto
    .createHmac('sha256', process.env.SAMVAAD_IDENTITY_SECRET)
    .update(email.trim().toLowerCase())
    .digest('hex')
}
```

## Open the chat

```dart
await Samvaad.present();
await Samvaad.present(message: 'Help with order YB-1042'); // prefilled, not sent
```

On Android `present` needs a foreground activity; it fails with `PlatformException`
code `no_activity` otherwise.

## Unread badge

```dart
StreamBuilder<int>(
  stream: Samvaad.onUnreadChange,
  initialData: 0,
  builder: (context, snapshot) => Badge(
    isLabelVisible: (snapshot.data ?? 0) > 0,
    label: Text('${snapshot.data ?? 0}'),
    child: const Icon(Icons.support_agent),
  ),
);

final count = await Samvaad.unreadCount;
```

The stream sends the current count as soon as you listen.

## Push

1. Set up push in your app as usual (for example with `firebase_messaging`).
2. In Samvaad, go to **Admin → Website widget → Mobile apps** and upload your keys:
   - Firebase (Android, and iOS apps using Firebase): the service account key JSON
     (Firebase console → Project settings → Service accounts → Generate new private key).
   - APNs (iOS apps without Firebase): the APNs key (.p8), key ID, team ID and bundle ID.
3. Give the plugin the device token:

```dart
// FCM token (Android, or iOS with Firebase)
await Samvaad.setPushToken(fcmToken);

// APNs device token as a hex string (iOS only)
await Samvaad.setPushToken(apnsHexToken, route: SamvaadPushRoute.apns);
```

The chat registers the token for the customer's conversation.

## Handle a push tap

Samvaad pushes carry a notification plus data `samvaad = "1"`, `tenant_id`, `session_id`.
Pass the data when the customer taps a notification:

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) async {
  if (await Samvaad.handlePush(message.data)) return;
  // not a Samvaad push: handle it yourself
});
```

`handlePush` returns `false` for anything that isn't a Samvaad push, otherwise it opens
the chat and returns `true`.

## Log out

```dart
await Samvaad.logout();
```

The chat forgets the customer (now if it is open, otherwise the next time it opens). The
device push token is kept for the next chat.

## Theme

```dart
await Samvaad.setTheme(SamvaadTheme.auto); // default: follows the app's light / dark mode
await Samvaad.setTheme(SamvaadTheme.dark);
```

## Local testing

In debug builds the native SDKs also accept a local Samvaad UI as `host`:

```dart
await Samvaad.configure(tenantId: tenantId, host: 'http://10.0.2.2:5173'); // Android emulator
await Samvaad.configure(tenantId: tenantId, host: 'http://localhost:5173'); // iOS simulator
```

See the iOS and Android SDK READMEs for the debug-only settings this needs (iOS local
network loads in `Info.plist`).

The `example/` app (Yobruh Shop) shows a Help button with an unread badge. Run
`flutter create .` inside `example/` once to add the platform folders, then `flutter run`.

## License

MIT. See `LICENSE`.
