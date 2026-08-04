# ClassPing

A weekly class routine reminder app — built to match the original
**ClassPing (CSE-308) proposal** feature-for-feature, styled with the same
glassmorphic look, colors, fonts, and animation language as EDUvian.

Everything runs fully on-device: SQLite for the routine, Android's
AlarmManager (via `flutter_local_notifications`) for reminders. No backend,
no Firebase project, no internet connection required — matching the
proposal's "works offline" objective.

## Feature checklist against the proposal

**Core Features** (from Section 7 of the proposal)

- [x] Routine Input & Management — add / edit / delete a class (subject, day,
      start & end time, room, instructor)
- [x] Automated local push notifications, configurable minutes-before
- [x] Local data persistence via SQLite (`sqflite`), fully offline
- [x] Today's Schedule View — home screen with today's classes + a live
      countdown to the next one
- [x] Recurring weekly scheduling — set a class once, the reminder repeats
      every week on its own (`DateTimeComponents.dayOfWeekAndTime`)
- [x] Permission handling — guided Android 13+ notification permission and
      Android 12+ exact-alarm access, with a status indicator in Settings

**Future Features** (from the proposal — included early where cheap, skipped where not)

- [x] Custom reminder time *per class* (5/10/15/20/30 min), not just one
      global default
- [x] Dark mode — comes near-free from reusing EDUvian's theme (Settings →
      Appearance)
- [ ] iOS build — Flutter is cross-platform by default, but the exact-alarm
      permission code here is Android-specific; iOS notification permission
      flow would need its own small addition
- [ ] Export routine as image/PDF — not started
- [ ] Cloud backup/sync — deliberately **not** added; it's the one thing
      that would compromise "fully offline"

## Why it looks like EDUvian

`app_theme.dart`, `glass_container.dart`, `app_background.dart`,
`glass_app_bar.dart`, `rounded_field.dart`, and `dropdown_field.dart` are
carried over from EDUvian's `lib/core/` essentially unchanged — same maroon
color seed, same glass-panel style, same animated background orbs, same
`Inter`/`Poppins` typography. Everything specific to ClassPing (the SQLite
layer, the notification scheduling, the routine/home/settings screens) is
new, built on top of that shared visual language.

The app icon (`assets/icon/ClassPing-Icon.png`) is a copy of EDUvian's for
now, just as a placeholder so `flutter_launcher_icons` has something to work
with — swap in your own ClassPing artwork before treating this as a final
submission, since it's currently still EDUvian's actual logo.

## Setup

This was written by hand in a sandbox without Flutter installed, so it
hasn't been run through `flutter pub get` / `flutter analyze` / a real
build. Steps to get it running:

1. **Generate the platform folders.** Only `lib/`, `pubspec.yaml`, and
   `assets/` are included — no `android/` or `ios/` yet. From this
   project's root:
   ```
   flutter create --project-name classping --org com.classping .
   ```
   This fills in `android/`, `ios/`, etc. around the existing `lib/` and
   `pubspec.yaml` without touching them.

2. **Add notification permissions to `android/app/src/main/AndroidManifest.xml`.**
   Inside `<manifest>`, above `<application>`:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   <uses-permission android:name="android.permission.VIBRATE"/>
   <uses-permission android:name="android.permission.WAKE_LOCK"/>
   ```
   Inside `<application>`, alongside the existing `<activity>`:
   ```xml
   <receiver android:exported="false"
       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
   <receiver android:exported="false"
       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
     <intent-filter>
       <action android:name="android.intent.action.BOOT_COMPLETED"/>
       <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
       <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
     </intent-filter>
   </receiver>
   ```
   The boot receiver is what lets weekly reminders survive a phone restart —
   Android clears AlarmManager alarms on reboot otherwise.

3. **Bump `minSdk` and enable core library desugoring** in
   `android/app/build.gradle.kts` (needed by `flutter_local_notifications`):
   ```kotlin
   defaultConfig {
       minSdk = 23
       // ...
   }
   compileOptions {
       isCoreLibraryDesugaringEnabled = true
   }
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
   }
   ```

4. **Install packages and run:**
   ```
   flutter pub get
   flutter run
   ```

5. On first launch, go to **Settings → Reminder permissions** and grant
   both the notification and exact-alarm permissions — reminders won't fire
   reliably without them.

### Most likely rough edges

`flutter_local_notifications`, `flutter_timezone`, and `go_router` all move
fast. The two spots most likely to need a one-line fix after `pub get` are
flagged with `NOTE:` comments directly in `notification_service.dart`
(`requestExactAlarmsPermission()` and `getLocalTimezone()`) — if either
doesn't compile, check that package's current API in its pub.dev changelog.

## Architecture

```
lib/
  core/
    theme/        — colors, isDark() (from EDUvian)
    widgets/       — GlassContainer, AppBackground, glass app bar, form fields (from EDUvian)
    database/      — sqflite setup + CRUD
    services/      — local notification scheduling (weekly, exact-alarm)
    router/        — go_router, bottom-tab shell + pushed add/edit routes
  features/
    splash/        — startup screen
    home/          — Today tab: today's classes + countdown
    routine/       — Routine tab: weekly list, add/edit/delete a class
    settings/       — permissions status, default reminder time, theme
    dashboard/     — bottom navigation shell
```
