import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _pubspecVersionPattern = RegExp(
  r'^version:\s+(\d+\.\d+\.\d+)\+(\d+)\s*$',
  multiLine: true,
);

Set<String> _declaredPermissions(String manifest) {
  return RegExp(
    r'<uses-permission\s+[^>]*android:name="([^"]+)"',
  ).allMatches(manifest).map((match) => match.group(1)!).toSet();
}

void main() {
  test('Android and web identity use the v4 Korean brand', () {
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final mainActivity = File(
      'android/app/src/main/kotlin/me/newlines/calmturn/MainActivity.kt',
    ).readAsStringSync();
    final webManifest = File('web/manifest.json').readAsStringSync();
    final webIndex = File('web/index.html').readAsStringSync();

    expect(buildGradle, contains('namespace = "me.newlines.calmturn"'));
    expect(buildGradle, contains('applicationId = "me.newlines.calmturn"'));
    expect(
      buildGradle,
      contains('targetSdk = maxOf(flutter.targetSdkVersion, 35)'),
    );
    expect(buildGradle, contains('key.properties'));
    expect(
      buildGradle,
      isNot(contains('signingConfig = signingConfigs.getByName("debug")')),
    );
    expect(manifest, contains('android:label="시계 (부부싸움 시리즈)"'));
    expect(
      manifest,
      contains('android:icon="@drawable/ic_turn_ring_launcher"'),
    );
    expect(mainActivity, contains('package me.newlines.calmturn'));
    expect(webManifest, contains('"name": "시계 (부부싸움 시리즈)"'));
    expect(webIndex, contains('<title>시계 (부부싸움 시리즈)</title>'));
  });

  test('Android launch art uses the turn ring concept', () {
    final icon = File(
      'android/app/src/main/res/drawable/ic_turn_ring_launcher.xml',
    ).readAsStringSync();
    final launchBackground = File(
      'android/app/src/main/res/drawable/launch_background.xml',
    ).readAsStringSync();

    expect(icon, contains('turn_ring'));
    expect(icon, contains('#2D6A64'));
    expect(icon, contains('#D99C2B'));
    expect(launchBackground, contains('@drawable/ic_turn_ring_launcher'));
  });

  test('release Android manifest excludes v4 out-of-scope permissions', () {
    final releaseManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final debugManifest = File(
      'android/app/src/debug/AndroidManifest.xml',
    ).readAsStringSync();
    final profileManifest = File(
      'android/app/src/profile/AndroidManifest.xml',
    ).readAsStringSync();
    final checklist = File(
      'docs/08_android_launch_checklist.md',
    ).readAsStringSync();
    final policyDraft = File(
      'docs/10_play_policy_drafts.md',
    ).readAsStringSync();
    final releasePermissions = _declaredPermissions(releaseManifest);
    final debugPermissions = _declaredPermissions(debugManifest);
    final profilePermissions = _declaredPermissions(profileManifest);
    final forbiddenReleasePermissions = <String>{
      'android.permission.RECORD_AUDIO',
      'android.permission.CAMERA',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.READ_CONTACTS',
      'android.permission.INTERNET',
    };

    for (final permission in forbiddenReleasePermissions) {
      expect(
        releasePermissions,
        isNot(contains(permission)),
        reason: '$permission must not be declared in the release/main manifest',
      );
    }
    expect(debugPermissions, contains('android.permission.INTERNET'));
    expect(profilePermissions, contains('android.permission.INTERNET'));
    expect(
      checklist,
      contains(
        '자동 검증: `flutter test test/release_identity_test.dart`에서 release/main 매니페스트에 v4 비대상 권한과 `INTERNET`이 없는지, debug/profile 전용 `INTERNET`이 유지되는지 확인한다.',
      ),
    );
    expect(
      policyDraft,
      contains(
        '자동 검증 추가됨: `flutter test test/release_identity_test.dart`가 release AndroidManifest 권한 정책과 debug/profile 전용 `INTERNET` 분리를 확인한다.',
      ),
    );
  });

  test('Android version metadata is delegated to pubspec version plus build', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    final checklist = File(
      'docs/08_android_launch_checklist.md',
    ).readAsStringSync();
    final versionMatch = _pubspecVersionPattern.firstMatch(pubspec);

    expect(versionMatch, isNotNull);
    final versionName = versionMatch!.group(1)!;
    final versionCode = versionMatch.group(2)!;

    expect(int.parse(versionCode), greaterThanOrEqualTo(1));
    expect(buildGradle, contains('versionCode = flutter.versionCode'));
    expect(buildGradle, contains('versionName = flutter.versionName'));
    expect(buildGradle, contains('pubspec.yaml version: x.y.z+build'));
    expect(checklist, contains('현재값: `$versionName+$versionCode`.'));
    expect(
      checklist,
      contains(
        '`versionName`은 `pubspec.yaml`의 `version`에서 `+` 앞의 SemVer(`$versionName`)',
      ),
    );
    expect(
      checklist,
      contains(
        '`versionCode`는 `pubspec.yaml`의 `version`에서 `+` 뒤의 빌드 번호(`$versionCode`)',
      ),
    );
    expect(
      checklist,
      contains('검증: `flutter test test/release_identity_test.dart`'),
    );
  });

  test('v4 docs describe the same turn-limit defaults and presets', () {
    final docs = <String, String>{
      'README.md': File('README.md').readAsStringSync(),
      'docs/09_vibe_coding_prompts.md': File(
        'docs/09_vibe_coding_prompts.md',
      ).readAsStringSync(),
      'docs/12_settings_and_notifications.md': File(
        'docs/12_settings_and_notifications.md',
      ).readAsStringSync(),
    };

    for (final entry in docs.entries) {
      expect(entry.value, contains('턴 제한 기본값은 `30초`'), reason: entry.key);
      expect(
        entry.value,
        contains('턴 제한 프리셋은 `10초 / 30초 / 45초 / 1분`'),
        reason: entry.key,
      );
      expect(entry.value, isNot(contains('턴당 발언 제한시간 기본값은 `3분`')));
      expect(entry.value, isNot(contains('턴 프리셋은 1/3/5/10분')));
    }
  });
}
