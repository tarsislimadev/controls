# GEMINI.md

## Project Overview

This is a Flutter-based mobile application that functions as a TV remote control by utilizing the device's infrared (IR) sensor. The application, named `tv_ir_remote`, is designed to send pre-defined IR codes for basic TV functions like power on/off and volume control. It uses the `ir_sensor_plugin` to interact with the device's IR hardware.

The project is structured as a standard Flutter application, with support for Android, iOS, and other platforms.

## Building and Running

### Prerequisites

- Flutter SDK
- Android SDK (for Android builds)
- Xcode (for iOS builds)

### Running the application

1.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
2.  **Run the app:**
    ```bash
    flutter run
    ```

### Building for release

The project includes a GitHub Actions workflow for building and releasing an Android APK. The build command is:

```bash
flutter build apk --release
```

## Development Conventions

The project follows the recommended linting rules from the `flutter_lints` package, as defined in `analysis_options.yaml`. This encourages good coding practices and a consistent code style.
