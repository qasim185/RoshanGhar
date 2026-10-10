class SolarCalculations {
  // Battery Depth of Discharge settings constant mapping
  static const Map<String, double> batteryDoD = {
    'LiFePO4': 0.90,
    'AGM': 0.50,
    'Tubular': 0.60,
  };

  // Peak Sun Hours (PSH) mapping for Pakistani Cities
  static const Map<String, double> cityPSH = {
    'Karachi': 5.5,
    'Lahore': 4.8,
    'Islamabad': 4.5,
    'Peshawar': 5.0,
    'Quetta': 6.0,
    'Multan': 5.8,
    'Faisalabad': 4.9,
    'Attock': 4.7,
    'Other / Generic': 5.0,
  };

  /// Calculates the number of batteries required
  /// [watts] - Total continuous load
  /// [backupHours] - Target hours of backup running solely on battery bank
  /// [systemVoltage] - DC voltage (12V, 24V, 48V)
  /// [batteryAh] - Individual battery amperage rating (e.g. 150Ah, 200Ah)
  /// [batteryType] - Battery chemistry type ('LiFePO4', 'AGM', 'Tubular')
  static Map<String, dynamic> calculateBatterySizing({
    required int watts,
    required double backupHours,
    required int systemVoltage,
    required int batteryAh,
    required String batteryType,
  }) {
    final double dod = batteryDoD[batteryType] ?? 0.60;
    
    // Total energy needed in Watt-Hours (Wh)
    final double energyNeededWh = watts * backupHours;
    
    // Usable energy capacity per single battery in Wh
    // Formula: Voltage (V) * Capacity (Ah) * Depth-of-Discharge (DoD)
    final double usableEnergyPerBatteryWh = systemVoltage * batteryAh * dod;
    
    // Total batteries needed
    int batteriesCount = (energyNeededWh / usableEnergyPerBatteryWh).ceil();
    if (batteriesCount <= 0) batteriesCount = 1;

    // Batteries must align with system voltage multiples for series pairings (simplification)
    // E.g. If system is 24V and we are using 12V batteries, we need multiples of 2.
    // E.g. If system is 48V and we are using 12V batteries, we need multiples of 4.
    // If using a custom system, let's keep it safe. Common practice is series strings.
    int stringMultipier = (systemVoltage / 12).ceil();
    if (stringMultipier <= 0) stringMultipier = 1;
    
    // Round batteries count to match the string voltage requirement
    if (batteriesCount % stringMultipier != 0) {
      batteriesCount = ((batteriesCount / stringMultipier).ceil()) * stringMultipier;
    }

    final double totalCapacityWh = batteriesCount * systemVoltage * batteryAh.toDouble();
    final double usableCapacityWh = totalCapacityWh * dod;

    // Recommended wiring configuration explanation
    String recommendation = "";
    int seriesCount = (systemVoltage / 12).round(); // standard is relative to 12V blocks
    if (seriesCount <= 1) {
      recommendation = "Connect all $batteriesCount batteries in PARALLEL to maintain a 12V DC system.";
    } else {
      int parallelStrings = (batteriesCount / seriesCount).round();
      if (parallelStrings <= 1) {
        recommendation = "Connect all $batteriesCount batteries in SERIES to achieve a ${systemVoltage}V DC system.";
      } else {
        recommendation = "Connect in Series-Parallel: $parallelStrings parallel strings, each having $seriesCount batteries in series.";
      }
    }

    return {
      'batteriesNeeded': batteriesCount,
      'totalAh': batteriesCount * batteryAh,
      'totalCapacityWh': totalCapacityWh,
      'usableCapacityWh': usableCapacityWh,
      'wiringRecommendation': recommendation,
    };
  }

  /// Calculates solar panel arrays needed
  /// [dailyKWh] - Daily consumer load electricity in kilowatt-hours
  /// [cityName] - Selected PSH city or Custom location
  /// [customPSH] - Peak sun hours if custom
  /// [panelWatts] - Panel rating wattage (e.g. 540W)
  /// [lossFactor] - Efficiency factor (default 0.80 for 20% system losses)
  static Map<String, dynamic> calculateSolarPanelSizing({
    required double dailyKWh,
    required String cityName,
    double? customPSH,
    required int panelWatts,
    double lossFactor = 0.80,
  }) {
    final double psh = (cityName == 'Other / Generic' && customPSH != null)
        ? customPSH
        : (cityPSH[cityName] ?? 5.0);

    // Required Array size in Watts (W)
    // Formula: (Daily energy Wh) / (Peak Sun Hours * System Losses Coefficient)
    if (psh <= 0) return {'panelsNeeded': 0, 'arrayKW': 0.0, 'dailyGenKWh': 0.0};
    
    final double requiredArrayWatts = (dailyKWh * 1000) / (psh * lossFactor);
    final int panelsCount = (requiredArrayWatts / panelWatts).ceil();
    final double actualArrayWatts = panelsCount * panelWatts.toDouble();
    final double arrayKW = actualArrayWatts / 1000.0;
    
    // Gen output = Array kW * sun hours * efficiency
    final double estimatedDailyGenKWh = arrayKW * psh * lossFactor;

    return {
      'panelsNeeded': panelsCount <= 0 ? 0 : panelsCount,
      'arrayKW': arrayKW,
      'estimatedDailyGenKWh': estimatedDailyGenKWh,
      'requiredArrayWatts': requiredArrayWatts,
    };
  }

  /// Calculates dynamic ROI metrics based on costs, power generation, and WAPDA tariffs
  static Map<String, dynamic> calculateROIPayback({
    required double systemCostPKR,
    required double monthlyUnitsKWh,
    required double wapdaUnitRatePKR,
    required bool hasNetMetering,
    double exportRatePKR = 22.0,
  }) {
    // Normal self-consumption rate saves full WAPDA cost
    final double normalSavingsPKR = monthlyUnitsKWh * wapdaUnitRatePKR;
    
    // If net metering, assume we export 30% and consume 70% of solar generation
    final double dynamicTariffSavingsPKR = hasNetMetering 
        ? (monthlyUnitsKWh * 0.7 * wapdaUnitRatePKR) + (monthlyUnitsKWh * 0.3 * exportRatePKR)
        : normalSavingsPKR;

    final double monthlySavings = dynamicTariffSavingsPKR;
    final double annualSavings = monthlySavings * 12;
    
    final double paybackMonths = monthlySavings > 0 ? (systemCostPKR / monthlySavings) : 0;
    final double paybackYears = paybackMonths / 12.0;

    // 25-Year Lifecycle profits
    // Solar panels have 25-year linear performance warranty. Maintenance counts.
    final double lifetimeSavings25Years = (annualSavings * 25) - systemCostPKR;

    // Generate yearly data for charts
    List<double> cumulativeSavingsList = [];
    double currentCumSaved = 0.0;
    for (int year = 1; year <= 10; year++) {
      currentCumSaved += annualSavings;
      cumulativeSavingsList.add(currentCumSaved);
    }

    return {
      'monthlySavings': monthlySavings,
      'annualSavings': annualSavings,
      'paybackMonths': paybackMonths,
      'paybackYears': paybackYears,
      'lifetimeSavings25Years': lifetimeSavings25Years,
      'tenYearSavingsChartData': cumulativeSavingsList,
    };
  }

  /// Validates if an inverter is capable of carrying the peak continuous load
  static Map<String, dynamic> checkInverterCapacity({
    required int peakLoadWatts,
    required double inverterKva,
    double safetyFactor = 0.80, // 80% Rule
  }) {
    // kva translates to load carrying capacity based on safety factor
    final double safeCapacityWatts = inverterKva * 1000 * safetyFactor;
    final bool isSafe = peakLoadWatts <= safeCapacityWatts;
    final double remainingHeadroomWatts = safeCapacityWatts - peakLoadWatts;
    final double headroomPercent = safeCapacityWatts > 0 
        ? (remainingHeadroomWatts / safeCapacityWatts) * 100 
        : 0;

    return {
      'isSafe': isSafe,
      'safeCapacityWatts': safeCapacityWatts,
      'headroomWatts': remainingHeadroomWatts,
      'headroomPercent': headroomPercent,
    };
  }
}
