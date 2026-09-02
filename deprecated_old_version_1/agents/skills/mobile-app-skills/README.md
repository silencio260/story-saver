# ai_chatbot

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.







### Dev Section

adb connect 192.168.171.228:5555
adb tcpip 5555

adb devices

adb kill-server
adb start-server



flutter emulators
flutter emulators --launch Pixel_9_Pro_API_35-ext15

flutter clean build  
flutter build appbundle --dart-define-from-file=env/release.json

shorebird release android -- --dart-define-from-file=env/release.json

zip -d Archive.zip "__MACOSX*" 


flutter clean
flutter build apk --release --dart-define-from-file=env/release.json

build/app/outputs/flutter-apk/app-release.apk

Option A: Using flutter install
flutter install --release

Option B: Using adb directly
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb uninstall com.yourcompany.yourapp



flutter run --release
flutter run --release --dart-define-from-file=env/release.json



-------------------------
https://docs.shorebird.dev/code-push/initialize/
shorebird init

https://docs.shorebird.dev/code-push/release/
shorebird release android


https://docs.shorebird.dev/code-push/patch/
shorebird patch android
shorebird patch android --release-version latest
shorebird patch android --release-version 0.1.0+1







