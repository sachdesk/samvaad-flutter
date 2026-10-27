# Yobruh Shop (Samvaad example)

A minimal app with a Help button and an unread badge. Help opens the chat with
"Help with order YB-1042" prefilled.

The platform folders are not checked in. Add them once:

```sh
cd example
flutter create . --org in.yobruh --project-name samvaad_widget_example
flutter run --dart-define=SAMVAAD_TENANT_ID=<your tenant id> --dart-define=SAMVAAD_HOST=<your host>
```

Then set iOS 15 in `ios/Podfile` and `minSdk` 24 in `android/app/build.gradle`, and add
the Android SDK's Maven repository (see the Android SDK README).
