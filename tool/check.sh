#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export PUB_CACHE="${PUB_CACHE:-.pub-cache}"

flutter pub get
flutter analyze
dart run test/timer/timer_engine_test.dart
dart run test/settings/session_settings_test.dart
flutter test test/app/session_settings_flow_test.dart
flutter build web --no-pub
