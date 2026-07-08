import 'package:emirates_wash/main.dart';
import 'package:emirates_wash/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on the splash flow', (tester) async {
    await tester.pumpWidget(const EmiratesWashApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
