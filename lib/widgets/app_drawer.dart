import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../screens/home_screen.dart';
import '../screens/load_calculator_screen.dart';
import '../screens/battery_sizer_screen.dart';
import '../screens/panel_sizer_screen.dart';
import '../screens/inverter_checker_screen.dart';
import '../screens/roi_calculator_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onOpenSettings;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);
    final String lang = appState.languageCode;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D9E75), Color(0xFF107B58)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.solar_power,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RoshanGhar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              appState.userName.isNotEmpty
                                  ? appState.userName
                                  : (lang == 'ur'
                                      ? 'سولر کیلکولیٹر'
                                      : 'Solar Sizing Suite'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (appState.isInstaller)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAEDCD),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO INSTALLER',
                            style: TextStyle(
                              color: Color(0xFF4A5D4E),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      if (appState.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerTile(
              context: context,
              title: lang == 'ur' ? 'مکمل سولر سائزنگ اور انوائس' : 'All-in-One Sizer & Invoice',
              subtitle: lang == 'ur' ? 'سسٹم سائزنگ اور کوٹیشن' : 'Main solar calculator & PDF generator',
              icon: Icons.calculate,
              isSelected: currentRoute == 'home',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'home') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
            _buildDrawerTile(
              context: context,
              title: lang == 'ur' ? 'لوڈ کیلکولیٹر' : 'Load Calculator',
              subtitle: lang == 'ur' ? 'گھریلو بجلی کے آلات کا کل بوجھ' : 'Detailed appliance wattage & duty cycle',
              icon: Icons.electrical_services,
              isSelected: currentRoute == 'load',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'load') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoadCalculatorScreen()),
                  );
                }
              },
            ),
            _buildDrawerTile(
              context: context,
              title: lang == 'ur' ? 'بیٹری سائزنگ' : 'Battery Bank Sizer',
              subtitle: lang == 'ur' ? 'ٹیوبلر / لیتھیم وائرنگ حساب' : 'Tubular / LiFePO4 backup & series wiring',
              icon: Icons.battery_charging_full,
              isSelected: currentRoute == 'battery',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'battery') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BatterySizerScreen()),
                  );
                }
              },
            ),
            _buildDrawerTile(
              context: context,
              title: lang == 'ur' ? 'سولر پینل سائزنگ' : 'Solar Panel Sizer',
              subtitle: lang == 'ur' ? 'شہر دھوپ شعاع اور پینلز گنتی' : 'City peak sun hours & array wattage',
              icon: Icons.wb_sunny,
              isSelected: currentRoute == 'panel',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'panel') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PanelSizerScreen()),
                  );
                }
              },
            ),
            _buildDrawerTile(
              context: context,
              title: lang == 'ur' ? 'انورٹر چیکر' : 'Inverter Capacity Checker',
              subtitle: lang == 'ur' ? '80٪ حفاظتی مارجن اور گنجائش' : '80% rule safety headroom verification',
              icon: Icons.speed,
              isSelected: currentRoute == 'inverter',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'inverter') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InverterCheckerScreen()),
                  );
                }
              },
            ),
            _buildDrawerTile(
              context: context,
              title: lang == 'ur' ? 'بچت اور رقم واپسی (ROI)' : 'ROI & Payback Calculator',
              subtitle: lang == 'ur' ? 'واپڈا بل بچت اور نیٹ میٹرنگ' : 'WAPDA bill savings & 25-yr payoff',
              icon: Icons.trending_up,
              isSelected: currentRoute == 'roi',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != 'roi') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoiCalculatorScreen()),
                  );
                }
              },
            ),
            const Divider(),
            if (onOpenSettings != null)
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF1D9E75)),
                title: Text(
                  lang == 'ur' ? 'سیٹنگز اور پروفائل' : 'Settings & Profile',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onOpenSettings!();
                },
              ),
            ListTile(
              leading: Icon(
                appState.isPremium ? Icons.verified : Icons.verified_outlined,
                color: appState.isPremium ? Colors.amber : Colors.blueGrey,
              ),
              title: Text(
                appState.isPremium
                    ? (lang == 'ur' ? 'پریمیم فعال ہے' : 'Premium Active (Ad-Free)')
                    : (lang == 'ur' ? 'پریمیم موڈ ٹوگل کریں' : 'Unlock Premium (Ad-Free)'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                appState.togglePremium();
              },
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'RoshanGhar v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedTileColor: const Color(0xFF1D9E75).withValues(alpha: 0.12),
        selectedColor: const Color(0xFF1D9E75),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1D9E75) : const Color(0xFF4A5D4E),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
            color: isSelected ? const Color(0xFF1D9E75) : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }
}
