import 'package:bay_wash/widgets/smooth_press.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smooth press scales down and invokes its callback',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Center(
            child: SmoothPress(
              onTap: () => taps++,
              child: const SizedBox(
                key: Key('press-target'),
                width: 80,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('press-target'))),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0.975);

    await gesture.up();
    await tester.pump();

    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });
}
