#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export PUB_CACHE="${PUB_CACHE:-.pub-cache}"

flutter pub get
flutter analyze
dart run test/timer/timer_engine_test.dart
dart run test/settings/session_settings_test.dart
dart run test/settings/app_settings_test.dart
dart run test/history/session_record_test.dart
dart run test/history/session_record_store_test.dart
flutter test test/app/app_settings_defaults_flow_test.dart
flutter test test/app/session_settings_flow_test.dart
flutter test test/app/timer_screen_test.dart
flutter test test/app/wrap_up_history_test.dart
flutter build web --no-pub
