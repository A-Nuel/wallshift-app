# WallShift

Flutter wallpaper rotation app with a native Android background engine.

Rotates wallpapers on **screen wake**, on a **timed interval** (AlarmManager), and with a **WorkManager** watchdog (15‑minute floor). Survives reboot via `BOOT_COMPLETED`.

## Install (phone-only)

1. Open this repo on GitHub → **Actions** → **Build APK**
2. Open the latest successful run → **Artifacts** → download **wallshift-apk**
3. Unzip if needed → install `app-release.apk` on your Android phone  
   (allow install from browser/files if prompted)

On HyperOS/MIUI (POCO, Redmi, Xiaomi): during onboarding, set **No battery restrictions** and enable **Autostart**, or rotation may stop after idle.

## Build locally

```bash
# Requires Flutter SDK
flutter create --org com.nuel --project-name wallshift -a kotlin -i swift wallshift_local
# Then copy lib/, pubspec.yaml, and android_native Kotlin + manifest as in CI
cd wallshift_local && flutter pub get && flutter run
```

Or push to `main` / run **workflow_dispatch** — CI scaffolds and builds the release APK for you.

## Features

- Pick & reorder images (stored in app documents so they survive reboots)
- Auto-rotate on screen wake + timed backup (5–120 min)
- Home / lock / both targets, shuffle on/off
- Change wallpaper now
- Onboarding for photo access + battery/autostart (HyperOS)
