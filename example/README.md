# Yobruh Shop (Samvaad example)

A minimal app with a Help button and an unread badge. Help opens the chat with
"Help with order YB-1042" prefilled.

## How CI builds it

The platform folders are not checked in. The `example-android` and `example-ios` jobs in
`.github/workflows/ci.yml` generate them with `flutter create`, then build the app so the
plugin's Kotlin and Swift compile against the real Samvaad SDKs:

- Android: checks out `sachdesk/samvaad-android`, publishes it with
  `./gradlew :samvaad:publishToMavenLocal`, adds `mavenLocal()` and `minSdk` 24, then runs
  `flutter build apk --debug`.
- iOS: checks out `sachdesk/samvaad-ios`, sets iOS 15, points the `Samvaad` pod at the
  checkout, runs `pod install`, then `flutter build ios --simulator --debug --no-codesign`.

While the SDK repos are private, the jobs need a repository secret `SDK_READ_TOKEN` with
read access to both. Without it they stop at the access check.

## Run it locally

```sh
cd example
flutter create . --org in.yobruh --project-name samvaad_widget_example
flutter run --dart-define=SAMVAAD_TENANT_ID=<your tenant id> --dart-define=SAMVAAD_HOST=<your host>
```

Before `flutter run`, wire up the native SDKs (until they are published):

- Android: in a checkout of `samvaad-android` run `./gradlew :samvaad:publishToMavenLocal`
  (JDK 17). Add `mavenLocal()` to the `allprojects { repositories { ... } }` block in
  `android/build.gradle(.kts)` and set `minSdk = 24` in `android/app/build.gradle(.kts)`.
- iOS: in `ios/Podfile` set `platform :ios, '15.0'` and add
  `pod 'Samvaad', :path => '<path to your samvaad-ios checkout>'` inside `target 'Runner'`.
  Set the Runner target's iOS deployment target to 15.0 in Xcode, then `pod install` in `ios/`.
