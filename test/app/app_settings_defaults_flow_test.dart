import 'package:calmturn/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app settings defaults are applied to the next session setup', (
    tester,
  ) async {
    await tester.pumpWidget(const CalmTurnApp());

    await _tapText(tester, 'App settings');
    expect(find.text('App Settings'), findsOneWidget);

    await _tapText(tester, '10 min each');
    await _tapText(tester, 'Turn 90 sec');
    await _tapText(tester, 'Sound');
    await _tapText(tester, 'Save settings');

    expect(find.text('Settings saved for the next session.'), findsOneWidget);
    await _tapText(tester, 'Back to setup');

    await _tapText(tester, 'Review rules');

    expect(find.text('Speaker A total: 10:00'), findsOneWidget);
    expect(find.text('Speaker B total: 10:00'), findsOneWidget);
    expect(find.text('Turn limit: 1:30'), findsOneWidget);
    expect(find.text('Alerts: Screen + Sound + Vibration'), findsOneWidget);
  });
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final baseFinder = find.text(text);
  for (
    var attempt = 0;
    attempt < 8 && baseFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(baseFinder.last);
  await tester.pumpAndSettle();
  await tester.tap(baseFinder.last);
  await tester.pumpAndSettle();
}
