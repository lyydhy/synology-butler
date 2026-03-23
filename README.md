# Synology Butler / 群晖管家

A Flutter-based mobile client for **Synology DSM 7+**, focused on a modern mobile experience for common NAS operations such as system overview, file access, downloads, and package management.

> Current codename: `syno_keeper`

## Highlights

- DSM 7+ oriented architecture
- Clean layered project structure
- Riverpod-based state management
- Synology authentication and session persistence
- Dashboard with system overview and realtime recovery flow
- File Station integration
- Download Station integration
- Package Center foundation
- Android CI workflow and release build optimization

## Project Structure

```text
lib/
├── app/                 # app bootstrap, router, theme
├── core/                # shared infra: errors, network, storage, utils
├── data/                # DSM APIs, models, repository implementations
├── domain/              # entities + repository contracts
├── features/            # feature-oriented presentation layer
├── l10n/                # localization
└── main.dart            # app entry
```

## Current Features

### Authentication
- DSM login
- Saved server switching
- Session persistence
- SynoToken refresh path
- Realtime session refresh fallback

### Dashboard
- System overview
- CPU / memory / storage cards
- Uptime display
- Realtime utilization fallback and recovery handling
- Home entry for Package Center

### Files
- Share / folder listing
- File preview basics
- Text editor
- Upload / download foundation
- Create folder / rename / delete / share link

### Downloads
- Download Station task list
- Create / pause / resume / delete tasks

### Package Center
- Package list
- Installed / updatable filtering
- Package detail page
- Start / stop / uninstall actions
- Install / update flow foundation
- Volume selection
- Queue impact confirmation

## Android Build Notes

Android release-related configuration has been added:

- R8 / ProGuard enabled for release
- Resource shrinking enabled
- ABI split build supported
- Dart obfuscation output supported
- Mapping / symbols artifact retention supported

Related files:

- `android/app/build.gradle.kts`
- `android/app/proguard-rules.pro`
- `docs/android-build.md`

## GitHub Actions

GitHub CI workflows are included:

- `.github/workflows/android-release.yml`
- `.github/workflows/pr-check.yml`

Current behavior:
- PR check runs `flutter analyze`
- Android release workflow currently only builds and uploads APK artifacts
- Analyze is configured as **non-blocking** for now, to avoid existing lint debt from blocking release artifacts

See also:
- `docs/github-actions.md`

## Local Development

Use your local Flutter environment:

```bash
flutter pub get
flutter analyze
flutter run
```

If you are using the OpenClaw-hosted Flutter SDK path from this workspace environment:

```bash
/root/.openclaw/projectEnv/flutter-sdk/bin/flutter pub get
/root/.openclaw/projectEnv/flutter-sdk/bin/flutter analyze
/root/.openclaw/projectEnv/flutter-sdk/bin/flutter run
```

## Release Build Examples

### APK (split per ABI)
```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

### AAB
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

## Current Limitations

- Formal Android release signing is not configured yet
- Application ID is still placeholder-style and should be finalized before public distribution
- Some advanced DSM flows still need real-device and real-server validation
- Package Center is already usable as a first version, but still needs deeper production hardening

## Recommended Next Steps

1. Finalize Android signing config
2. Replace placeholder package name / namespace
3. Validate package install/update flows against real DSM servers
4. Expand common token-refresh recovery beyond dashboard-only paths
5. Continue cleaning remaining lint / polish items until `flutter analyze` is fully clean

## License / Status

This repository is currently in active product iteration and should be treated as a working codebase rather than a finalized public SDK.
