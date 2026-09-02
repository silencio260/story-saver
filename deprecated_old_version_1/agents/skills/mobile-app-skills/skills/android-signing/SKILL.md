---
name: android-signing
description: Guide for generating and configuring the Android release signing key (keystore) and key.properties.
---

# Android Production Signing

This skill documents the process for setting up a production signing key for the Android build. This ensures that the app can be signed for Google Play and other distribution channels using a secure, external configuration.

> [!CAUTION]
> **AI INSTRUCTION**: NEVER run the `keytool` command automatically for the user. It requires interactive password input and critical key management. **Only provide the instructions and commands for the user to run manually.**

## 🔐 Configuration Overview

The project uses a secure `key.properties` file (excluded from Git) to store sensitive signing credentials. The `android/app/build.gradle.kts` file is configured to load these properties at build time.

### 📁 Key Files
| File | Purpose | Git Status |
|---|---|---|
| `~/app_key_stores/app_name/upload-keystore.jks` | The actual binary keystore file (stashed externally). | **EXTERIOR** |
| `android/key.properties` | Credentials (passwords, alias, path). | **EXCLUDED** |
| `android/key.properties.example` | Template for `key.properties`. | Tracked |
| `android/app/build.gradle.kts` | Gradle logic to load the keys. | Tracked |

---

## 🚀 Setup Instructions

### Step 1: Create a Secure Store (Manual)
It is recommended to store your keystores in a dedicated folder outside the project for security:

```bash
mkdir -p ~/app_key_stores/app_name/
```

### Step 2: Generate the Keystore (Manual)
Run this command to create a new keystore:

```bash
keytool -genkey -v -keystore ~/app_key_stores/app_name/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

> [!IMPORTANT]
> **Keep your passwords safe!** Losing the keystore or passwords means you cannot update your app on the Google Play Store.

### Step 3: Create `key.properties`
Copy the example file and fill in your credentials:

```bash
cp android/key.properties.example android/key.properties
```

**Content of `android/key.properties`:**
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/YOUR_USERNAME/app_key_stores/app_name/upload-keystore.jks
```

---

## 🛠️ Gradle Implementation (Reference)

The `android/app/build.gradle.kts` should contain the following logic to load the keys:

```kotlin
// 1. Load properties at the top level
val keystorePropertiesFile = rootProject.projectDir.resolve("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// 2. Define signingConfigs
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    // 3. Apply to release build type
    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // ... rest of config
        }
    }
}
```

---

## 📦 Building the App

Once configured, use the following commands to build signed release versions:

**AAB (Google Play):**
```bash
flutter build appbundle --release
```

**APK (Side-loading/Testing):**
```bash
flutter build apk --release
```

---

## ❌ Common Gotchas & Security

| Issue | Solution |
|---|---|
| **Committed `key.properties`** | Immediately rotate your passwords and remove the file from history using `git filter-repo`. |
| **Missing `key.properties`** | The build will fall back to `debug` signing. Ensure the file exists in `android/` for a production-ready build. |
| **Path Errors** | Ensure `storeFile` is correctly named and located in `android/app/`. |
