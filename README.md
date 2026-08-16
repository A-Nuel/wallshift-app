# WallShift — setup

I couldn't run `flutter`/Android SDK tooling in this sandbox (it's not
installed here), so this package has the **app code** but not the
boilerplate `flutter create` normally generates (gradlew, wrapper jar,
default gradle files, launcher icons). You'll generate that boilerplate on
your own machine, then drop this code on top. About 10 minutes.

## 1. Scaffold the project

```bash
flutter create --org com.nuel --project-name wallshift -a kotlin -i swift wallshift_app
```

This gives you a real `android/` folder with a working gradle setup.

## 2. Copy this code in

- Copy everything from this package's `lib/` over the generated `lib/`
  (replace `main.dart`).
- Copy this package's `pubspec.yaml` over the generated one (or merge the
  `dependencies:` block if you changed the org/name).
- Copy every `.kt` file from `android_native/kotlin/` into:
  `android/app/src/main/kotlin/com/nuel/wallshift/`
  (create the folder if `flutter create` used a different package path —
  check `android/app/build.gradle`'s `applicationId` matches `com.nuel.wallshift`,
  or update the `package` line at the top of each `.kt` file to match yours).
- Open `android/app/src/main/AndroidManifest.xml` and merge in everything
  from `android_native/AndroidManifest_ADDITIONS.xml` (permissions as
  children of `<manifest>`, service/receivers as children of `<application>`).

## 3. Add the native WorkManager dependency

The timed backup uses `androidx.work` directly in Kotlin (not the Flutter
workmanager plugin — no need to boot a Flutter engine in the background
just to change a wallpaper). Add to `android/app/build.gradle`:

```gradle
dependencies {
    implementation "androidx.work:work-runtime-ktx:2.9.1"
}
```

Also set, in the same file:

```gradle
android {
    defaultConfig {
        minSdkVersion 23   // needs Marshmallow+ for battery-optimization APIs
    }
}
```

## 4. Install packages and run

```bash
cd wallshift_app
flutter pub get
flutter run
```

## How the rotation actually works

| Trigger | Reliability | Interval |
|---|---|---|
| `ACTION_SCREEN_ON` receiver, registered by a foreground service | High while the service is alive | Every screen wake |
| `AlarmManager` exact-alarm chain (self-rescheduling) | Good, but Doze can delay it under deep sleep | Your chosen interval, min 5 min |
| `WorkManager` periodic job | Best OS-level survival — outlives app kills/reboots once re-enqueued | Every 15 min (Android's hard floor for periodic work) — re-arms the alarm chain and does a guaranteed wallpaper change |
| `BOOT_COMPLETED` receiver | Restarts the service + worker after a restart | — |

So in practice: screen-wake changes are near-instant, the alarm chain
covers the 5-minute cadence you asked for while the phone is reachable,
and WorkManager is the backstop that guarantees a change happens at least
every 15 minutes and repairs the other two layers if the OS killed them.
That 15-minute floor on WorkManager is an Android platform limit, not
something any app can configure around — the alarm chain is doing the real
5-minute work.

## POCO C71 (HyperOS/MIUI) note

The onboarding flow in the app already walks the user through this, but
for reference: HyperOS kills background apps aggressively unless you
manually flip two switches — **Settings → Battery → App battery saver →
WallShift → No restrictions**, and **Security app → Permissions →
Autostart → enable WallShift**. Without both, expect the rotation to stop
after the phone's been idle a while, even with all three trigger layers in
place — that's an OS policy, not something code alone can fully defeat.
