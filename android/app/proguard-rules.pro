# RevenueCat Proguard Rules
-keep class com.revenuecat.purchases.** { *; }
-keep class com.revenuecat.purchases.ui.** { *; }
-keep class com.revenuecat.** { *; }

# Prevent obfuscation of RevenueCat classes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# PostHog Proguard Rules
-keep class com.posthog.flutter.** { *; }
-keep class com.posthog.** { *; }

# Classes that SDKs reference but that are not in the app. R8 stops the release
# build on them; these lines come from its generated
# build/app/outputs/mapping/release/missing_rules.txt.
-dontwarn com.facebook.infer.annotation.Nullsafe$Mode
-dontwarn com.facebook.infer.annotation.Nullsafe
-dontwarn com.google.api.client.http.GenericUrl
-dontwarn com.google.api.client.http.HttpHeaders
-dontwarn com.google.api.client.http.HttpRequest
-dontwarn com.google.api.client.http.HttpRequestFactory
-dontwarn com.google.api.client.http.HttpResponse
-dontwarn com.google.api.client.http.HttpTransport
-dontwarn com.google.api.client.http.javanet.NetHttpTransport$Builder
-dontwarn com.google.api.client.http.javanet.NetHttpTransport
-dontwarn org.joda.time.Instant
