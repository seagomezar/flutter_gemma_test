# Flutter Gemma Test App

A Flutter application demonstrating how to integrate and run Google's **Gemma 4 ** models entirely locally on-device using the `flutter_gemma` plugin.

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

## How to Run

1. Clone this repository.
2. Run `flutter pub get` to install dependencies.
3. Run the app on a physical device or emulator using `flutter run`.

## Tech Stack
- **Flutter** & **Dart**
- **[flutter_gemma](https://pub.dev/packages/flutter_gemma)**: Core inference engine.
