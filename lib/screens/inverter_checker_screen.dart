import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/calculations.dart';
import '../widgets/result_card.dart';
import '../widgets/admob_banner.dart';

class InverterCheckerScreen extends StatefulWidget {
  const InverterCheckerScreen({super.key});

  @override
  State<InverterCheckerScreen> createState() => _InverterCheckerScreenState();
}

class _InverterCheckerScreenState extends State<InverterCheckerScreen> {
  // Preset list of popular inverters in Pakistan
  final List<Map<String, dynamic>> _presets = [
    {'brand': 'Inverex', 'model': 'Nitrox 3.6KW Hybrid', 'kva': 3.6},
    {'brand': 'Inverex', 'model': 'Nitrox 5.0KW Hybrid', 'kva': 5.0},
    {'brand': 'Inverex', 'model': 'Nitrox 8.0KW Hybrid', 'kva': 8.0},
    {'brand': 'Inverex', 'model': 'Veyron 3.2KW Off-Grid', 'kva': 3.2},
    {'brand': 'Inverex', 'model': 'Veyron II 5.2KW Off-Grid', 'kva': 5.2},
    {'brand': 'Growatt', 'model': 'SPF 5000 ES', 'kva': 5.0},
    {'brand': 'Growatt', 'model': 'SPF 12000T DVM', 'kva': 12.0},
    {'brand': 'Deye', 'model': 'SUN-5K-SG01 Single Phase', 'kva': 5.0},
    {'brand': 'Deye', 'model': 'SUN-8K-SG01 Single Phase', 'kva': 8.0},
    {'brand': 'Deye', 'model': 'SUN-12K-SG01 Three Phase', 'kva': 12.0},
    {'brand': 'Crown Micro', 'model': 'Elego 3.2KW', 'kva': 3.2},
    {'brand': 'Crown Micro', 'model': 'Elego 5.2KW', 'kva': 5.2},
    {'brand': 'Custom / Other', 'model': 'Configure manually', 'kva': 0.0},
  ];

  late Map<String, dynamic> _selectedInverter;
  late TextEditingController _loadController;
  late TextEditingController _customKvaController;
  double _safetyFactor = 0.80; // 80% Rule

  @override
  void initState() {
    super.initState();
    _selectedInverter = _presets[1]; // default Nitrox 5kW
    _loadController = TextEditingController();
    _customKvaController = TextEditingController(text: "5.0");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill kontinuier target watts from load calculator
    final totalLoad = Provider.of<SolarAppState>(context).totalLoadWatts;
    if (_loadController.text.isEmpty && totalLoad > 0) {
      _loadController.text = totalLoad.toString();
    }
  }

  @override
  void dispose() {
    _loadController.dispose();
    _customKvaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);
    
    final int peakLoad = int.tryParse(_loadController.text) ?? 0;
    
    double inverterRatingKVA = _selectedInverter['kva'];
    if (_selectedInverter['model'] == 'Configure manually') {
      inverterRatingKVA = double.tryParse(_customKvaController.text) ?? 5.0;
    }

    // Trigger Inverter safety calculations core
    final analysis = SolarCalculations.checkInverterCapacity(
      peakLoadWatts: peakLoad,
      inverterKva: inverterRatingKVA,
      safetyFactor: _safetyFactor,
    );

    final bool isSafe = analysis['isSafe'] as bool;
    final double safeCapacityWatts = analysis['safeCapacityWatts'] as double;
    final double headroomWatts = analysis['headroomWatts'] as double;
    final double headroomPercent = analysis['headroomPercent'] as double;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(appState.translate('inverterCheck'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D9E75),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Configurations Panel card
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
                          "Configure Inverter Options",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Overridable Peak load wattage
                        TextField(
                          controller: _loadController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Peak Connected Load (Watts)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.electrical_services, color: Colors.purple),
                            suffixText: "W",
                            hintText: "Enter continuous load e.g. 5000",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Preset Dropdown selector
                        const Text("Select Local Inverter Brand/Model Preset", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          initialValue: _selectedInverter,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _presets.map((item) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: item,
                              child: Text(
                                "${item['brand']} — ${item['model']} (${item['kva'] > 0 ? '${item['kva']} kW' : 'Custom'})",
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedInverter = val;
                              });
                            }
                          },
                        ),

                        // Custom KVA manual size input if selected custom dropdown
                        if (_selectedInverter['model'] == 'Configure manually') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _customKvaController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: "Enter Custom Inverter kW / kVA Rating",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.bolt_sharp, color: Colors.purple),
                              suffixText: "kW / kVA",
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Safety margin threshold slider selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Inverter Safety Loading Cap",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text("${(_safetyFactor * 100).round()}% Loading Cap", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.purple)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text("Continuous load should stay below this factor to protect electronics.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Slider(
                          value: _safetyFactor,
                          min: 0.50,
                          max: 0.95,
                          divisions: 9,
                          activeColor: Colors.purple,
                          onChanged: (val) {
                            setState(() {
                              _safetyFactor = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Output metrics Card displays
                if (peakLoad > 0) ...[
                  ResultCard(
                    title: "INVERTER LOADING ANALYSIS",
                    value: isSafe ? "✅ SAFE CRITICAL LOAD" : "❌ OVERLOAD WARNING",
                    subtitle: isSafe 
                        ? "Continuous load is well within limits of your selected inverter."
                        : "Your appliances load exceeds recommended inverter loading guidelines!",
                    icon: isSafe ? Icons.gpp_good : Icons.gpp_maybe,
                    primaryColor: isSafe ? Colors.green : Colors.red,
                    details: [
                      ResultDetailRow(label: "Inverter Max Nominal Rating", value: "${inverterRatingKVA.toStringAsFixed(1)} kW / kVA", icon: Icons.offline_bolt),
                      ResultDetailRow(label: "Safety Adjusted Max Load Limit", value: "${safeCapacityWatts.round()} W", icon: Icons.security),
                      ResultDetailRow(label: "Actual Continuous Peak Load", value: "$peakLoad W", icon: Icons.power_input),
                      
                      const Divider(height: 16),
                      
                      ResultDetailRow(
                        label: isSafe ? "Remaining Safe Headroom" : "Deficit Overload Draw", 
                        value: "${headroomWatts.abs().round()} W", 
                        icon: isSafe ? Icons.arrow_upward : Icons.arrow_downward,
                        iconColor: isSafe ? Colors.green : Colors.red,
                      ),
                      ResultDetailRow(
                        label: "Safety Loading Margin %", 
                        value: "${headroomPercent.toStringAsFixed(1)}%", 
                        icon: Icons.percent
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Please increase peak continuous load above 0 W to trigger capacity rating checking.",
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
