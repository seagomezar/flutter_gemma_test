# Flutter Gemma Test App

A Flutter application demonstrating how to integrate and run Google's **Gemma 4 / SmolLM** models entirely locally on-device using the `flutter_gemma` plugin.

## Features
- **Local AI Inference**: Runs Large Language Models (LLMs) completely offline using MediaPipe underneath.
- **Dynamic Chat UI**: A sleek, real-time streaming chat interface with "Thinking" states and user message styling.
- **Background Downloads**: Integrates background and foreground service downloads to pull multi-gigabyte models directly from Hugging Face.

## Requirements & Setup

To run this project on Android, ensure your environment meets the strict requirements of the `flutter_gemma` underlying native libraries.

### Android Environment
This project has been explicitly configured to resolve common build errors with `flutter_gemma`:
- **Compile SDK**: `36`
- **Min SDK**: `24`
- **NDK Version**: `27.0.12077973`
- **Android Gradle Plugin (AGP)**: `8.9.1`

### Required Permissions
The following permissions are configured in `android/app/src/main/AndroidManifest.xml` to support massive model downloads without timing out:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
*(An optional `network_security_config.xml` is also included to bypass local SSL inspection issues on certain corporate networks like Zscaler).*

## How to Run

1. Clone this repository.
2. Run `flutter pub get` to install dependencies.
3. Run the app on a physical device or emulator using `flutter run`.

### Note on Corporate Networks (Zscaler, etc.)
If you are on a corporate network that uses SSL interception (like Zscaler), the automated model download may fail with a `CertPathValidatorException` (Trust anchor not found). If this happens, you will need to either bypass the proxy or manually download the model via browser and push it to the app's internal storage (`/data/user/0/com.example.flutter_gemma_test/app_flutter/`).

## Tech Stack
- **Flutter** & **Dart**
- **[flutter_gemma](https://pub.dev/packages/flutter_gemma)**: Core inference engine.
