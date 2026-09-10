// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.8.4"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.3.2"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.4"),
        .package(name: "share_plus", path: "../.packages/share_plus-10.1.3"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.4.1"),
        .package(name: "purchases_ui_flutter", path: "../.packages/purchases_ui_flutter-9.6.0"),
        .package(name: "purchases_flutter", path: "../.packages/purchases_flutter-9.6.0"),
        .package(name: "onesignal_flutter", path: "../.packages/onesignal_flutter-5.6.8"),
        .package(name: "device_info_plus", path: "../.packages/device_info_plus-11.3.0"),
        .package(name: "in_app_review", path: "../.packages/in_app_review-2.0.11"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.22.1"),
        .package(name: "firebase_remote_config", path: "../.packages/firebase_remote_config-5.5.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-3.15.2"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-19.5.0"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-8.3.1"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-4.3.10"),
        .package(name: "posthog_flutter", path: "../.packages/posthog_flutter-5.39.0"),
        .package(name: "firebase_analytics", path: "../.packages/firebase_analytics-11.6.0"),
        .package(name: "flutter_timezone", path: "../.packages/flutter_timezone-4.1.1"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+7"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "purchases-ui-flutter", package: "purchases_ui_flutter"),
                .product(name: "purchases-flutter", package: "purchases_flutter"),
                .product(name: "onesignal-flutter", package: "onesignal_flutter"),
                .product(name: "device-info-plus", package: "device_info_plus"),
                .product(name: "in-app-review", package: "in_app_review"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "firebase-remote-config", package: "firebase_remote_config"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "posthog-flutter", package: "posthog_flutter"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "flutter-timezone", package: "flutter_timezone"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
