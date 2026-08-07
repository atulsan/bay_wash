import 'package:bay_wash/data/dummy_data.dart';
import 'package:bay_wash/l10n/app_localizations.dart';
import 'package:bay_wash/models/app_booking.dart';
import 'package:bay_wash/models/payment_commission.dart';
import 'package:bay_wash/screens/admin_commission_dashboard_screen.dart';
import 'package:bay_wash/screens/login_screen.dart';
import 'package:bay_wash/screens/payment_screen.dart';
import 'package:bay_wash/screens/portal_selection_screen.dart';
import 'package:bay_wash/screens/vendor/vendor_queue_screen.dart';
import 'package:bay_wash/services/payment_commission_store.dart';
import 'package:bay_wash/theme/app_theme.dart';
import 'package:bay_wash/utils/vendor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp(Widget home) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: home,
      );

  testWidgets('compact portal layout exposes secured corporate sign-in',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(const PortalSelectionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ADNOC Corporate Dashboard'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppTheme.bayTeal);
    expect(scaffold.extendBody, isTrue);
    final systemUi = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(systemUi.value.systemNavigationBarColor, AppTheme.bayTeal);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ADNOC Corporate Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('ADNOC Corporate Sign In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer checkout offers all three payment models',
      (tester) async {
    await tester.pumpWidget(
      testApp(PaymentScreen(wash: dummyCarWashes.first)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('7:00 AM'));
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Pay full online'), findsOneWidget);
    expect(find.text('Pay deposit'), findsOneWidget);
    expect(find.text('Pay at station'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corporate dashboard renders offline commission and audit data',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PaymentCommissionStore.instance;
    addTearDown(store.clear);
    store.clear();
    store.registerJob(
      jobId: 'BW-ADMIN-1',
      stationId: 'adnoc_dxb_demo',
      vendorId: 'adnoc',
      token: 'BW-ADMIN-1',
      origin: JobOrigin.appLiveQueue,
      serviceName: 'Standard',
      serviceAmount: 60,
      paymentPlan: PaymentPlan.payAtStation,
      paymentChannel: PaymentChannel.unrecorded,
      amountPaid: 0,
    );
    store.verifyArrival('BW-ADMIN-1', ArrivalVerificationMethod.otp);
    store.startService('BW-ADMIN-1');
    store.closeCompletedJob(
      jobId: 'BW-ADMIN-1',
      finalServiceAmount: 60,
      discountAmount: 0,
      paymentChannel: PaymentChannel.cash,
    );

    await tester.pumpWidget(
      testApp(const AdminCommissionDashboardScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Corporate payments'), findsOneWidget);
    expect(find.text('AED 6.00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Pending from vendor'),
      300,
    );
    expect(find.textContaining('Pending from vendor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vendor completion opens mandatory transaction closure',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = VendorState.instance;
    addTearDown(state.resetDemoOperations);
    state.resetDemoOperations();
    final booking = AppBooking.walkIn(
      wash: dummyCarWashes.first,
      packageName: 'Standard wash',
      price: 60,
      interiorCleaningNeeded: true,
      paymentPlan: PaymentPlan.payAtStation,
      paymentChannel: PaymentChannel.unrecorded,
      amountPaid: 0,
    );
    state.addAppBooking(booking);
    final car = state.carByJobId(booking.reference)!;
    state.verifyArrival(car.id, ArrivalVerificationMethod.otp);
    state.assignCarToBay(car.id, 'B1');

    await tester.pumpWidget(testApp(const VendorQueueScreen()));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Mark complete').last, 250);
    await tester.tap(find.text('Mark complete').last);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Close transaction'), findsOneWidget);
    expect(find.text('FINAL SERVICE AMOUNT'), findsOneWidget);
    expect(find.text('Close job and secure commission'), findsOneWidget);
    expect(tester.takeException(), isNull);
    state.stopTimerForTesting();
  });
}
