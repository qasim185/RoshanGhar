import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/calculations.dart';
import '../widgets/result_card.dart';
import '../widgets/admob_banner.dart';

class RoiCalculatorScreen extends StatefulWidget {
  const RoiCalculatorScreen({super.key});

  @override
  State<RoiCalculatorScreen> createState() => _RoiCalculatorScreenState();
}

class _RoiCalculatorScreenState extends State<RoiCalculatorScreen> {
  late TextEditingController _costController;
  late TextEditingController _unitsController;
  double _wapdaRate = 42.0; // Typical WAPDA off-peak/avg slab rate is Rs. 42-50/kWh
  bool _netMetering = false;
  double _exportRate = 22.0; // Typical NEPRA export feed-in-tariff is Rs. 22

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(text: "750000"); // Standard 5kW hybrid costs ~7.5L PKR
    _unitsController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Estimate monthly units generated based on load calculator parameters
    final dailyKWh = Provider.of<SolarAppState>(context).totalDailyKWh;
    if (_unitsController.text.isEmpty && dailyKWh > 0) {
      double monthlyGenerated = dailyKWh * 30;
      _unitsController.text = monthlyGenerated.toStringAsFixed(0);
    } else if (_unitsController.text.isEmpty) {
      _unitsController.text = "450"; // typical 3kW/5kW system generates ~450 units/month
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);
    final double costVal = double.tryParse(_costController.text) ?? 0.0;
    final double unitsVal = double.tryParse(_unitsController.text) ?? 0.0;

    // Trigger ROI Payback computations
    final roi = SolarCalculations.calculateROIPayback(
      systemCostPKR: costVal,
      monthlyUnitsKWh: unitsVal,
      wapdaUnitRatePKR: _wapdaRate,
      hasNetMetering: _netMetering,
      exportRatePKR: _exportRate,
    );

    final double monthlySaved = roi['monthlySavings'] as double;
    final double annualSaved = roi['annualSavings'] as double;
    final double paybackYears = roi['paybackYears'] as double;
    final double standardLifetimeProfit = roi['lifetimeSavings25Years'] as double;
    final List<double> cumulativeChartData = roi['tenYearSavingsChartData'] as List<double>;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(appState.translate('roiCalc'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D9E75),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cost configurations form card
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Configure System Investment",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // System capitalized cost in PKR
                        TextField(
                          controller: _costController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Total Solar Setup Cost (PKR)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.currency_exchange, color: Colors.teal),
                            suffixText: "PKR",
                            hintText: "Enter total system costs e.g. 750000",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Monthly generated kilowatt hours
                        TextField(
                          controller: _unitsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Monthly Average Generation Offset (kWh)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.flash_on, color: Colors.amber),
                            suffixText: "Units",
                            hintText: "Enter monthly solar units saved e.g. 450",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // WAPDA utility slab rate slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text("WAPDA Rate / Cost per Unit", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text("Rs. ${_wapdaRate.toStringAsFixed(1)} / kWh", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
                          ],
                        ),
                        Slider(
                          value: _wapdaRate,
                          min: 15.0,
                          max: 80.0,
                          divisions: 65,
                          activeColor: const Color(0xFF1D9E75),
                          onChanged: (val) {
                            setState(() {
                              _wapdaRate = val;
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // Net metering toggle settings
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("Net Metering (On-Grid Export)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  SizedBox(height: 2),
                                  Text("Are you exporting back excess solar to NEPRA grid?", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _netMetering,
                              activeThumbColor: Colors.teal,
                              onChanged: (val) {
                                setState(() {
                                  _netMetering = val;
                                });
                              },
                            )
                          ],
                        ),

                        if (_netMetering) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text("NEPRA National Export Rate (PKR)", style: TextStyle(fontSize: 12)),
                              ),
                              Text("Rs. ${_exportRate.toStringAsFixed(1)} / kWh", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Slider(
                            value: _exportRate,
                            min: 12.0,
                            max: 35.0,
                            divisions: 23,
                            activeColor: Colors.teal,
                            onChanged: (val) {
                              setState(() {
                                _exportRate = val;
                              });
                            },
                          )
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Calculations outputs displaying cards
                if (costVal > 0 && unitsVal > 0) ...[
                  ResultCard(
                    title: "ESTIMATED PAYBACK PERIOD",
                    value: paybackYears <= 0.1 
                        ? "Immediate Payback" 
                        : "${paybackYears.toStringAsFixed(1)} Years",
                    subtitle: "Takes approx. ${(paybackYears * 12).round()} months to recover initial system costs",
                    icon: Icons.calendar_view_month,
                    primaryColor: Colors.teal,
                    details: [
                      ResultDetailRow(
                        label: "Average Monthly Savings", 
                        value: "Rs. ${monthlySaved.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}", 
                        icon: Icons.savings
                      ),
                      ResultDetailRow(
                        label: "Average Annual Savings", 
                        value: "Rs. ${annualSaved.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}", 
                        icon: Icons.savings_outlined
                      ),
                      ResultDetailRow(
                        label: "25-Year Lifecycle Net Gains", 
                        value: "Rs. ${standardLifetimeProfit.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}", 
                        icon: Icons.monetization_on,
                        iconColor: Colors.amber[800],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Cumulative savings ledger projection cards
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "10-Year Cumulative Savings Projection Ledger",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                          ),
                          const Divider(height: 20),
                          
                          // Draw a highly legible ledger table mapping ROI growth offset
                          ...List.generate(10, (idx) {
                            final double yearSaved = cumulativeChartData[idx];
                            final bool costRecovered = yearSaved >= costVal;

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 0.5)),
                                color: costRecovered ? Colors.green.withValues(alpha: 0.02) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 11,
                                        backgroundColor: costRecovered ? Colors.green : Colors.blueGrey[200],
                                        child: Text(
                                          "${idx + 1}",
                                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Year ${idx + 1}",
                                        style: TextStyle(
                                          fontWeight: costRecovered ? FontWeight.bold : FontWeight.normal,
                                          color: costRecovered ? Colors.black87 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            "Rs. ${yearSaved.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: costRecovered ? Colors.green[800] : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (costRecovered && idx > 0 && cumulativeChartData[idx - 1] < costVal) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                            child: const Text("BREAKEVEN", style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                                          )
                                        ]
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Please increase costs and monthly generation defaults above Rs. 0 to run investment estimations.",
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                ]
              ],
            ),
          ),
          const AdmobBanner(),
        ],
      ),
    );
  }
}
