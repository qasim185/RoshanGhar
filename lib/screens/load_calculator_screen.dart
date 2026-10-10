import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/appliance.dart';
// import '../services/n8n_audit_service.dart';
import '../services/nlp_load_parser.dart';
import '../services/whatsapp_service.dart';
import '../widgets/admob_banner.dart';

class LoadCalculatorScreen extends StatefulWidget {
  const LoadCalculatorScreen({super.key});

  @override
  State<LoadCalculatorScreen> createState() => _LoadCalculatorScreenState();
}

class _LoadCalculatorScreenState extends State<LoadCalculatorScreen> {
  // bool _isAuditing = false;

  // Preset list of common appliances in Gulf/Pakistani markets
  final List<Map<String, dynamic>> _presets = [
    {'name': 'LED Bulb / Tube', 'watts': 12},
    {'name': 'Ceiling Fan (AC/DC)', 'watts': 55},
    {'name': 'Ceiling Fan (Standard)', 'watts': 75},
    {'name': 'Inverter AC (1.0 Ton)', 'watts': 900},
    {'name': 'Inverter AC (1.5 Ton)', 'watts': 1400},
    {'name': 'Refrigerator (Inverter)', 'watts': 130},
    {'name': 'Deep Freezer', 'watts': 220},
    {'name': 'Water Pump (0.5 HP)', 'watts': 375},
    {'name': 'Water Pump (1.0 HP)', 'watts': 750},
    {'name': 'LED TV (40 inch)', 'watts': 75},
    {'name': 'Iron / Clothes Press', 'watts': 1000},
    {'name': 'Washing Machine', 'watts': 400},
    {'name': 'Microwave Oven', 'watts': 1200},
    {'name': 'Internet Router', 'watts': 15},
    {'name': 'Laptop Charger', 'watts': 65},
    {'name': 'Desktop Computer', 'watts': 250},
  ];

  Future<void> _shareToWhatsApp(SolarAppState appState) async {
    final Map<String, int> loadData = {};
    for (final app in appState.appliances) {
      if (app.quantity > 0) {
        loadData[app.name] = (loadData[app.name] ?? 0) + app.quantity;
      }
    }
    final double totalKw = appState.totalLoadWatts / 1000.0;
    final bool success = await WhatsAppService.shareLoadToWhatsApp(
      loadData: loadData,
      totalKw: totalKw,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp is not installed on this device.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /*
  Future<void> _requestAiAudit(SolarAppState appState) async {
    if (_isAuditing) return;
    setState(() {
      _isAuditing = true;
    });
    try {
      final Map<String, int> loadData = {};
      for (final app in appState.appliances) {
        if (app.quantity > 0) {
          loadData[app.name] = (loadData[app.name] ?? 0) + app.quantity;
        }
      }
      final double totalKw = appState.totalLoadWatts / 1000.0;
      await N8nAuditService.requestAndShowAudit(
        context,
        loadData: loadData,
        totalKw: totalKw,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local AI Auditor unreachable. Running in offline mode.'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuditing = false;
        });
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(appState.translate('loadCalc'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1D9E75),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: "Share via WhatsApp",
            onPressed: () => _shareToWhatsApp(appState),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            tooltip: "Quick Text Load (AI/Urdu)",
            onPressed: () => _showNlpInputDialog(context, appState),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            tooltip: "Clear All",
            onPressed: () {
              appState.clearAppliances();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Load list cleared.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total load summary card
          Container(
            color: const Color(0xFF1D9E75),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildSummaryColumn(
                          "${appState.totalLoadWatts} W",
                          appState.translate('totalWatts'),
                          const Color(0xFF1D9E75),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      Expanded(
                        child: _buildSummaryColumn(
                          "${appState.totalDailyKWh.toStringAsFixed(2)} kWh",
                          appState.translate('dailyUnits'),
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildMiniSummary(
                          icon: Icons.wb_sunny_outlined,
                          label: appState.translate('daytimeLoad'),
                          value: "${appState.daytimeWatts} W",
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMiniSummary(
                          icon: Icons.nightlight_round_outlined,
                          label: appState.translate('nighttimeLoad'),
                          value: "${appState.nightWatts} W",
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.share, size: 18, color: Colors.white),
                      label: const Text(
                        'Share Load via WhatsApp',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _shareToWhatsApp(appState),
                    ),
                  ),
                  /*
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 1,
                      ),
                      icon: _isAuditing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                              ),
                            )
                          : const Icon(
                              Icons.psychology_outlined,
                              size: 18,
                              color: Color(0xFF38BDF8),
                            ),
                      label: Text(
                        _isAuditing
                            ? 'AI Auditor analyzing Swabi 4.8 PSH data...'
                            : 'Request AI Engineering Audit',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: _isAuditing ? null : () => _requestAiAudit(appState),
                    ),
                  ),
                  */
                ],
              ),
            ),
          ),

          // Core appliance rows
          Expanded(
            child: appState.appliances.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.electric_bolt, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            appState.translate('emptyLoadText'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: appState.appliances.length,
                    itemBuilder: (context, index) {
                      final app = appState.appliances[index];
                      return _buildApplianceRow(context, app, appState);
                    },
                  ),
          ),

          // Double FAB Action bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showPresetsSheet(context, appState),
                    icon: const Icon(Icons.playlist_add),
                    label: Text(appState.translate('addPreset')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showCustomApplianceDialog(context, appState),
                    icon: const Icon(Icons.add),
                    label: Text(appState.translate('addAppliance')),
                  ),
                ),
              ],
            ),
          ),

          const AdmobBanner(),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniSummary({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildApplianceRow(BuildContext context, Appliance app, SolarAppState appState) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            "${app.watts} Watts",
                            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  app.isDaytime ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                                  size: 14,
                                  color: app.isDaytime ? Colors.orange : Colors.indigo,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  app.isDaytime ? "Daytime Load" : "Night Load",
                                  style: TextStyle(
                                    color: app.isDaytime ? Colors.orange[800] : Colors.indigo[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Quantity Incrementor
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.redAccent),
                      onPressed: () {
                        if (app.quantity > 1) {
                          appState.updateAppliance(app.copyWith(quantity: app.quantity - 1));
                        } else {
                          appState.removeAppliance(app.id);
                        }
                      },
                    ),
                    Text(
                      "${app.quantity}",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.green),
                      onPressed: () {
                        appState.updateAppliance(app.copyWith(quantity: app.quantity + 1));
                      },
                    ),
                  ],
                ),
                
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => appState.removeAppliance(app.id),
                ),
              ],
            ),
            
            const Divider(height: 12, thickness: 0.5),
            
            // Slider to tweak power schedule hours
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  "Runtime: ${app.hoursPerDay.toStringAsFixed(1)}h",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                ),
                Expanded(
                  child: SizedBox(
                    height: 35,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: app.hoursPerDay,
                        min: 0.5,
                        max: 24.0,
                        divisions: 47, // 0.5hr steps
                        activeColor: const Color(0xFF1D9E75),
                        inactiveColor: Colors.grey[200],
                        onChanged: (val) {
                          appState.updateAppliance(app.copyWith(hoursPerDay: val));
                        },
                      ),
                    ),
                  ),
                )
              ],
            ),
            
            // Toggle for Day/Night load profiling
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Is this primarily daytime operational load?",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Night", style: TextStyle(fontSize: 11, color: Colors.indigo)),
                    Switch(
                      value: app.isDaytime,
                      activeThumbColor: Colors.orange,
                      inactiveThumbColor: Colors.indigo,
                      inactiveTrackColor: Colors.indigo.withAlpha(50),
                      onChanged: (val) {
                        appState.updateAppliance(app.copyWith(isDaytime: val));
                      },
                    ),
                    const Text("Day", style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // Draw Bottom sheet with standard presets
  void _showPresetsSheet(BuildContext context, SolarAppState appState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Add Typical Home Loads",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _presets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _presets[i];
                    return ListTile(
                      title: Text(p['name']),
                      trailing: Text(
                        "${p['watts']} Watts",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D9E75)),
                      ),
                      onTap: () {
                        final newApp = Appliance(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: p['name'],
                          watts: p['watts'],
                          hoursPerDay: 4.0,
                          isDaytime: p['name'].toString().contains('AC') || p['name'].toString().contains('LED Bulb') == false,
                        );
                        appState.addAppliance(newApp);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${p['name']} added to loads list.')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Draw Custom appliance input dialog
  void _showCustomApplianceDialog(BuildContext context, SolarAppState appState) {
    final nameController = TextEditingController();
    final wattsController = TextEditingController();
    bool isDaytime = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Custom Appliance Details"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name (e.g., Gaming PC, Air Fryer)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: wattsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Watts rating'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text("Load Profiles Window"),
                        ),
                        Row(
                          children: [
                            const Text("Night", style: TextStyle(fontSize: 12)),
                            Switch(
                              value: isDaytime,
                              onChanged: (val) {
                                setDialogState(() {
                                  isDaytime = val;
                                });
                              },
                            ),
                            const Text("Day", style: TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final watts = int.tryParse(wattsController.text) ?? 100;
                    if (name.isNotEmpty) {
                      appState.addAppliance(
                        Appliance(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          watts: watts,
                          isDaytime: isDaytime,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // Quick Natural Language load extractor dialog for Roman Urdu, Pashto, English
  void _showNlpInputDialog(BuildContext context, SolarAppState appState) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF1D9E75)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quick Text Load',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type loads in English, Roman Urdu, or Pashto:\n(e.g., "4 fans, 1 fridge, 6 bulbs" or "chaar pankhe ek ac")',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter text here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final input = textController.text.trim();
                if (input.isNotEmpty) {
                  final parsed = NlpLoadParser.parse(input);
                  int addedCount = 0;
                  final Map<String, int> wattMap = {
                    'fan': 75,
                    'dc_fan': 45,
                    'fridge': 150,
                    'ac': 1200,
                    'oven': 1200,
                    'bulb': 15,
                    'pump': 800,
                  };
                  final Map<String, String> nameMap = {
                    'fan': 'Ceiling Fan (AC)',
                    'dc_fan': 'DC Fan (12V)',
                    'fridge': 'Refrigerator',
                    'ac': 'Inverter AC',
                    'oven': 'Microwave / Oven',
                    'bulb': 'LED Bulb',
                    'pump': 'Water Pump',
                  };

                  parsed.forEach((key, count) {
                    if (count > 0 && nameMap.containsKey(key)) {
                      appState.addAppliance(
                        Appliance(
                          id: '${DateTime.now().millisecondsSinceEpoch}_$key',
                          name: nameMap[key]!,
                          watts: wattMap[key] ?? 100,
                          quantity: count,
                          hoursPerDay: key == 'bulb' ? 8.0 : (key == 'fan' ? 12.0 : 6.0),
                          isDaytime: key != 'bulb',
                        ),
                      );
                      addedCount += count;
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        addedCount > 0
                            ? '$addedCount appliances detected and added!'
                            : 'No recognizable appliances found in text.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Parse & Add'),
            ),
          ],
        );
      },
    );
  }
}
