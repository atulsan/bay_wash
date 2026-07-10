import 'package:bay_wash/main.dart';
import 'package:bay_wash/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on the splash flow', (tester) async {
    await tester.pumpWidget(const BayWashApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
