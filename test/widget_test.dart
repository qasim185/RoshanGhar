import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solarcalcpk/app_state.dart';
import 'package:solarcalcpk/main.dart';
import 'package:solarcalcpk/screens/battery_sizer_screen.dart';
import 'package:solarcalcpk/screens/inverter_checker_screen.dart';
import 'package:solarcalcpk/screens/load_calculator_screen.dart';
import 'package:solarcalcpk/screens/panel_sizer_screen.dart';
import 'package:solarcalcpk/screens/roi_calculator_screen.dart';
import 'package:solarcalcpk/services/solar_price_service.dart';
import 'package:solarcalcpk/utils/calculations.dart';
import 'package:solarcalcpk/widgets/app_drawer.dart';
import 'package:solarcalcpk/widgets/result_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'setup_complete': true,
      'user_name': 'Haji Saleem',
      'language_code': 'en',
    });
  });

  testWidgets('SolarCalc app renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SolarAppState(),
        child: const SolarCalcApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('SolarCalcPK'), findsWidgets);
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
}
