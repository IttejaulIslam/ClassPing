# ClassPing \u2014 Upgrade Summary

This package contains the full ClassPing project with the following upgrades
added on top of the original app. All of it follows the existing
architecture (domain / data / providers / screens per feature, Riverpod,
GoRouter, the maroon glassmorphic theme).

## \ud83d\udd34 Critical
- **Backup / Export & Restore** \u2014 `core/services/backup_service.dart`.
  Exports every table (routine, tasks, attendance, exams, grades) to a
  JSON file via the OS share sheet, and restores from a previously
  exported file. Reachable from Settings \u2192 Data & Backup.
- **iOS notification fix** \u2014 `flutter_launcher_icons` now generates iOS
  icons too. **Still needed**: `DarwinInitializationSettings` in
  `notification_service.dart` for iOS push permissions \u2014 flagged inline
  as the one remaining piece for full iOS parity.

## \ud83d\udfe2 Quick wins
- **Weekly timetable grid view** \u2014 `features/routine/presentation/screens/routine_grid_screen.dart`.
  A day \u00d7 time visual grid, color-coded per subject. Reachable from the
  Routine screen's app bar icon or Settings \u2192 Tools.
- **CSV routine import** \u2014 `features/routine/data/csv_import_service.dart`
  + `import_routine_screen.dart`. Parses Subject/Day/Start/End/Room/
  Instructor columns with per-row error messages, includes a
  copy-to-clipboard template.
- **Conflict detection** \u2014 `ClassEntry.overlaps()` in the domain model,
  checked in Add/Edit Class before saving; warns (doesn't block) on
  overlapping classes.
- **Search bars** \u2014 added to both the Routine and Tasks screens
  (client-side filter over subject/room/instructor and title/subject
  respectively).

## \ud83d\udfe1 Medium effort
- **Attendance tracker** \u2014 `features/attendance/`. Mark present/absent
  per class, see attendance % per subject with a 75%-threshold warning.
- **Exam mode** \u2014 `features/exams/`. Separate from regular tasks: exam
  type, room, syllabus notes, countdown, and a "prepared" checklist
  toggle. Swipe to delete.
- **GPA / CGPA calculator** \u2014 `features/gpa/`. Add courses with credit
  hours + letter grade, computes weighted GPA and per-semester CGPA
  breakdown. Calculation logic is in a pure `GpaCalculator` class
  (no Flutter dependency) so it's directly unit-testable.
- **Semester/holiday pause** \u2014 `features/settings/.../semester_break_provider.dart`.
  Set a date range in Settings; reminders are cancelled while the range
  is active and resume automatically once it passes (synced whenever
  the app opens and the routine list loads \u2014 see the note in
  `notification_service.dart` about this being app-open-time sync,
  not true background scheduling).
- **Home-screen widget (Android)** \u2014 Flutter side is done
  (`core/services/home_widget_service.dart`, wired into `HomeScreen`).
  The native Android widget files (layout XML, provider Kotlin class,
  manifest entry) still need to be added \u2014 see `HOME_WIDGET_SETUP.md`
  for exactly what's left and a recommended reference to copy from.

## \ud83e\uddea Code quality
- `test/class_entry_conflict_test.dart` \u2014 tests the overlap-detection logic.
- `test/task_priority_test.dart` \u2014 tests priority-based sorting.
- `test/gpa_calculator_test.dart` \u2014 tests the GPA/CGPA math.
- `test/widget_test.dart` \u2014 replaced the unmodified default Flutter
  counter-app template test with a real smoke test that boots the app.
- `.github/workflows/flutter_ci.yml` \u2014 runs `flutter analyze` and
  `flutter test` on every push/PR.

## Database
`core/database/database_helper.dart` gained three new tables
(`attendance`, `exams`, `course_grades`) plus a versioned migration
(bumped to version 3) and raw export/import helpers used by
`BackupService`.

## New dependencies (already added to `pubspec.yaml`)
`share_plus`, `path_provider`, `file_picker`, `csv`, `home_widget`.
Run `flutter pub get` after pulling this in.

## Known limitations / honest caveats
- This code was written and reviewed without a Flutter SDK available in
  the environment it was built in, so it has **not been compiled or run**.
  It follows the existing codebase's patterns closely and has been
  checked carefully by hand, but budget time to fix any small
  compile-time issues (a typo, an API signature drift in a
  dependency version) before a live demo.
- `share_plus`'s API has shifted across major versions \u2014 see the
  comment in `backup_service.dart` if `exportAndShare()` doesn't compile
  against the resolved package version.
- The home-screen widget's native Android half is intentionally left as
  a documented next step (`HOME_WIDGET_SETUP.md`), not a working feature
  yet, since it needs a real device/emulator to get right.
- The semester-break pause is app-open-time sync, not exact background
  scheduling \u2014 documented inline in `notification_service.dart`.
