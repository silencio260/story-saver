# RevenueCat Proguard Rules
-keep class com.revenuecat.purchases.** { *; }
-keep class com.revenuecat.purchases.ui.** { *; }
-keep class com.revenuecat.** { *; }

# Prevent obfuscation
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# PostHog Proguard Rules
-keep class com.posthog.flutter.** { *; }
-keep class com.posthog.** { *; }
