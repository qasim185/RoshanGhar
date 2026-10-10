import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/calculations.dart';
import '../widgets/result_card.dart';
import '../widgets/admob_banner.dart';

class BatterySizerScreen extends StatefulWidget {
  const BatterySizerScreen({super.key});

  @override
  State<BatterySizerScreen> createState() => _BatterySizerScreenState();
}

class _BatterySizerScreenState extends State<BatterySizerScreen> {
  // Input form variables
  late TextEditingController _loadController;
  double _backupHours = 4.0;
  String _batteryType = 'Tubular'; // Tubular is default in Pakistan, Lithium (LiFePO4) and AGM are popular
  int _systemVoltage = 24; // 12V, 24V, 48V are standard
  int _batteryAh = 180; // Ah rating: 100, 150, 180, 200, 220

  @override
  void initState() {
    super.initState();
    _loadController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill continuous wattage load dynamically from previous Screen loads sum
    final totalLoad = Provider.of<SolarAppState>(context).totalLoadWatts;
    if (_loadController.text.isEmpty && totalLoad > 0) {
      _loadController.text = totalLoad.toString();
    }
  }

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);
    final int wattsVal = int.tryParse(_loadController.text) ?? 0;

    // Trigger the central mathematical calculations engine
    final calculations = SolarCalculations.calculateBatterySizing(
      watts: wattsVal,
      backupHours: _backupHours,
      systemVoltage: _systemVoltage,
      batteryAh: _batteryAh,
      batteryType: _batteryType,
    );

    final int batteriesNeeded = calculations['batteriesNeeded'] as int;
    final int totalAh = calculations['totalAh'] as int;
    final double totalCapKWh = (calculations['totalCapacityWh'] as double) / 1000.0;
    final double usableCapKWh = (calculations['usableCapacityWh'] as double) / 1000.0;
    final String recommendation = calculations['wiringRecommendation'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(appState.translate('batterySizer'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D9E75),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top sizing configurations form card
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
                          "Configure Backup Needs",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        
                        // Overridable Watts input textfield
                        TextField(
                          controller: _loadController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Continuous Power Running on Battery (Watts)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.bolt, color: Colors.orange),
                            suffixText: "W",
                            hintText: "Enter manual load e.g. 800",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Backup hours slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text("Backup runtime planned", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Text("${_backupHours.toStringAsFixed(1)} Hours", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ],
                        ),
                        Slider(
                          value: _backupHours,
                          min: 1.0,
                          max: 16.0,
                          divisions: 30,
                          activeColor: const Color(0xFF1D9E75),
                          onChanged: (val) {
                            setState(() {
                              _backupHours = val;
                            });
                          },
                        ),

                        // System Voltage Segmented Selector
                        const Text("Battery Bank DC System Voltage", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ToggleButtons(
                            isSelected: [
                              _systemVoltage == 12,
                              _systemVoltage == 24,
                              _systemVoltage == 48,
                            ],
                            onPressed: (index) {
                              setState(() {
                                if (index == 0) _systemVoltage = 12;
                                if (index == 1) _systemVoltage = 24;
                                if (index == 2) _systemVoltage = 48;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey,
                            selectedColor: Colors.white,
                            fillColor: const Color(0xFF1D9E75),
                            constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("12V (Small)"),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("24V (Mid)"),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("48V (Large)"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Battery Type Chemistry selector
                        const Text("Battery Chemistry Model", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _batteryType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Tubular', child: Text("Tubular Lead-Acid (OpzV / Tall) — 60% DoD", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'LiFePO4', child: Text("Lithium Iron Phosphate (LiFePO4) — 90% DoD", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'AGM', child: Text("AGM VRLA Sealed Gel — 50% DoD", overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _batteryType = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // AH rating option
                        const Text("Battery Ampere-Hour Rating (capacity per cell)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _batteryAh,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 100, child: Text("100 Ah (Standard AGM)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 150, child: Text("150 Ah (Medium Residential)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 180, child: Text("180 Ah (OpzV Tall)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 200, child: Text("200 Ah (Standard Inverter)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 220, child: Text("220 Ah (Max Capacity tubular)", overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _batteryAh = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Output metrics Display panel
                if (wattsVal > 0) ...[
                  ResultCard(
                    title: "BATTERIES REQUIRED (12V Blocks)",
                    value: "$batteriesNeeded Batteries",
                    subtitle: "Best fit for a $_batteryType bank configured at ${_systemVoltage}V",
                    icon: Icons.battery_saver,
                    primaryColor: Colors.blue,
                    details: [
                      ResultDetailRow(label: "Total capacity (kW-hr)", value: "${totalCapKWh.toStringAsFixed(2)} kWh", icon: Icons.flash_on),
                      ResultDetailRow(label: "Usable backup capacity (DoD adjusted)", value: "${usableCapKWh.toStringAsFixed(2)} kWh", icon: Icons.offline_bolt_outlined),
                      ResultDetailRow(label: "Cumulative Amperage Rating", value: "$totalAh Ah", icon: Icons.adjust),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recommendation,
                          style: TextStyle(height: 1.3, fontSize: 13, color: Colors.blue[900], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Please increase continuous wattage load above 0 W to compute outputs.",
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
