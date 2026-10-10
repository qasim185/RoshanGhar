import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roshanghar/app_state.dart';
import 'package:roshanghar/main.dart';
import 'package:roshanghar/screens/battery_sizer_screen.dart';
import 'package:roshanghar/screens/home_screen.dart';
import 'package:roshanghar/screens/inverter_checker_screen.dart';
import 'package:roshanghar/screens/load_calculator_screen.dart';
import 'package:roshanghar/screens/panel_sizer_screen.dart';
import 'package:roshanghar/screens/roi_calculator_screen.dart';
import 'package:roshanghar/services/solar_price_service.dart';
import 'package:roshanghar/services/whatsapp_service.dart';
import 'package:roshanghar/utils/calculations.dart';
import 'package:roshanghar/widgets/app_drawer.dart';
import 'package:roshanghar/widgets/result_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'setup_complete': true,
      'user_name': 'Haji Saleem',
      'language_code': 'en',
    });
  });

  testWidgets('RoshanGhar app renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SolarAppState(),
        child: const RoshanGharApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('RoshanGhar'), findsWidgets);
    expect(find.text('🛠️ DEDICATED TOOLS & CHECKERS'), findsOneWidget);
  });

  testWidgets('AppDrawer renders all calculator navigation destinations',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SolarAppState(),
        child: const MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(currentRoute: 'home'),
            body: Text('Test Body'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('All-in-One Sizer & Invoice'), findsOneWidget);
    expect(find.text('Load Calculator'), findsOneWidget);
    expect(find.text('Battery Bank Sizer'), findsOneWidget);
    expect(find.text('Solar Panel Sizer'), findsOneWidget);
    expect(find.text('Inverter Capacity Checker'), findsOneWidget);
    expect(find.text('ROI & Payback Calculator'), findsOneWidget);
  });

  group('SolarCalculations Unit Tests', () {
    test('calculateBatterySizing computes correctly for 24V system', () {
      final res = SolarCalculations.calculateBatterySizing(
        watts: 800,
        backupHours: 4.0,
        systemVoltage: 24,
        batteryAh: 180,
        batteryType: 'Tubular',
      );

      expect(res['batteriesNeeded'], greaterThan(0));
      expect(res['totalAh'], greaterThan(0));
      expect(res['wiringRecommendation'], isNotEmpty);
    });

    test('calculateSolarPanelSizing returns positive panel count', () {
      final res = SolarCalculations.calculateSolarPanelSizing(
        dailyKWh: 15.0,
        cityName: 'Lahore',
        panelWatts: 585,
      );

      expect(res['panelsNeeded'], greaterThan(0));
      expect(res['arrayKW'], greaterThan(0.0));
      expect(res['estimatedDailyGenKWh'], greaterThan(0.0));
    });

    test('checkInverterCapacity validates safe headroom accurately', () {
      final safeRes = SolarCalculations.checkInverterCapacity(
        peakLoadWatts: 2000,
        inverterKva: 3.6,
      );
      expect(safeRes['isSafe'], isTrue);
      expect(safeRes['headroomWatts'], greaterThan(0.0));

      final overloadedRes = SolarCalculations.checkInverterCapacity(
        peakLoadWatts: 5000,
        inverterKva: 3.2,
      );
      expect(overloadedRes['isSafe'], isFalse);
    });

    test('calculateROIPayback returns valid payback years and lifetime savings', () {
      final roi = SolarCalculations.calculateROIPayback(
        systemCostPKR: 850000,
        monthlyUnitsKWh: 500,
        wapdaUnitRatePKR: 48,
        hasNetMetering: false,
      );

      expect(roi['monthlySavings'], greaterThan(0.0));
      expect(roi['annualSavings'], greaterThan(0.0));
      expect(roi['paybackYears'], greaterThan(0.0));
      expect((roi['tenYearSavingsChartData'] as List<double>).length, equals(10));
    });
  });

  group('Dedicated Tools Narrow Screen Overflow Tests', () {
    testWidgets('ResultCard renders without overflow with large values and long details',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResultCard(
                title: 'INVERTER LOADING ANALYSIS',
                value: '❌ OVERLOAD WARNING',
                subtitle: 'Your appliances load exceeds recommended inverter loading guidelines!',
                details: [
                  ResultDetailRow(
                    label: 'Very Long Label Name for Electrical Measurement Specification',
                    value: 'Rs. 1,450,000 / month',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('BatterySizerScreen renders without overflow on 320px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: BatterySizerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('InverterCheckerScreen renders without overflow on 320px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: InverterCheckerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('PanelSizerScreen renders without overflow on 320px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: PanelSizerScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('RoiCalculatorScreen renders without overflow on 320px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: RoiCalculatorScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoadCalculatorScreen renders without overflow on 320px width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: LoadCalculatorScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('HomeScreen renders without overflow on 320px width including Live Market Rates button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      expect(tester.takeException(), isNull);

      // Scroll to the Live Market Rates button
      final liveMarketBtn = find.text('Live Market Rates');
      await tester.scrollUntilVisible(
        liveMarketBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(liveMarketBtn, findsOneWidget);

      await tester.tap(liveMarketBtn);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Pakistan Solar Market Rates'), findsOneWidget);
    });
  });

  group('SolarPriceService & Live Market Rates Tests', () {
    test('SolarPriceService returns Tier-1 Pakistani panel rates', () async {
      final rates = await SolarPriceService.getPanelRates();
      expect(rates, isNotEmpty);
      expect(rates.containsKey('jinko-585'), isTrue);
      expect(rates.containsKey('canadian-585'), isTrue);
      expect(rates.containsKey('trina-585'), isTrue);
      expect(rates['jinko-585'], greaterThanOrEqualTo(35.0));
    });

    test('SolarPriceService provides last updated timestamp', () async {
      final updated = await SolarPriceService.getLastUpdatedText();
      expect(updated, isNotEmpty);
    });
  });

  group('WhatsApp Load-Sharing Tests', () {
    test('formatLoadMessage creates correct message format without prices', () {
      final message = WhatsAppService.formatLoadMessage(
        loadData: {
          'Inverter AC (1.5 Ton)': 2,
          'Ceiling Fan (Standard)': 4,
          'LED Bulb / Tube': 8,
          'Zero Quantity Item': 0,
        },
        totalKw: 3.50,
      );

      // Verifies required opening
      expect(
        message,
        contains('Assalam-o-Alaikum! I calculated my household load using RoshanGhar.'),
      );
      // Verifies appliances with quantities
      expect(message, contains('• 2x Inverter AC (1.5 Ton)'));
      expect(message, contains('• 4x Ceiling Fan (Standard)'));
      expect(message, contains('• 8x LED Bulb / Tube'));
      expect(message, isNot(contains('Zero Quantity Item')));

      // Verifies kW total
      expect(message, contains('3.50 kW'));

      // Verifies asking for quotation / audit
      expect(message.toLowerCase(), contains('audit and quotation'));

      // STRICT PRIVACY CHECK: ensures no pricing figures or currency symbols
      expect(message, isNot(contains('PKR')));
      expect(message, isNot(contains('Rs')));
      expect(message, isNot(contains('markup')));
      expect(message, isNot(contains('Price')));
    });

    testWidgets('LoadCalculatorScreen displays Share via WhatsApp button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: LoadCalculatorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final shareBtn = find.text('Share Load via WhatsApp');
      expect(shareBtn, findsOneWidget);

      // AI Engineering audit button is temporarily commented out
      // final auditBtn = find.text('Request AI Engineering Audit');
      // expect(auditBtn, findsOneWidget);
    });

    // AI Engineering audit button is temporarily commented out
    /*
    testWidgets('HomeScreen calculation results displays Request AI Engineering Audit button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SolarAppState(),
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final verticalList = find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.vertical);
      await tester.drag(verticalList, const Offset(0, -3000));
      await tester.pumpAndSettle();

      final proDetailsTile = find.byType(ExpansionTile);
      await tester.tap(proDetailsTile);
      await tester.pumpAndSettle();

      // Scroll inside to ensure the button is visible
      await tester.drag(verticalList, const Offset(0, -1000));
      await tester.pumpAndSettle();

      final auditBtn = find.text('Request AI Engineering Audit');
      expect(auditBtn, findsOneWidget);
    });
    */
  });
}

