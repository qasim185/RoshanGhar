import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/calculations.dart';
import '../widgets/result_card.dart';
import '../widgets/admob_banner.dart';

class PanelSizerScreen extends StatefulWidget {
  const PanelSizerScreen({super.key});

  @override
  State<PanelSizerScreen> createState() => _PanelSizerScreenState();
}

class _PanelSizerScreenState extends State<PanelSizerScreen> {
  late TextEditingController _dailyKWhController;
  String _selectedCity = 'Karachi';
  double _customPSH = 5.0;
  int _panelWatts = 540; // High wattage panels (540W - 585W - 650W) are the standard now in PK
  double _lossFactor = 0.80; // 20% losses

  @override
  void initState() {
    super.initState();
    _dailyKWhController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-fill from our Load Calculator dynamic states
    final avgDailyKWh = Provider.of<SolarAppState>(context).totalDailyKWh;
    if (_dailyKWhController.text.isEmpty && avgDailyKWh > 0) {
      _dailyKWhController.text = avgDailyKWh.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _dailyKWhController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);
    final double inputKWh = double.tryParse(_dailyKWhController.text) ?? 0.0;

    // Fetch details from calculations core
    final sizerResults = SolarCalculations.calculateSolarPanelSizing(
      dailyKWh: inputKWh,
      cityName: _selectedCity,
      customPSH: _customPSH,
      panelWatts: _panelWatts,
      lossFactor: _lossFactor,
    );

    final int panelsNeeded = sizerResults['panelsNeeded'] as int;
    final double arrayKW = sizerResults['arrayKW'] as double;
    final double estimatedGen = sizerResults['estimatedDailyGenKWh'] as double;

    // Get active sun hours
    final double currentSunHours = (_selectedCity == 'Other / Generic') 
        ? _customPSH 
        : (SolarCalculations.cityPSH[_selectedCity] ?? 5.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(appState.translate('panelSizer'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D9E75),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // inputs form card
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
                          "Configure Solar Generation Needs",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 16),

                        // Units textfield
                        TextField(
                          controller: _dailyKWhController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Target Daily Consumption (kWh / Units)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.flash_on, color: Colors.amber),
                            suffixText: "kWh",
                            hintText: "Enter daily units target e.g. 15",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // City Sun hours selector mapping
                        const Text("Select Regional City (for local solar radiance index)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: SolarCalculations.cityPSH.keys.map((city) {
                            final psh = SolarCalculations.cityPSH[city]!;
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text("$city ($psh Peak Sun hours)", overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCity = val;
                              });
                            }
                          },
                        ),
                        
                        if (_selectedCity == 'Other / Generic') ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text("Adjust Custom Sun hours", style: TextStyle(fontSize: 12)),
                              ),
                              Text("${_customPSH.toStringAsFixed(1)} PSH", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Slider(
                            value: _customPSH,
                            min: 2.0,
                            max: 8.0,
                            divisions: 12,
                            activeColor: const Color(0xFF1D9E75),
                            onChanged: (val) {
                              setState(() {
                                _customPSH = val;
                              });
                            },
                          )
                        ],
                        const SizedBox(height: 16),

                        // Solar Module specs presets
                        const Text("Choose Single Panel Wattage", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _panelWatts,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 150, child: Text("150W (Small Off-grid model)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 250, child: Text("250W (Retrofitted system)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 400, child: Text("400W (Medium Mono-PERC)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 540, child: Text("540W (Standard Tier 1 Utility)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 585, child: Text("585W (High power N-Type)", overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 650, child: Text("650W (Bifacial heavy duty)", overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _panelWatts = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Safety Loss factors slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "System Performance Safety Margin",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("${((1.0 - _lossFactor) * 100).round()}% Losses", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text("Accounts for dust, wire drops, cell temp coefficients.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Slider(
                          value: _lossFactor,
                          min: 0.60,
                          max: 0.95,
                          divisions: 7,
                          activeColor: const Color(0xFF1D9E75),
                          onChanged: (val) {
                            setState(() {
                              _lossFactor = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Calculations Outputs card display
                if (inputKWh > 0) ...[
                  ResultCard(
                    title: "RECOMMENDED SOLAR ARRAY SIZE",
                    value: "$panelsNeeded Panels",
                    subtitle: "Calculated with $_panelWatts Watts panels in $_selectedCity",
                    icon: Icons.solar_power,
                    primaryColor: Colors.orange,
                    details: [
                      ResultDetailRow(label: "Total Array Capacity", value: "${arrayKW.toStringAsFixed(2)} kW", icon: Icons.offline_bolt),
                      ResultDetailRow(label: "Required Minimum Watts", value: "${(sizerResults['requiredArrayWatts'] as double).round()} W", icon: Icons.analytics),
                      ResultDetailRow(label: "Regional Average Sun Hours", value: "${currentSunHours.toStringAsFixed(1)} PSH", icon: Icons.sunny),
                      ResultDetailRow(label: "Est. Generation with losses", value: "${estimatedGen.toStringAsFixed(1)} kWh/day", icon: Icons.energy_savings_leaf),
                      const Divider(height: 16),
                      Row(
                        children: const [
                          Icon(Icons.info, size: 14, color: Colors.orange),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Tip: In Pakistani winter, sun duration decreases 20%. Add 2 extra panels to preserve backup.",
                              style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        "Please increase target consumption units above 0 kWh to run calculator.",
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
