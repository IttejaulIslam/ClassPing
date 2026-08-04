# Home-Screen Widget \u2014 Setup Notes

The Dart/Flutter side of the "next class" home-screen widget is already
wired up:

- `lib/core/services/home_widget_service.dart` pushes the next class +
  pending task count to native storage via the `home_widget` package.
- `HomeScreen` calls it automatically on every rebuild.

**What's still needed** (native Android files this environment can't
build or test, since there's no Android SDK/emulator here):

1. `android/app/src/main/res/layout/classping_widget.xml`
   The widget's visual layout (a small card showing subject + time).

2. `android/app/src/main/res/xml/classping_widget_info.xml`
   Widget metadata \u2014 min size, resize mode, update period, and which
   layout to use initially.

3. `android/app/src/main/kotlin/<your_package_path>/ClassPingWidgetProvider.kt`
   An `AppWidgetProvider` subclass that reads the values
   `HomeWidgetService` saves (`next_class_title`, `next_class_time`,
   `pending_tasks_count`) and populates the layout's `RemoteViews`.

4. A `<receiver>` entry for that provider inside
   `android/app/src/main/AndroidManifest.xml`, pointing at the
   `classping_widget_info.xml` metadata.

**Recommended path:** clone the `home_widget` package's own example app
(linked from its pub.dev page) and copy its four widget files as a
starting point, then swap in ClassPing's app name, colors
(`primaryColor` / `secondaryColor` from `app_theme.dart`), and the three
data keys above. Getting AppWidgetProvider XML exactly right is mostly
trial-and-error on a real device/emulator, so treat the example app as
the known-working reference rather than writing these from scratch.

Once wired, `flutter pub get` + a rebuild + long-pressing the home
screen \u2192 Widgets \u2192 ClassPing should let you place it.
