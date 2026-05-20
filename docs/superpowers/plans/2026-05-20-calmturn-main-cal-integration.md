# CalmTurn Main CAL Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the completed CAL-5, CAL-6, and CAL-7 CalmTurn feature stack into the current Android-scaffolded `main` branch, preserving the intended product behavior and keeping Android/web builds verifiable.

**Architecture:** Create an integration branch from `main`, merge the top feature branch `cal-7-v0.4-wrapup-history`, and resolve conflicts by responsibility. Android platform files and launch-readiness docs come from `main`; Flutter app behavior, tests, local-only history, and neutral wrap-up language come from the CAL feature stack.

**Tech Stack:** Flutter, Dart, Cupertino widgets, Flutter widget tests, pure-Dart model tests, Android Gradle Kotlin DSL, local web storage through conditional imports.

---

## Current Verified State

Repository root: `/Users/int/ZManagedProjects/Tool/malcharye`

`main` currently points to `db00647 Add Android build scaffold`.

The completed feature stack is already linear:

```text
1234855 Implement v0.4 wrap-up history
c682fc2 Address timer review feedback
5fbe771 Implement v0.3 timer screen
62fb8b6 Implement v0.2 session settings flow
```

The feature stack branches from `6f80564 Add Flutter web build scaffold`; `main` adds Android platform files and Android launch-readiness documentation after that point.

## Merge Intent

Use this conflict policy:

| Area | Winning Intent |
|---|---|
| `android/**` | Keep `main`; it contains the generated Android scaffold needed for Android Studio and APK/AAB builds. |
| `.metadata` | Keep `main`; it is part of the generated Flutter Android project state currently present in `main`. |
| `docs/08_android_launch_checklist.md` | Keep `main`; it records the current Android scaffold caveats and release gates. |
| `README.md` and product docs | Preserve Android-first launch wording from `main`; keep any CAL feature wording only when it describes completed v0.2-v0.4 behavior. |
| `lib/**` | Prefer `cal-7-v0.4-wrapup-history`; it contains the intended settings, timer, feedback, wrap-up, and local-history app experience. |
| `test/**` | Prefer `cal-7-v0.4-wrapup-history`; it contains the regression suite for v0.2-v0.4. |
| `pubspec.yaml` | Keep the CAL stack addition of `dev_dependencies: flutter_test`, while keeping no third-party persistence dependency. |
| `tool/check.sh` | Prefer CAL stack; it runs timer, settings, history, widget tests, and web build. |
| `lib/features/timer/domain/timer_models.dart` | Keep the CAL-7 split: history records live in `lib/features/history/`, not in timer domain models. |
| Wrap-up/history copy | Keep `대화 기록` intent: no winner/loser framing, local-only storage, no added persistence package. |
| Timer screen behavior | Keep the CAL-6 review fix: honor `showOvertime` and do not show a dead `Resume` action after auto-pause when resume cannot work. |

## File Structure

These paths should exist after integration:

- `/Users/int/ZManagedProjects/Tool/malcharye/android/app/build.gradle.kts` keeps the current Android scaffold with temporary `com.example.calmturn` identifiers.
- `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/AndroidManifest.xml` keeps launcher metadata and `CalmTurn` temporary app label.
- `/Users/int/ZManagedProjects/Tool/malcharye/docs/08_android_launch_checklist.md` remains the release-readiness gate.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/settings/session_settings.dart` owns settings draft to `SessionConfig` mapping.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/settings/session_setup_page.dart` owns setup and consent UI.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/timer/timer_feedback.dart` owns visual/sound/haptic feedback decisions through an adapter.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record.dart` owns dependency-free history models.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_store.dart` owns JSON record persistence interface and store.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_storage_io.dart` owns file-backed IO storage.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_storage_web.dart` owns `window.localStorage` web storage.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_storage_stub.dart` owns in-memory fallback storage.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/wrap_up_page.dart` owns wrap-up UI and saved record list.
- `/Users/int/ZManagedProjects/Tool/malcharye/lib/main.dart` wires setup, consent, timer, break, time extension, and wrap-up flow.
- `/Users/int/ZManagedProjects/Tool/malcharye/tool/check.sh` is the single verification gate.

## Task 1: Create The Integration Branch

**Files:**
- Modify: none

- [ ] **Step 1: Confirm clean starting state**

Run:

```bash
cd /Users/int/ZManagedProjects/Tool/malcharye
git status --short --branch
git worktree list
git log --graph --oneline --decorate --all -n 20
```

Expected:

```text
## main...origin/main
```

The worktree list should show `main`, `cal-5-v0.2-settings`, `cal-6-v0.3-timer-screen`, and `cal-7-v0.4-wrapup-history`.

- [ ] **Step 2: Create the integration branch from current main**

Run:

```bash
git switch -c codex/calmturn-main-cal-integration main
git status --short --branch
```

Expected:

```text
## codex/calmturn-main-cal-integration
```

- [ ] **Step 3: Commit checkpoint**

Do not create a commit in this step. The new branch is the checkpoint.

## Task 2: Preview The Merge

**Files:**
- Read: `/Users/int/ZManagedProjects/Tool/malcharye/README.md`
- Read: `/Users/int/ZManagedProjects/Tool/malcharye/docs/08_android_launch_checklist.md`
- Read: `/Users/int/ZManagedProjects/Tool/malcharye/pubspec.yaml`
- Read: `/Users/int/ZManagedProjects/Tool/malcharye/tool/check.sh`

- [ ] **Step 1: Compare what main added after the shared base**

Run:

```bash
git diff --name-status 6f80564..main
```

Expected important paths:

```text
A	android/app/build.gradle.kts
A	android/app/src/main/AndroidManifest.xml
R052	docs/08_ios_launch_checklist.md	docs/08_android_launch_checklist.md
```

- [ ] **Step 2: Compare what CAL-7 adds after the shared base**

Run:

```bash
git diff --name-status 6f80564..cal-7-v0.4-wrapup-history
```

Expected important paths:

```text
A	lib/features/settings/session_settings.dart
A	lib/features/settings/session_setup_page.dart
A	lib/features/timer/timer_feedback.dart
A	lib/features/history/session_record.dart
A	lib/features/history/session_record_store.dart
A	lib/features/history/wrap_up_page.dart
M	lib/main.dart
M	pubspec.yaml
M	tool/check.sh
```

- [ ] **Step 3: Generate a read-only merge preview**

Run:

```bash
git merge-tree 6f80564 main cal-7-v0.4-wrapup-history > /private/tmp/calmturn-merge-preview.txt
rg -n "<<<<<<<|=======|>>>>>>>|CONFLICT" /private/tmp/calmturn-merge-preview.txt
```

Expected:

```text
```

No output from `rg` means the preview has no textual conflict markers.

## Task 3: Merge The CAL Feature Stack

**Files:**
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/pubspec.yaml`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/pubspec.lock`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/tool/check.sh`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/lib/main.dart`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/timer/domain/timer_engine.dart`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/timer/domain/timer_models.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/settings/session_settings.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/settings/session_setup_page.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/timer/timer_feedback.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_store.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_storage_io.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_storage_web.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_storage_stub.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/wrap_up_page.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/test/app/session_settings_flow_test.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/test/app/timer_screen_test.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/test/app/wrap_up_history_test.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/test/history/session_record_test.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/test/history/session_record_store_test.dart`
- Create: `/Users/int/ZManagedProjects/Tool/malcharye/test/settings/session_settings_test.dart`

- [ ] **Step 1: Merge the top feature branch**

Run:

```bash
git merge --no-ff cal-7-v0.4-wrapup-history -m "Merge CalmTurn v0.4 feature stack into Android scaffold"
```

Expected no-conflict result:

```text
Merge made by the 'ort' strategy.
```

- [ ] **Step 2: If Git reports conflicts, list them**

Run:

```bash
git diff --name-only --diff-filter=U
```

Expected conflict-handling result after the list is resolved:

```text
```

- [ ] **Step 3: Resolve `pubspec.yaml` by keeping Flutter tests**

The integrated `pubspec.yaml` must contain exactly this dependency shape:

```yaml
dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: false
```

This keeps the CAL widget tests and avoids new persistence packages.

- [ ] **Step 4: Resolve `tool/check.sh` by keeping the full CAL verification gate**

The integrated `tool/check.sh` command sequence must contain these checks in this order:

```bash
flutter pub get
flutter analyze
dart run test/timer/timer_engine_test.dart
dart run test/settings/session_settings_test.dart
dart run test/history/session_record_test.dart
dart run test/history/session_record_store_test.dart
flutter test test/app/session_settings_flow_test.dart
flutter test test/app/timer_screen_test.dart
flutter test test/app/wrap_up_history_test.dart
flutter build web --no-pub
```

- [ ] **Step 5: Resolve conditional storage imports by preserving platform-local storage**

The integrated `/Users/int/ZManagedProjects/Tool/malcharye/lib/features/history/session_record_store.dart` must keep this conditional import:

```dart
import 'session_record_storage_stub.dart'
    if (dart.library.io) 'session_record_storage_io.dart'
    if (dart.library.js_interop) 'session_record_storage_web.dart'
    as platform;
```

- [ ] **Step 6: Preserve Android scaffold files from main**

After conflict resolution, these files must still exist:

```text
android/app/build.gradle.kts
android/app/src/main/AndroidManifest.xml
android/app/src/main/kotlin/com/example/calmturn/MainActivity.kt
android/settings.gradle.kts
docs/08_android_launch_checklist.md
```

Run:

```bash
test -f android/app/build.gradle.kts
test -f android/app/src/main/AndroidManifest.xml
test -f android/app/src/main/kotlin/com/example/calmturn/MainActivity.kt
test -f android/settings.gradle.kts
test -f docs/08_android_launch_checklist.md
```

Expected:

```text
```

- [ ] **Step 7: Finish conflicted merge if needed**

Run:

```bash
git status --short
git add pubspec.yaml pubspec.lock tool/check.sh lib test android docs README.md .metadata
git status --short
git commit --no-edit
```

Expected after commit:

```text
```

If the merge completed without conflicts in Step 1, skip Step 7.

## Task 4: Verify App Behavior And Tests

**Files:**
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/timer/timer_engine_test.dart`
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/settings/session_settings_test.dart`
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/history/session_record_test.dart`
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/history/session_record_store_test.dart`
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/app/session_settings_flow_test.dart`
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/app/timer_screen_test.dart`
- Test: `/Users/int/ZManagedProjects/Tool/malcharye/test/app/wrap_up_history_test.dart`

- [ ] **Step 1: Run the full project check**

Run:

```bash
PUB_CACHE=.pub-cache ./tool/check.sh
```

Expected:

```text
No issues found!
```

The pure-Dart tests should print `PASS` lines. The Flutter widget tests should pass. The web build should finish with a success message.

- [ ] **Step 2: If widget tests fail around auto-pause, confirm the CAL-6 fix survived**

Run:

```bash
rg -n "showOvertime|Resume|autoPause|_resumePhase" lib test
```

Expected:

```text
```

The output should show that `showOvertime` is used by the timer UI/feedback path and that auto-pause does not expose a resume action that cannot work.

- [ ] **Step 3: If history tests fail on storage, confirm no persistence package was added**

Run:

```bash
rg -n "shared_preferences|hive|sqflite|isar|drift" pubspec.yaml lib
```

Expected:

```text
```

No output means history is still local-only through existing Dart and web APIs.

## Task 5: Verify Android Build Survives The Merge

**Files:**
- Read: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/build.gradle.kts`
- Read: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Refresh packages through the project cache**

Run:

```bash
PUB_CACHE=.pub-cache flutter pub get
```

Expected:

```text
Resolving dependencies...
```

- [ ] **Step 2: Build a debug APK**

Run:

```bash
flutter build apk --debug --no-pub
```

Expected artifact:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

- [ ] **Step 3: Build the current release APK**

Run:

```bash
flutter build apk --release --no-pub
```

Expected artifact:

```text
build/app/outputs/flutter-apk/app-release.apk
```

This release APK is only a buildability check because the current Android scaffold still uses temporary app identifiers and debug signing for release builds.

- [ ] **Step 4: Build the current release app bundle**

Run:

```bash
flutter build appbundle --release --no-pub
```

Expected artifact:

```text
build/app/outputs/bundle/release/app-release.aab
```

This AAB is a readiness smoke test, not the Play upload candidate.

## Task 6: Commit The Integrated State

**Files:**
- Modify: integration result from Tasks 3-5

- [ ] **Step 1: Review the final diff**

Run:

```bash
git status --short --branch
git diff --stat main...HEAD
git diff --check
```

Expected:

```text
```

`git diff --check` should produce no output.

- [ ] **Step 2: Commit if the merge did not already create the final commit**

Run:

```bash
git status --short
git add .
git commit -m "Integrate CalmTurn feature stack with Android scaffold"
```

Expected:

```text
```

If Task 3 already created the merge commit and no additional fixes were needed, skip this commit step.

- [ ] **Step 3: Keep the branch ready for review**

Run:

```bash
git log --oneline --decorate -n 8
git status --short --branch
```

Expected:

```text
## codex/calmturn-main-cal-integration
```

## Task 7: Start v0.5 Android Readiness After Integration

**Files:**
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/docs/08_android_launch_checklist.md`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/build.gradle.kts`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/AndroidManifest.xml`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/kotlin/com/example/calmturn/MainActivity.kt`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- Modify: `/Users/int/ZManagedProjects/Tool/malcharye/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

- [ ] **Step 1: Create a separate readiness branch after integration passes**

Run:

```bash
git switch -c codex/calmturn-android-v0.5-readiness
```

Expected:

```text
Switched to a new branch 'codex/calmturn-android-v0.5-readiness'
```

- [ ] **Step 2: Keep irreversible Play identity decisions explicit**

Before editing Application ID, confirm the final value in writing. The documented candidates are:

```text
pro.thirdb.malcharye
pro.thirdb.calmturn
```

Do not upload or label an AAB as Play-ready while the app still uses:

```text
com.example.calmturn
```

- [ ] **Step 3: Run the launch checklist as a device-readiness gate**

Use `/Users/int/ZManagedProjects/Tool/malcharye/docs/08_android_launch_checklist.md` as the gate and verify these items in order:

```text
Application ID
Android namespace
Kotlin MainActivity package path
App display name
Launcher icon
Splash screen
Release signing
versionCode and versionName rule
minSdk and targetSdk
Android SDK command-line tools
Android SDK licenses
Real-device vibration, sound, and visual alert behavior
Permission list
Privacy policy URL
Support URL
Google Play Data safety answers
Direct APK install before internal testing track upload
```

## Self-Review

Spec coverage:

- CAL-5 is covered by merging `62fb8b6` through the top CAL-7 branch and verifying settings tests.
- CAL-6 is covered by merging `c682fc2` through the top CAL-7 branch and verifying timer screen tests.
- CAL-7 is covered by merging `1234855` and verifying history and wrap-up tests.
- Android scaffold survival is covered by preserving `android/**`, `docs/08_android_launch_checklist.md`, and APK/AAB build checks.
- v0.5 is treated as a branch after integration because Application ID, release signing, and Play identity decisions should not be silently made during a merge.

Placeholder scan:

- No placeholder commands are required to complete Tasks 1-6.
- The v0.5 branch has one explicit decision gate: Application ID must be confirmed before editing permanent package identity.

Type consistency:

- `SessionConfig`, `OvertimeConfig`, `PenaltyConfig`, and `AlertConfig` stay in timer domain models.
- `SessionRecord`, `SessionConfigSnapshot`, and `ParticipantResult` stay in the history feature.
- `JsonSessionRecordStore.local()` remains the app-facing local store factory.
