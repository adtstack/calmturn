# Clock And History Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the CalmTurn timer flow match the approved direction: landscape-only shrinking clock zones, icon-only timer controls, screen-awake runtime behavior, simplified fair setup, return-to-setup wrap-up, setup entry points for history/settings, and a real calendar-shaped history view.

**Architecture:** Keep the existing Flutter feature boundaries. `SessionSetupPage` owns simple fair defaults, `TimerHomePage` owns active-session display contracts, `WrapUpPage` owns save/discard completion, and `HistoryScreen` owns a month grid calendar. Android keep-awake behavior is exposed through a tiny platform channel used by a Dart timer display controller.

**Tech Stack:** Flutter/Cupertino widgets, widget tests, Android Kotlin `FlutterActivity`, platform method channels, existing in-memory stores.

---

### Task 1: Write Failing Widget Tests For The Requested Flow

**Files:**
- Modify: `test/app/session_settings_flow_test.dart`
- Modify: `test/app/timer_screen_test.dart`
- Modify: `test/app/wrap_up_history_test.dart`
- Modify: `test/app/app_settings_defaults_flow_test.dart`

- [ ] **Step 1: Update setup tests**

Require shared total labels `10분`, `20분`, `30분`, `60분`, turn labels `1분`, `2분`, `3분`, `5분`, no separate participant total controls, and visible setup entry-point keys for history and advanced settings.

- [ ] **Step 2: Update timer tests**

Require icon-only pause/resume/finish controls, a display controller activation/restoration hook, and panel width shrinking to zero when a participant runs out of total time.

- [ ] **Step 3: Update wrap-up/history tests**

Require both save and discard to return to the setup screen, and require history to render a 7-column month grid with weekday headers and dated day cells.

- [ ] **Step 4: Run failing tests**

Run: `flutter test test/app/session_settings_flow_test.dart test/app/timer_screen_test.dart test/app/wrap_up_history_test.dart test/app/app_settings_defaults_flow_test.dart`

Expected: FAIL because production code still has text timer buttons, old setup labels, status-only wrap-up completion, and non-calendar history layout.

### Task 2: Implement Active Timer Display Contracts

**Files:**
- Create: `lib/features/timer/timer_display_controller.dart`
- Modify: `lib/main.dart`
- Modify: `android/app/src/main/kotlin/me/newlines/calmturn/MainActivity.kt`

- [ ] **Step 1: Add timer display controller**

Create a Dart controller that sets landscape orientations and sends `setKeepScreenOn` to channel `calmturn/screen_awake`, ignoring missing-plugin errors for tests/web.

- [ ] **Step 2: Wire controller into `TimerHomePage`**

Activate it when a timer starts, restore it when a timer finishes or the page disposes, and allow tests to inject a recording controller.

- [ ] **Step 3: Add Android keep-screen-on handler**

In `MainActivity`, handle `calmturn/screen_awake` by adding or clearing `WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON` on the UI thread.

- [ ] **Step 4: Replace text controls with icon controls**

Use `CupertinoIcons.pause_solid`, `CupertinoIcons.play_arrow_solid`, and `CupertinoIcons.xmark` with accessible labels/tooltips through semantics, but no visible `일시정지`, `재개`, or `종료` text on the timer surface.

- [ ] **Step 5: Make zero time remove the panel**

Change panel sizing so positive remaining time maps to proportional width and zero remaining time maps to no visible panel, while keeping active content stable during normal countdown.

### Task 3: Implement Simplified Setup And Return-To-Setup Completion

**Files:**
- Modify: `lib/features/settings/session_setup_page.dart`
- Modify: `lib/features/history/wrap_up_page.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Simplify setup presets**

Use fair shared total presets `10분`, `20분`, `30분`, `60분`, direct minute input, and turn presets `1분`, `2분`, `3분`, `5분`, direct minute input.

- [ ] **Step 2: Keep setup entry points visible**

Put history and advanced settings actions on the setup screen with stable keys: `history-button` and `advanced-settings-button`.

- [ ] **Step 3: Normalize setup draft to fair totals**

When setup opens, coerce defaults to `TotalTimeMode.same` so separate participant total settings do not appear on the first screen.

- [ ] **Step 4: Return after save/discard**

After `WrapUpPage` saves or discards, call the root callback so `_sessionConfig` becomes `null` and the setup screen is shown again.

### Task 4: Implement Calendar-Shaped History

**Files:**
- Modify: `lib/features/history/history_screen.dart`

- [ ] **Step 1: Build current-month calendar weeks**

Group records by day and render weekday headers plus six or fewer week rows in seven equal columns.

- [ ] **Step 2: Add day-cell keys and outcome marks**

Use keys like `history-day-2026-06-06`, show up to three recent marks in a cell, and open the existing day detail screen when a populated day is tapped.

- [ ] **Step 3: Preserve empty/loading states**

Keep loading and empty messages, but show the calendar frame whenever records exist.

### Task 5: Verify

**Files:**
- All modified files

- [ ] **Step 1: Run focused tests**

Run: `flutter test test/app/session_settings_flow_test.dart test/app/timer_screen_test.dart test/app/wrap_up_history_test.dart test/app/app_settings_defaults_flow_test.dart`

- [ ] **Step 2: Run full validation**

Run: `./tool/check.sh`

- [ ] **Step 3: Run browser visual check**

Start the Flutter web app, inspect setup, timer, and history in the in-app browser, and take screenshots for the final report if the app runs successfully.
