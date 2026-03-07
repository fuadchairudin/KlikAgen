import 'package:flutter_test/flutter_test.dart';
import 'package:klik_agen/main.dart';

import 'package:klik_agen/theme/app_theme.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    final themeNotifier = ThemeNotifier();
    await tester.pumpWidget(KlikAgenApp(themeNotifier: themeNotifier));
    await tester.pumpAndSettle();
    expect(find.text('KlikAgen'), findsOneWidget);
  });
}
