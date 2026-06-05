import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _pubspecVersionPattern = RegExp(
  r'^version:\s+(\d+\.\d+\.\d+)\+(\d+)\s*$',
  multiLine: true,
);

void main() {
  test('Android and web identity use the release Korean brand', () {
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
    expect(manifest, contains('android:label="말차례 CalmTurn"'));
    expect(
      manifest,
      contains('android:icon="@drawable/ic_turn_ring_launcher"'),
    );
    expect(mainActivity, contains('package me.newlines.calmturn'));
    expect(webManifest, contains('"name": "말차례 CalmTurn"'));
    expect(webIndex, contains('<title>말차례 CalmTurn</title>'));
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
}
