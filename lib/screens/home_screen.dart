import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
// import '../services/n8n_audit_service.dart';
import '../services/pdf_invoice_service.dart';
import '../services/solar_price_service.dart';
import '../services/whatsapp_service.dart';
import '../widgets/admob_banner.dart';
import '../widgets/app_drawer.dart';
import 'battery_sizer_screen.dart';
import 'inverter_checker_screen.dart';
import 'load_calculator_screen.dart';
import 'panel_sizer_screen.dart';
import 'roi_calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _mediumFridgeWatts = 400;
  static const int _acOnePointFiveTonWatts = 1100;

  // Sizing mode variables
  bool _manualInputActive = false;
  final TextEditingController _manualWattsController = TextEditingController(
    text: "1500",
  );
  final TextEditingController _manualKWhController = TextEditingController(
    text: "320",
  );

  // Live calculation & market pricing state
  bool _hasCustomItemizedOverrides = false;
  String _liveRatesStatus = 'Live Market Rates: October 2026';
  bool _isLoadingRates = false;

  // Language state: 'mix' (Roman Urdu Mix), 'ur' (Urdu), 'en' (English)
  String _activeLang = 'mix';
  bool _didHydrateProfile = false;
  // bool _isAuditing = false;

  // Appliance quantities
  int _fridgeCount = 1;
  bool _isFridgeInverter = true;
  int _acCount = 1;
  int _ovenCount = 1;
  int _fanCount = 4;
  int _dcFanCount = 0;
  int _bulbCount = 8;
  int _pumpCount = 1;

  // Selected parameters
  String _selectedCity = 'Lahore';
  String _selectedDisco = 'PESCO';
  String _selectedSlab = 'standard';
  String _selectedPanelId = 'jinko-585';
  bool _backupWanted = true;

  // Pro installer contact fields
  final _clientNameController = TextEditingController(text: "Haji Saleem Khan");
  final _installerNameController = TextEditingController(text: "Ahmed Raza");
  final _shopNameController = TextEditingController(
    text: "Al-Noor Solar Solutions",
  );
  final _phoneController = TextEditingController(text: "0300-1234567");
  final _licenseController = TextEditingController(text: "NEPRA-2024-1234");
  final _bankNameController = TextEditingController(text: "Meezan Bank");
  final _accountNoController = TextEditingController(text: "0012-1234567-01");
  String _selectedWarranty = "10-year warranty";

  // Detailed Bill-Of-Materials Itemized Controllers
  final TextEditingController _propPanelCountController =
      TextEditingController();
  final TextEditingController _propPanelPriceController =
      TextEditingController();
  final TextEditingController _propInverterPriceController =
      TextEditingController();
  final TextEditingController _propBatteryCountController =
      TextEditingController();
  final TextEditingController _propBatteryPriceController =
      TextEditingController();
  final TextEditingController _propBoxCountController = TextEditingController(
    text: "1",
  );
  final TextEditingController _propBoxPriceController = TextEditingController(
    text: "12000",
  );
  final TextEditingController _propWiringPriceController =
      TextEditingController(text: "35000");
  final TextEditingController _propEarthingPriceController =
      TextEditingController(text: "15000");
  final TextEditingController _propMountingPriceController =
      TextEditingController(text: "25000");
  final TextEditingController _propMc4PriceController = TextEditingController(
    text: "2500",
  );
  final TextEditingController _propLaborPriceController = TextEditingController(
    text: "20000",
  );

  // Pakistani Cities Peak Sun Hours (PSH) climate index
  final Map<String, double> _cityPSH = {
    'Karachi': 5.5,
    'Lahore': 4.8,
    'Islamabad': 4.5,
    'Peshawar': 5.0,
    'Quetta': 6.0,
    'Multan': 5.8,
    'Faisalabad': 4.9,
    'Attock': 4.7,
  };

  // Panel catalog
  final List<Map<String, dynamic>> _panelCatalog = [
    {
      'id': 'jinko-585',
      'name': 'Jinko Tiger Neo N-Type 585W',
      'brand': 'Jinko Solar',
      'nameplateWatts': 585,
      'realWatts': 470,
      'efficiency': 22.6,
      'pricePerWatt': 47.0,
      'descEn': 'Highly popular. Dual-glass bifacial with dust resistance.',
      'descUr': 'پاکستان کا مقبول ترین پینل۔ دھول مٹی اور گرمی میں بہترین۔',
      'descMix': 'Pakistan ka hit panel. Mitti aur garmi me behtareen output.',
    },
    {
      'id': 'canadian-585',
      'name': 'Canadian Solar N-Type 585W',
      'brand': 'Canadian Solar',
      'nameplateWatts': 585,
      'realWatts': 470,
      'efficiency': 22.5,
      'pricePerWatt': 47.0,
      'descEn': 'Premium dual-glass panel. Certified original tier-1.',
      'descUr': 'کینیڈین سولر پینل۔ انتہائی پائیدار گلاس جو دھوپ جذب کرے۔',
      'descMix': 'Canadian tier-1 original plate. Mazboot aur durable solar.',
    },
    {
      'id': 'trina-585',
      'name': 'Trina Vertex S+ N-Type 585W',
      'brand': 'Trina Solar',
      'nameplateWatts': 585,
      'realWatts': 470,
      'efficiency': 22.6,
      'pricePerWatt': 47.0,
      'descEn': 'Exceptional shading tolerance and heat ratio current.',
      'descUr': 'ٹرینا بہترین پینل۔ معمولی چھاؤں میں بھی کام جاری رکھے۔',
      'descMix': 'Trina Solar. Chhaon (shading) me bhi dynamic current out.',
    },
    {
      'id': 'longi-himo6-580',
      'name': 'Longi Hi-MO 6 Explorer 580W',
      'brand': 'Longi Solar',
      'nameplateWatts': 580,
      'realWatts': 464,
      'efficiency': 22.8,
      'pricePerWatt': 47.0,
      'descEn': 'Residential plate with advanced HPBC energy technology.',
      'descUr': 'لونگی ہائی مو 6۔ جدید ترین گنجائش اور طویل عمر۔',
      'descMix': 'Longi Himo 6 premium cell design, zyaada performance.',
    },
    {
      'id': 'longi-x10-700',
      'name': 'Longi Hi-MO X10 Premium 700W',
      'brand': 'Longi Solar',
      'nameplateWatts': 700,
      'realWatts': 565,
      'efficiency': 23.2,
      'pricePerWatt': 48.0,
      'descEn': 'Massive rating capacity. Save standard roof space density.',
      'descUr': 'لونگی 700 واٹ سپر سائز۔ کم جگہ پر زیادہ کرنٹ۔',
      'descMix': 'Sabar se bara high tech panel. Kam space me double current.',
    },
  ];

  // Translations dictionary
  final Map<String, Map<String, String>> _labels = {
    'en': {
      'appName': 'RoshanGhar',
      'tagline': 'Solar Sizing & Custom Invoice Generator',
      'easyPresets': '⚡ One-Tap Super Presets (Asaan Load)',
      'presetSmall': 'Chota Ghar (Small)',
      'presetMedium': 'Medium Home (Mera Ghar)',
      'presetKothi': 'Kothi / Heavy Villa',
      'sizingMethod': 'Sizing Method',
      'tapAppliances': 'Choose Appliances',
      'typeWattsDirectly': 'Type Watts Directly',
      'backupQuestion': 'Do you want Battery Backup?',
      'backupYes': 'Yes, with Batteries',
      'backupNo': 'No, Solar Only (Sasta)',
      'activeLoad': 'Active Load Power',
      'monthlySavings': 'Bill Savings/Month',
      'paybackYears': 'Paisa Vasool period',
      'proDetailsTitle': 'Pro Invoices & Detailed Itemized Setup',
      'nomVsRealTitle': '💡 Real-World vs Paper Sizer Secrets',
      'explanationText':
          'Solar panels have printed labels like "585W". Due to extreme heat temperatures & settling dust in Pakistan, standard 585W panels yield between 460W-485W. Sizing with de-rated real output guarantees your system never fails in July!',
      'clientName': 'Client / Customer Name',
      'warrantyDuration': 'Assured Warranty Detail',
      'installerName': 'Designer / Installer Name',
      'shopName': 'Shop / Business Name',
      'phone': 'Phone / Contact details',
      'bankDetails': 'Bank & Branch Name',
      'accountNo': 'Account / IBAN Number',
      'generatePdf': 'Generate Detailed PDF Quotation',
      'selectCity': '1. Choose City Location (Solar Sun Intensity)',
      'selectDisco': '2. Choose Electricity Provider (DISCO)',
      'selectSlab': '3. Monthly Units Slab (WAPDA Tariff Rate)',
      'selectPanel': '4. Solar Panel Model & De-rated Specs',
      'nepraLicense': 'Installer NEPRA License Code',
      'loadWatts': 'Total load power (Watts):',
      'monthlyKWh': 'Approx. Units / Month (KWh):',
    },
    'ur': {
      'appName': 'روشن گھر',
      'tagline': 'سولر کیلکولیٹر اور پروفیشنل انوائس جنریٹر',
      'easyPresets': '⚡ ایک کلک آسان گھریلو پری سیٹس',
      'presetSmall': 'چھوٹا گھر (بغیر اے سی)',
      'presetMedium': 'درمیانہ گھر (اے سی کے ساتھ)',
      'presetKothi': 'کوٹھی / بڑا گھر',
      'sizingMethod': 'حساب کا طریقہ کار',
      'tapAppliances': 'آلات منتخب کریں',
      'typeWattsDirectly': 'خود واٹس لکھیں',
      'backupQuestion': 'کیا آپ کو بیٹری بیک اب چاہیے؟',
      'backupYes': 'جی ہاں (بیٹریوں کے ساتھ)',
      'backupNo': 'جی نہیں (صرف دن کا آن گرڈ)',
      'activeLoad': 'کل بوجھ کا حساب',
      'monthlySavings': 'ماہانہ بل کی بچت',
      'paybackYears': 'رقم واپسی دورانیہ',
      'proDetailsTitle': 'پرو انوائس اور تفصیلی آئٹمز سیٹنگز',
      'nomVsRealTitle': '💡 سولر پینل کی اصل کارکردگی کا راز',
      'explanationText':
          'پاکستان کی تپتی دھوپ اور چمک کی وجہ سے پلیٹ پر پانچ سو پچاسی واٹ لکھا ہوتا ہے لیکن اصل میں یہ چار سو ستر واٹ تک کرنٹ دیتی ہے۔ ہم نے اندازی حساب اصل کرنٹ کی بنیاد پر لگایا ہے تاکہ آپ کا سسٹم کبھی ناکام نہ ہو!',
      'clientName': 'گاہک کا نام',
      'warrantyDuration': 'سسٹم کی وارنٹی',
      'installerName': 'انسٹالر کا نام',
      'shopName': 'دکان کا نام',
      'phone': 'فون نمبر',
      'bankDetails': 'بینک کا نام',
      'accountNo': 'بینک اکاؤنٹ نمبر',
      'generatePdf': 'پی ڈی ایف رپورٹ ڈاؤن لوڈ کریں',
      'selectCity': '۱۔ اپنا شہر منتخب کریں (دھوپ کا دورانیہ)',
      'selectDisco': '۲۔ بجلی فراہم کرنے والی کمپنی منتخب کریں',
      'selectSlab': '۳۔ ماہانہ یونٹ سلیب منتخب کریں (ٹیرف ریٹ)',
      'selectPanel': '۴۔ سولر پینل برانڈ اور اصل کرنٹ تفصیل',
      'nepraLicense': 'نیپرا رجسٹریشن کوڈ',
      'loadWatts': 'کل بوجھ واٹ میں لکھیں:',
      'monthlyKWh': 'ماہانہ بجلی یونٹس لکھیں (KWh):',
    },
    'mix': {
      'appName': 'RoshanGhar',
      'tagline': 'Solar Calculator aur Pro Invoice Generator',
      'easyPresets': '⚡ Ek Click Asaan Ghar ke Presets',
      'presetSmall': 'Chota Ghar (Bina AC ke)',
      'presetMedium': 'Darmiyana Ghar (AC ke Saath)',
      'presetKothi': 'Bara Ghar / Kothi Load',
      'sizingMethod': 'Sizing ka tareeqa',
      'tapAppliances': 'Appliances tap karein',
      'typeWattsDirectly': 'Watts direct likhein',
      'backupQuestion': 'Kya aapko battery backup chahiye?',
      'backupYes': 'Ji Haan (Battery + Hybrid)',
      'backupNo': 'Ji Nahi (Solar direct - Sasta)',
      'activeLoad': 'Ghar Ka Active Load',
      'monthlySavings': 'Mahana Bill me Bachat',
      'paybackYears': 'Paisa Vasool period',
      'proDetailsTitle': 'Pro Invoice & Detailed Itemized Settings',
      'nomVsRealTitle': '💡 Solar Plate ki Asli Output vs Paper Formula',
      'explanationText':
          'Solar plate par 585W likha hota hai, lekin Pakistan ki extreme garmi aur mitti ki wajah se real output kam hoti hai. Humne calculation bilkul real output 470W par ki hai taake aapka system bina fault ke chale!',
      'clientName': 'Client ka Naam',
      'warrantyDuration': 'Warranty Duration Details',
      'installerName': 'Installer ka Naam',
      'shopName': 'Shop / Business Name',
      'phone': 'Phone / Contact details',
      'bankDetails': 'Bank ka Naam',
      'accountNo': 'Account / IBAN Number',
      'generatePdf': 'Generate PDF Invoice & Summary',
      'selectCity': '1. Choose City Location (Solar Sun Intensity)',
      'selectDisco': '2. Choose Electricity Provider (DISCO)',
      'selectSlab': '3. Monthly Units Slab (WAPDA Tariff)',
      'selectPanel': '4. Solar Panel Model & De-rated Specs',
      'nepraLicense': 'NEPRA License / Reg Code',
      'loadWatts': 'Ghar Ka Total Load (Watts):',
      'monthlyKWh': 'Expected Monthly Units (KWh):',
    },
  };

  String _t(String key) {
    return _labels[_activeLang]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLiveMarketRates();
  }

  Future<void> _loadLiveMarketRates({bool fetchOnline = false}) async {
    if (_isLoadingRates) return;
    setState(() => _isLoadingRates = true);
    try {
      final rates = fetchOnline
          ? await SolarPriceService.fetchLiveRates()
          : await SolarPriceService.getPanelRates();
      final updatedText = await SolarPriceService.getLastUpdatedText();
      if (mounted) {
        setState(() {
          for (var panel in _panelCatalog) {
            final id = panel['id'] as String;
            if (rates.containsKey(id)) {
              panel['pricePerWatt'] = rates[id]!;
            }
          }
          _liveRatesStatus = 'Live Rates: $updatedText';
          _isLoadingRates = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRates = false);
    }
  }

  void _showLiveMarketPricesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, color: Color(0xFF1D9E75), size: 22),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pakistan Solar Market Rates',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_liveRatesStatus • Per-watt Tier-1 retail rates',
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 18),
                      ..._panelCatalog.map((p) {
                        final isSelected = p['id'] == _selectedPanelId;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1D9E75).withValues(alpha: 0.08) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1D9E75) : Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "${p['nameplateWatts']}W plate • ${p['brand']}",
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Rs. ${p['pricePerWatt']} / W",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Color(0xFF1D9E75),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D9E75),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: _isLoadingRates
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: Text(_isLoadingRates ? 'Pulling Market Rates...' : 'Refresh Live Rates Now'),
                        onPressed: _isLoadingRates
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setSheetState(() => _isLoadingRates = true);
                                await _loadLiveMarketRates(fetchOnline: true);
                                setSheetState(() => _isLoadingRates = false);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Live market rates updated & applied to calculations!'),
                                    backgroundColor: Color(0xFF1D9E75),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateProfile) return;
    final appState = Provider.of<SolarAppState>(context, listen: false);
    _activeLang = appState.languageCode;
    if (appState.userName.isNotEmpty) {
      _installerNameController.text = appState.userName;
    }
    if (appState.installerAccountNumber.isNotEmpty) {
      _accountNoController.text = appState.installerAccountNumber;
    }
    _didHydrateProfile = true;
  }

  // Live Sync calculation variables onto editable proposal settings textboxes
  void _syncProFieldsWithCalculator({
    required int panelsCount,
    required double panelPrice,
    required double inverterCost,
    required int recommendedBatteryCount,
    required double batteryPrice,
  }) {
    setState(() {
      _hasCustomItemizedOverrides = false;
      _propPanelCountController.text = panelsCount.toString();
      _propPanelPriceController.text = panelPrice.toStringAsFixed(0);
      _propInverterPriceController.text = inverterCost.toStringAsFixed(0);
      _propBatteryCountController.text = recommendedBatteryCount.toString();
      _propBatteryPriceController.text = batteryPrice.toStringAsFixed(0);
      _propBoxCountController.text = panelsCount > 0 ? "1" : "0";
      _propBoxPriceController.text = "12000";
      _propWiringPriceController.text = panelsCount > 0 ? "30000" : "0";
      _propEarthingPriceController.text = panelsCount > 0 ? "15000" : "0";
      _propMountingPriceController.text = (panelsCount * 3000).toStringAsFixed(0);
      _propMc4PriceController.text = panelsCount > 0 ? "2500" : "0";
      _propLaborPriceController.text = panelsCount > 0 ? (15000 + panelsCount * 500).toStringAsFixed(0) : "0";
    });

    // Toast alert feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _activeLang == 'en'
              ? '✅ Pro itemized fields synchronized with current solar calculations!'
              : _activeLang == 'ur'
              ? 'سولر حساب تفصیلی فیلڈز کے ساتھ سنکرونائز ہو گیا ہے۔ ✓'
              : 'Sizing fields synced with system calculations! ✓',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1D9E75),
      ),
    );
  }

  // Apply quick presets
  void _applyPreset(String preset) {
    setState(() {
      _hasCustomItemizedOverrides = false;
      _manualInputActive = false;
      if (preset == 'small') {
        _fridgeCount = 1;
        _isFridgeInverter = false;
        _acCount = 0;
        _ovenCount = 0;
        _fanCount = 2;
        _dcFanCount = 1;
        _bulbCount = 6;
        _pumpCount = 0;
      } else if (preset == 'medium') {
        _fridgeCount = 1;
        _isFridgeInverter = true;
        _acCount = 1;
        _ovenCount = 1;
        _fanCount = 4;
        _dcFanCount = 0;
        _bulbCount = 8;
        _pumpCount = 1;
      } else if (preset == 'kothi') {
        _fridgeCount = 2;
        _isFridgeInverter = true;
        _acCount = 3;
        _ovenCount = 2;
        _fanCount = 10;
        _dcFanCount = 2;
        _bulbCount = 20;
        _pumpCount = 2;
      }
    });
  }



  @override
  void dispose() {
    _manualWattsController.dispose();
    _manualKWhController.dispose();
    _clientNameController.dispose();
    _installerNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();

    _propPanelCountController.dispose();
    _propPanelPriceController.dispose();
    _propInverterPriceController.dispose();
    _propBatteryCountController.dispose();
    _propBatteryPriceController.dispose();
    _propBoxCountController.dispose();
    _propBoxPriceController.dispose();
    _propWiringPriceController.dispose();
    _propEarthingPriceController.dispose();
    _propMountingPriceController.dispose();
    _propMc4PriceController.dispose();
    _propLaborPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<SolarAppState>(context);

    // Compute load mathematics dynamically
    final int fridgeWatts = _isFridgeInverter ? 150 : _mediumFridgeWatts;
    final int calculatedLoadWatts =
        (_fanCount * 90) +
        (_dcFanCount * 40) +
        (_bulbCount * 18) +
        (_fridgeCount * fridgeWatts) +
        (_acCount * _acOnePointFiveTonWatts) +
        (_ovenCount * 1200) +
        (_pumpCount * 1200);

    final int activeLoadWatts = _manualInputActive
        ? (int.tryParse(_manualWattsController.text) ?? 1500)
        : calculatedLoadWatts;

    final double calculatedDailyKWh =
        ((_fridgeCount * fridgeWatts * 10) +
            (_fanCount * 90 * 12) +
            (_dcFanCount * 40 * 12) +
            (_bulbCount * 18 * 8) +
            (_acCount * _acOnePointFiveTonWatts * 6) +
            (_ovenCount * 1200 * 0.8) +
            (_pumpCount * 1200 * 1.5)) /
        1000.0;

    final double activeDailyKWh = _manualInputActive
        ? ((double.tryParse(_manualKWhController.text) ?? 320.0) / 30.0)
        : calculatedDailyKWh;

    final double activeMonthlyKWh = activeDailyKWh * 30.0;

    // Get active panel attributes
    final activePanel = _panelCatalog.firstWhere(
      (p) => p['id'] == _selectedPanelId,
      orElse: () => _panelCatalog[0],
    );
    final int panelNominalWatts = activePanel['nameplateWatts'] as int;
    final int panelRealWatts = activePanel['realWatts'] as int;
    final double panelPricePerWatt = activePanel['pricePerWatt'] as double;
    final double panelPrice = panelNominalWatts * panelPricePerWatt;

    // Sizing panels array based on dynamic selected city climate irradiation coefficients
    final double activePSH = _cityPSH[_selectedCity] ?? 5.0;
    final double dailyGenPerPanelKWh = (panelRealWatts * activePSH) / 1000.0;
    final int panelsCount = activeDailyKWh > 0
        ? (activeDailyKWh / dailyGenPerPanelKWh).ceil()
        : 0;
    // Calculate Inverter scale needed with safe buffer
    double suggestedInverterKW = 0.0;
    if (activeLoadWatts <= 0) {
      suggestedInverterKW = 0.0;
    } else if (activeLoadWatts <= 1200) {
      suggestedInverterKW = 2.5;
    } else if (activeLoadWatts <= 2800) {
      suggestedInverterKW = 3.6;
    } else if (activeLoadWatts <= 4500) {
      suggestedInverterKW = 6.0;
    } else if (activeLoadWatts <= 9000) {
      suggestedInverterKW = 10.0;
    } else {
      suggestedInverterKW = 15.0;
    }

    // Suggested inverter baseline cost
    double inverterCost = 0.0;
    if (suggestedInverterKW <= 0.0) {
      inverterCost = 0.0;
    } else if (_backupWanted) {
      // Hybrid pricing
      if (suggestedInverterKW <= 2.5) {
        inverterCost = 135000;
      } else if (suggestedInverterKW <= 3.6) {
        inverterCost = 165000;
      } else if (suggestedInverterKW <= 6.0) {
        inverterCost = 245000;
      } else if (suggestedInverterKW <= 10.0) {
        inverterCost = 395000;
      } else {
        inverterCost = 530000;
      }
    } else {
      // Daytime Only grid-tied pricing
      if (suggestedInverterKW <= 2.5) {
        inverterCost = 40000;
      } else if (suggestedInverterKW <= 3.6) {
        inverterCost = 55000;
      } else if (suggestedInverterKW <= 6.0) {
        inverterCost = 90000;
      } else if (suggestedInverterKW <= 10.0) {
        inverterCost = 145000;
      } else {
        inverterCost = 205000;
      }
    }

    // Battery Bank Suggestion & Costs for power outages
    String batteriesSuggestion = 'None (Daytime system direct grid bypass)';
    double batteriesCost = 0.0;
    int recommendedBatteryCount = 0;
    if (_backupWanted && activeLoadWatts > 0) {
      if (activeLoadWatts <= 600) {
        batteriesSuggestion = '1x 12V 180Ah Tall Tubular acid battery';
        recommendedBatteryCount = 1;
        batteriesCost = 29500;
      } else if (activeLoadWatts <= 1500) {
        batteriesSuggestion = '2x 12V 180Ah Tubular batteries (24V Series)';
        recommendedBatteryCount = 2;
        batteriesCost = 59000;
      } else {
        batteriesSuggestion =
            '4x 12V 180Ah Tubular batteries (48V String connection)';
        recommendedBatteryCount = 4;
        batteriesCost = 118000;
      }
    }

    final double actualBatteryCostUnit = recommendedBatteryCount > 0
        ? batteriesCost / recommendedBatteryCount
        : 29500.0;

    // Compile Dynamic Total Bill of Materials based on current values in controllers (or fallback to calculator)
    final int uiPanelCount = _hasCustomItemizedOverrides
        ? (int.tryParse(_propPanelCountController.text) ?? panelsCount)
        : panelsCount;
    final double uiPanelPrice = _hasCustomItemizedOverrides
        ? (double.tryParse(_propPanelPriceController.text) ?? panelPrice)
        : panelPrice;
    final double uiInverterCost = _hasCustomItemizedOverrides
        ? (double.tryParse(_propInverterPriceController.text) ?? (panelsCount > 0 ? inverterCost : 0.0))
        : (panelsCount > 0 ? inverterCost : 0.0);
    final int uiBatteryCount = _hasCustomItemizedOverrides
        ? (int.tryParse(_propBatteryCountController.text) ?? (panelsCount > 0 ? recommendedBatteryCount : 0))
        : (panelsCount > 0 ? recommendedBatteryCount : 0);
    final double uiBatteryPrice = _hasCustomItemizedOverrides
        ? (double.tryParse(_propBatteryPriceController.text) ?? actualBatteryCostUnit)
        : actualBatteryCostUnit;
    final int uiBoxCount = _hasCustomItemizedOverrides
        ? (int.tryParse(_propBoxCountController.text) ?? (panelsCount > 0 ? 1 : 0))
        : (panelsCount > 0 ? 1 : 0);
    final double uiBoxPrice = _hasCustomItemizedOverrides
        ? (double.tryParse(_propBoxPriceController.text) ?? 12000.0)
        : (panelsCount > 0 ? 12000.0 : 0.0);

    final double uiWiringCost = _hasCustomItemizedOverrides
        ? (double.tryParse(_propWiringPriceController.text) ?? (panelsCount > 0 ? 30000.0 : 0.0))
        : (panelsCount > 0 ? 30000.0 : 0.0);
    final double uiEarthingCost = _hasCustomItemizedOverrides
        ? (double.tryParse(_propEarthingPriceController.text) ?? (panelsCount > 0 ? 15000.0 : 0.0))
        : (panelsCount > 0 ? 15000.0 : 0.0);
    final double uiMountingCost = _hasCustomItemizedOverrides
        ? (double.tryParse(_propMountingPriceController.text) ?? (panelsCount * 3000.0))
        : (panelsCount * 3000.0);
    final double uiMc4Cost = _hasCustomItemizedOverrides
        ? (double.tryParse(_propMc4PriceController.text) ?? (panelsCount > 0 ? 2500.0 : 0.0))
        : (panelsCount > 0 ? 2500.0 : 0.0);
    final double uiLaborCost = _hasCustomItemizedOverrides
        ? (double.tryParse(_propLaborPriceController.text) ?? (panelsCount > 0 ? 15000.0 + panelsCount * 500.0 : 0.0))
        : (panelsCount > 0 ? 15000.0 + panelsCount * 500.0 : 0.0);

    // Keep proposal controllers synchronized with live calculations when not overridden
    if (!_hasCustomItemizedOverrides) {
      _propPanelCountController.text = uiPanelCount.toString();
      _propPanelPriceController.text = uiPanelPrice.toStringAsFixed(0);
      _propInverterPriceController.text = uiInverterCost.toStringAsFixed(0);
      _propBatteryCountController.text = uiBatteryCount.toString();
      _propBatteryPriceController.text = uiBatteryPrice.toStringAsFixed(0);
      _propBoxCountController.text = uiBoxCount.toString();
      _propBoxPriceController.text = uiBoxPrice.toStringAsFixed(0);
      _propWiringPriceController.text = uiWiringCost.toStringAsFixed(0);
      _propEarthingPriceController.text = uiEarthingCost.toStringAsFixed(0);
      _propMountingPriceController.text = uiMountingCost.toStringAsFixed(0);
      _propMc4PriceController.text = uiMc4Cost.toStringAsFixed(0);
      _propLaborPriceController.text = uiLaborCost.toStringAsFixed(0);
    }

    final double panelCostSum = uiPanelCount * uiPanelPrice;
    final double inverterCostSum = uiInverterCost;
    final double boxCostSum = uiBoxCount * uiBoxPrice;
    final double batteryCostSum = uiBatteryCount * uiBatteryPrice;

    // Cumulative system quotation sum
    final double computedTotalCostPKR = (panelsCount == 0 && !_hasCustomItemizedOverrides)
        ? 0.0
        : (panelCostSum +
            inverterCostSum +
            boxCostSum +
            batteryCostSum +
            uiWiringCost +
            uiEarthingCost +
            uiMountingCost +
            uiMc4Cost +
            uiLaborCost);

    // Apply WAPDA grid base tariff based on slab selection and regional adjustments (PESCO/LESCO/IESCO/KE)
    double wapdaRate = 48.0;
    if (_selectedSlab == 'protected') {
      wapdaRate = 24.0;
    } else if (_selectedSlab == 'standard') {
      wapdaRate = 48.0;
    } else if (_selectedSlab == 'heavy') {
      wapdaRate = 62.0;
    } else if (_selectedSlab == 'commercial') {
      wapdaRate = 74.0;
    }

    if (_selectedDisco == 'KE') {
      wapdaRate += 4.0; // KE peaks fuel adjustment
    } else if (_selectedDisco == 'IESCO') {
      wapdaRate -= 2.0;
    }

    final double monthlySavingsPKR = activeMonthlyKWh * wapdaRate;
    final double annualSavingsPKR = monthlySavingsPKR * 12.0;
    final double paybackPeriodYears = (annualSavingsPKR > 0 && computedTotalCostPKR > 0)
        ? (computedTotalCostPKR / annualSavingsPKR)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F3),
      drawer: AppDrawer(
        currentRoute: 'home',
        onOpenSettings: () => _showSettingsSheet(appState),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _t('appName'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF4A5D4E),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showSettingsSheet(appState),
          ),
          // Language selection toggle
          InkWell(
            onTap: () {
              setState(() {
                if (_activeLang == 'mix') {
                  _activeLang = 'ur';
                } else if (_activeLang == 'ur') {
                  _activeLang = 'en';
                } else {
                  _activeLang = 'mix';
                }
              });
              appState.setLanguage(_activeLang);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.language,
                    color: Color(0xFFFAEDCD),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _activeLang == 'en'
                        ? 'ENG'
                        : _activeLang == 'ur'
                        ? 'اردو'
                        : 'MIX',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Premium badge status indicator
          IconButton(
            icon: Icon(
              appState.isPremium ? Icons.verified : Icons.verified_outlined,
              color: appState.isPremium
                  ? const Color(0xFFFAEDCD)
                  : Colors.white60,
              size: 26,
            ),
            onPressed: () {
              appState.togglePremium();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                // Real-time market subtitle
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _t('tagline'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8B7E5D),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                // Dedicated Sizers & Calculators Quick Access
                _buildQuickToolsRow(),
                const SizedBox(height: 10),

                // ⚡ Rapid One-Tap Super Presets
                Card(
                  color: const Color(0xFFFAEDCD).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('easyPresets'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8B7E5D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPresetButton(
                                'small',
                                _t('presetSmall'),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildPresetButton(
                                'medium',
                                _t('presetMedium'),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildPresetButton(
                                'kothi',
                                _t('presetKothi'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 📐 Sizing Calculation Trigger Selector (Toggle vs Manual list)
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE9E1CC), width: 1),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('sizingMethod').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Color(0xFF4A5D4E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _t('tapAppliances'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: !_manualInputActive
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                selected: !_manualInputActive,
                                selectedColor: const Color(0xFF4A5D4E),
                                disabledColor: Colors.white,
                                showCheckmark: false,
                                onSelected: (selected) {
                                  setState(() {
                                    _manualInputActive = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _t('typeWattsDirectly'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: _manualInputActive
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                selected: _manualInputActive,
                                selectedColor: const Color(0xFF4A5D4E),
                                disabledColor: Colors.white,
                                showCheckmark: false,
                                onSelected: (selected) {
                                  setState(() {
                                    _manualInputActive = true;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_manualInputActive) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _manualWattsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: _t('loadWatts'),
                              suffixText: 'W',
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _manualKWhController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              labelText: _t('monthlyKWh'),
                              suffixText: 'Units',
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Core Pakistani appliances config lists
                if (!_manualInputActive) ...[
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Color(0xFFE9E1CC),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _activeLang == 'en'
                                      ? 'Tap to Configure Appliances'
                                      : _activeLang == 'ur'
                                      ? 'گھریلو آلات کو تبدیل کریں'
                                      : 'Apne appliances configure karein',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Color(0xFF4A5D4E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _fridgeCount = 0;
                                    _acCount = 0;
                                    _ovenCount = 0;
                                    _fanCount = 0;
                                    _dcFanCount = 0;
                                    _bulbCount = 0;
                                    _pumpCount = 0;
                                  });
                                },
                                child: Text(
                                  _activeLang == 'en' ? 'Clear' : 'صاف کریں',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildApplianceItem(
                            icon: '❄️',
                            name: _activeLang == 'mix'
                                ? 'Fridge / Refrigerator'
                                : _activeLang == 'ur'
                                ? 'فریج / ریفریجریٹر'
                                : 'Refrigerator (Fridge)',
                            subtitle: _isFridgeInverter
                                ? '150W low-draw'
                                : '${_mediumFridgeWatts}W medium-draw',
                            count: _fridgeCount,
                            showInverterCheckbox: true,
                            onDec: () => _fridgeCount > 0
                                ? setState(() => _fridgeCount--)
                                : null,
                            onInc: () => setState(() => _fridgeCount++),
                            onCheckboxChanged: (val) {
                              setState(() {
                                _isFridgeInverter = val ?? false;
                              });
                            },
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          _buildApplianceItem(
                            icon: '💨',
                            name: _activeLang == 'ur'
                                ? 'انورٹر اے سی (1.5 ٹن)'
                                : '1.5 Ton Inverter AC',
                            subtitle:
                                '${_acOnePointFiveTonWatts}W constant load',
                            count: _acCount,
                            onDec: () => _acCount > 0
                                ? setState(() => _acCount--)
                                : null,
                            onInc: () => setState(() => _acCount++),
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          _buildApplianceItem(
                            icon: '🍲',
                            name: _activeLang == 'ur'
                                ? 'مائیکرو ویو / اوون'
                                : 'Microwave / Baking Oven',
                            subtitle: '1200W peak surge',
                            count: _ovenCount,
                            onDec: () => _ovenCount > 0
                                ? setState(() => _ovenCount--)
                                : null,
                            onInc: () => setState(() => _ovenCount++),
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          _buildApplianceItem(
                            icon: '🌀',
                            name: _activeLang == 'ur'
                                ? 'پنکھے (اے سی)'
                                : 'Ceiling Fans (AC)',
                            subtitle: '90W standard rating',
                            count: _fanCount,
                            onDec: () => _fanCount > 0
                                ? setState(() => _fanCount--)
                                : null,
                            onInc: () => setState(() => _fanCount++),
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          _buildApplianceItem(
                            icon: '🔌',
                            name: _activeLang == 'ur'
                                ? 'ڈی سی فین (بہترین بچت)'
                                : 'DC Fans (12V / Heavy Saving)',
                            subtitle: '40W direct efficient',
                            count: _dcFanCount,
                            onDec: () => _dcFanCount > 0
                                ? setState(() => _dcFanCount--)
                                : null,
                            onInc: () => setState(() => _dcFanCount++),
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          _buildApplianceItem(
                            icon: '💡',
                            name: _activeLang == 'ur'
                                ? 'ایل ای ڈی بلب'
                                : 'LED Bulbs / Lights',
                            subtitle: '18W loading',
                            count: _bulbCount,
                            onDec: () => _bulbCount > 0
                                ? setState(() => _bulbCount--)
                                : null,
                            onInc: () => setState(() => _bulbCount++),
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          _buildApplianceItem(
                            icon: '💧',
                            name: _activeLang == 'ur'
                                ? 'پانی کی موٹر پمپ'
                                : 'Water Motor Pump',
                            subtitle: '0.75 HP (1200W steady)',
                            count: _pumpCount,
                            onDec: () => _pumpCount > 0
                                ? setState(() => _pumpCount--)
                                : null,
                            onInc: () => setState(() => _pumpCount++),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ⚡ DISCO, Slab, Panel and Location parameters dropdown Card
                Card(
                  color: const Color(0xFFFAEDCD).withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // City selection location
                        Text(
                          _t('selectCity').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF8B7E5D),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          isExpanded: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: _cityPSH.keys.map((city) {
                            return DropdownMenuItem(
                              value: city,
                              child: Text(
                                "$city (${_cityPSH[city]} PSH / Day Radiation)",
                                overflow: TextOverflow.ellipsis,
                              ),
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
                        const SizedBox(height: 12),

                        // Disco selector
                        Text(
                          _t('selectDisco').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF8B7E5D),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: ['PESCO', 'LESCO', 'IESCO', 'KE'].map((
                            disco,
                          ) {
                            final isSel = _selectedDisco == disco;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedDisco = disco),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? const Color(0xFF4A5D4E)
                                          : Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFFE9E1CC),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        disco,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          color: isSel
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Slab selector
                        Text(
                          _t('selectSlab').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF8B7E5D),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSlab,
                          isExpanded: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'protected',
                              child: Text(
                                _activeLang == 'en'
                                    ? 'Protected Slab (<200 Units / Rs. 24)'
                                    : 'کم بجٹ سلیب (۲۰۰ سے کم و ۲۴ روپے)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'standard',
                              child: Text(
                                _activeLang == 'en'
                                    ? 'Standard Home (200-500 Units / Rs. 48)'
                                    : 'گھریلو فل ریٹ (۲۰۰ سے ۵۰۰ و ۴۸ روپے)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'heavy',
                              child: Text(
                                _activeLang == 'en'
                                    ? 'Heavy AC Home (500-1000 Units / Rs. 62)'
                                    : 'بھاری اے سی لوڈ (۵۰۰ سے ۱۰۰۰ و ۶۲ روپے)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'commercial',
                              child: Text(
                                _activeLang == 'en'
                                    ? 'Commercial Slab (>1000 Units / Rs. 74)'
                                    : 'کمرشل دکان ریٹ (ہزار سے زائد و ۷۴ روپے)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSlab = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Panel dropdown select
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _t('selectPanel').toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: Color(0xFF8B7E5D),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _showLiveMarketPricesDialog,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF1D9E75).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.show_chart, size: 12, color: Color(0xFF1D9E75)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isLoadingRates ? 'Pulling...' : 'Live Market Rates',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D9E75),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPanelId,
                          isExpanded: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 11,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: _panelCatalog.map((panel) {
                            return DropdownMenuItem<String>(
                              value: panel['id'] as String,
                              child: Text(
                                "${panel['brand']} - ${panel['nameplateWatts']}W (${panel['realWatts']}W Real • Rs. ${panel['pricePerWatt']}/W)",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPanelId = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),

                        // Real-World efficiency warning info panel
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE9E1CC)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "⚡ ${activePanel['name']}: ${_activeLang == 'ur'
                                ? activePanel['descUr']
                                : _activeLang == 'mix'
                                ? activePanel['descMix']
                                : activePanel['descEn']}",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 🔋 Battery Backup Toggle Row
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _t('backupQuestion').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Color(0xFF4A5D4E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _backupWanted = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _backupWanted
                                        ? const Color(0xFF4A5D4E)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFFE9E1CC),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _t('backupYes'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: _backupWanted
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _backupWanted = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_backupWanted
                                        ? const Color(0xFFD4A373)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFFE9E1CC),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _t('backupNo'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: !_backupWanted
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 📊 Real World efficiency info card
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Color(0xFF4A5D4E),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _t('nomVsRealTitle'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Color(0xFF4A5D4E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _t('explanationText'),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey[800],
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 📝 Live System Sizing Sizer Output Proposal
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(
                      color: Color(0xFFE9E1CC),
                      width: 1.8,
                    ),
                  ),
                  elevation: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.assignment,
                                    color: Color(0xFF4A5D4E),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _activeLang == 'en'
                                          ? 'LIVE SYSTEM PROPOSAL'
                                          : _activeLang == 'ur'
                                          ? 'سولر تجویزاتی رپورٹ'
                                          : 'LIVE SYSTEM PROPOSAL',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: Color(0xFF4A5D4E),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_hasCustomItemizedOverrides)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _hasCustomItemizedOverrides = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Switched back to Live System Calculation mode! ✓'),
                                      backgroundColor: Color(0xFF1D9E75),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber[700]!, width: 0.5),
                                  ),
                                  child: const Text(
                                    'Custom (Tap to Sync)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '⚡ Live Synced',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D9E75),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 1.5),

                        _buildOutputDetailRow(
                          label: _activeLang == 'en'
                              ? 'Suggested Inverter'
                              : 'تجویز کردہ انورٹر',
                          value:
                              "${suggestedInverterKW.toStringAsFixed(1)} kW ${_backupWanted ? 'Hybrid Series' : 'Day-time OnGrid'}",
                          desc: _activeLang == 'en'
                              ? 'Cushioned for compressor/motor starts & continuous loads.'
                              : 'موٹر اور کمپریسر بوجھ اٹھانے کے لیے بہترین گنجائش۔',
                        ),
                        const SizedBox(height: 10),
                        _buildOutputDetailRow(
                          label: _activeLang == 'en'
                              ? 'Suggested Solar Array'
                              : 'درکار سولر پینلز',
                          value:
                              "$panelsCount Plates x $panelNominalWatts W Label",
                          desc: _activeLang == 'en'
                              ? "Approx. ${((panelsCount * panelNominalWatts) / 1000.0).toStringAsFixed(2)} kW nominal roof array recomendation."
                              : "کل سولر پلیٹیں: $panelsCount پینلز (چھت کی جگہ کلو واٹ: ${((panelsCount * panelNominalWatts) / 1000.0).toStringAsFixed(2)})۔",
                        ),
                        const SizedBox(height: 10),
                        _buildOutputDetailRow(
                          label: _activeLang == 'en'
                              ? 'Battery Bank Suggestion'
                              : 'درکار بیٹریاں',
                          value: _backupWanted
                              ? batteriesSuggestion
                              : 'Direct Day-Run (Bina Battery - Sasta)',
                          desc: _activeLang == 'en'
                              ? 'Holds continuous fan/refrigerator operations during loadshedding.'
                              : 'لوڈشیڈنگ کے وقت ضروری اشیاء چلانے کے لیے۔',
                        ),
                        const Divider(height: 20, thickness: 1.0),

                        // Financial variables sum
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _activeLang == 'en'
                                    ? 'Est. Sized Investment:'
                                    : _activeLang == 'ur'
                                    ? 'کل اندازاً لاگت:'
                                    : 'Est. Sized Investment (PKR):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "Rs. ${computedTotalCostPKR.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF1D9E75),
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${_t('monthlySavings')}:",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blueGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "Rs. ${monthlySavingsPKR.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Colors.teal,
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${_t('paybackYears')}:",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.blueGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                "${paybackPeriodYears.toStringAsFixed(1)} ${_activeLang == 'en' ? 'Years' : 'سال'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 📂 Collapsible ExpansionTile for "Pro Details & Itemized BOM Invoice Setup"
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE9E1CC), width: 1),
                  ),
                  elevation: 0.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.settings_suggest,
                          color: Color(0xFF1D9E75),
                          size: 24,
                        ),
                        title: Text(
                          _t('proDetailsTitle'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Color(0xFF1D9E75),
                            letterSpacing: -0.2,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        children: [
                          const Divider(height: 10, thickness: 1.0),
                          const SizedBox(height: 8),

                          // Trigger button to load current calculator estimations immediately!
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1D9E75,
                              ).withValues(alpha: 0.08),
                              foregroundColor: const Color(0xFF1D9E75),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              "Auto-populate fields from current calculations",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () {
                              _syncProFieldsWithCalculator(
                                panelsCount: panelsCount,
                                panelPrice: panelPrice,
                                inverterCost: inverterCost,
                                recommendedBatteryCount:
                                    recommendedBatteryCount,
                                batteryPrice: actualBatteryCostUnit,
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // Contact/Business profile inputs
                          _buildSectionHeader(
                            "1. Business & Client Profile Details",
                          ),
                          _buildTextField(
                            _clientNameController,
                            _t('clientName'),
                            Icons.person,
                            keyboardType: TextInputType.name,
                          ),
                          _buildTextField(
                            _installerNameController,
                            _t('installerName'),
                            Icons.engineering,
                            keyboardType: TextInputType.name,
                          ),
                          _buildTextField(
                            _shopNameController,
                            _t('shopName'),
                            Icons.storefront,
                            keyboardType: TextInputType.text,
                          ),
                          _buildTextField(
                            _phoneController,
                            _t('phone'),
                            Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          _buildTextField(
                            _licenseController,
                            _t('nepraLicense'),
                            Icons.verified_user,
                            keyboardType: TextInputType.text,
                          ),
                          _buildTextField(
                            _bankNameController,
                            _t('bankDetails'),
                            Icons.account_balance,
                            keyboardType: TextInputType.text,
                          ),
                          _buildTextField(
                            _accountNoController,
                            _t('accountNo'),
                            Icons.payment,
                            keyboardType: TextInputType.text,
                          ),

                          // Warranty dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedWarranty,
                            isExpanded: true,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              labelText: _t('warrantyDuration'),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: '10-year warranty',
                                child: Text(
                                  _activeLang == 'en'
                                      ? '10-Year Complete Performance Sizing'
                                      : 'دس سالہ وارنٹی',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: '5-year warranty',
                                child: Text(
                                  _activeLang == 'en'
                                      ? '5-Year Standard Sizing Warranty'
                                      : 'پانچ سالہ وارنٹی',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'No official warranty',
                                child: Text(
                                  _activeLang == 'en'
                                      ? 'No Warranty Policy Clause'
                                      : 'کوئی وارنٹی نہیں ہے',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedWarranty = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 15),

                          _buildSectionHeader(
                            "2. Exact Sizing Quantities & Pricing Override",
                          ),

                          // Solar plates quantity and price edit box
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _propPanelCountController,
                                  "Solar Array Plate Count",
                                  Icons.analytics,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  _propPanelPriceController,
                                  "Price per Plate (Rs.)",
                                  Icons.price_change,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                                ),
                              ),
                            ],
                          ),

                          // Inverter price edit box
                          _buildTextField(
                            _propInverterPriceController,
                            "Inverter Sizing Cost (Rs.)",
                            Icons.electric_bolt,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                          ),

                          // Battery bank count and unit cost edit box
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _propBatteryCountController,
                                  "Batteries Count",
                                  Icons.battery_charging_full,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  _propBatteryPriceController,
                                  "Price per Battery Asset",
                                  Icons.payments,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),
                          _buildSectionHeader(
                            "3. Balance-of-System (BoS) Ancillary Costs",
                          ),

                          // AC/DC Distribution Box Box Sizing edit controller
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  _propBoxCountController,
                                  "DB Box Qty",
                                  Icons.dns,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  _propBoxPriceController,
                                  "DB Unit Price (Rs.)",
                                  Icons.receipt_long,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                                ),
                              ),
                            ],
                          ),

                          // Wiring, Earthing, Mounting frames edit controllers
                          _buildTextField(
                            _propWiringPriceController,
                            "DC / AC Copper Cabling Price (Rs.)",
                            Icons.cable,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                          ),
                          _buildTextField(
                            _propEarthingPriceController,
                            "Lightning Earthing Bore Cost (Rs.)",
                            Icons.g_mobiledata,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                          ),
                          _buildTextField(
                            _propMountingPriceController,
                            "Galvanized Structure Frame Cost (Rs.)",
                            Icons.layers,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                          ),
                          _buildTextField(
                            _propMc4PriceController,
                            "Waterproof MC4 Connectors Array Cost (Rs.)",
                            Icons.alt_route,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                          ),
                          _buildTextField(
                            _propLaborPriceController,
                            "Tech Installation & Sizing Labor Fee (Rs.)",
                            Icons.handyman,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _hasCustomItemizedOverrides = true),
                          ),

                          const SizedBox(height: 10),

                          // PDF Generating button trigger
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D9E75),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf, size: 20),
                            label: Text(
                              _t('generatePdf'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              PdfInvoiceService.generateAndPrintProposal(
                                activeLang: _activeLang,
                                totalLoadWatts: activeLoadWatts,
                                dailyKWh: activeDailyKWh,
                                monthlyKWh: activeMonthlyKWh,
                                panelsCount: uiPanelCount,
                                panelPrice: uiPanelPrice,
                                inverterCost: uiInverterCost,
                                panelModelName: activePanel['name'] as String,
                                panelNominalWatts: panelNominalWatts,
                                suggestedInverterKW: suggestedInverterKW,
                                inverterType: _backupWanted
                                    ? 'Hybrid Series'
                                    : 'Day-time OnGRID',
                                recommendedBatteryCount: uiBatteryCount,
                                batteryPrice: uiBatteryPrice,
                                distributionBoxCount: uiBoxCount,
                                distributionBoxPrice: uiBoxPrice,
                                wiringCost: uiWiringCost,
                                earthingCost: uiEarthingCost,
                                mountingCost: uiMountingCost,
                                mc4Cost: uiMc4Cost,
                                laborCost: uiLaborCost,
                                totalCost: computedTotalCostPKR,
                                monthlySaved: monthlySavingsPKR,
                                paybackYears: paybackPeriodYears,
                                clientName: _clientNameController.text,
                                warranty: _selectedWarranty,
                                installerName: _installerNameController.text,
                                shopName: _shopNameController.text,
                                phone: _phoneController.text,
                                license: _licenseController.text,
                                bankName: _bankNameController.text,
                                accountNo: _accountNoController.text,
                                selectedCity: _selectedCity,
                              );
                            },
                          ),
                          const SizedBox(height: 12),

                          // WhatsApp Load-Sharing Button (Privacy Protected - No Prices)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.share, size: 20, color: Colors.white),
                            label: Text(
                              _activeLang == 'ur'
                                  ? 'واٹس ایپ پر لوڈ شیئر کریں'
                                  : (_activeLang == 'mix'
                                      ? 'WhatsApp Per Load Share Karein'
                                      : 'Share Load via WhatsApp'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              final Map<String, int> loadData = {};
                              if (_manualInputActive) {
                                loadData['Custom Continuous Load'] = 1;
                              } else {
                                if (_acCount > 0) loadData['Inverter AC (1.5 Ton)'] = _acCount;
                                if (_fanCount > 0) loadData['Ceiling Fan (Standard)'] = _fanCount;
                                if (_dcFanCount > 0) loadData['Solar DC Fan'] = _dcFanCount;
                                if (_bulbCount > 0) loadData['LED Bulb / Tube'] = _bulbCount;
                                if (_fridgeCount > 0) {
                                  loadData[_isFridgeInverter ? 'Inverter Refrigerator' : 'Standard Refrigerator'] = _fridgeCount;
                                }
                                if (_ovenCount > 0) loadData['Microwave / Oven'] = _ovenCount;
                                if (_pumpCount > 0) loadData['Water Pump'] = _pumpCount;

                                if (loadData.isEmpty && appState.appliances.isNotEmpty) {
                                  for (final app in appState.appliances) {
                                    if (app.quantity > 0) {
                                      loadData[app.name] = (loadData[app.name] ?? 0) + app.quantity;
                                    }
                                  }
                                }
                              }

                              final double totalKw = activeLoadWatts / 1000.0;
                              final success = await WhatsAppService.shareLoadToWhatsApp(
                                loadData: loadData,
                                totalKw: totalKw,
                              );

                              if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('WhatsApp is not installed on this device.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // AI Engineering Audit Button (Queries local n8n & Ollama) - commented out for now
                          /*
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            icon: _isAuditing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                    ),
                                  )
                                : const Icon(
                                    Icons.psychology_outlined,
                                    size: 20,
                                    color: Color(0xFF38BDF8),
                                  ),
                            label: Text(
                              _isAuditing
                                  ? 'AI Auditor analyzing Swabi 4.8 PSH data...'
                                  : 'Request AI Engineering Audit',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _isAuditing
                                ? null
                                : () async {
                                    setState(() {
                                      _isAuditing = true;
                                    });
                                    try {
                                      final Map<String, int> loadData = {};
                                      if (_manualInputActive) {
                                        loadData['Custom Continuous Load'] = 1;
                                      } else {
                                        if (_acCount > 0) loadData['Inverter AC (1.5 Ton)'] = _acCount;
                                        if (_fanCount > 0) loadData['Ceiling Fan (Standard)'] = _fanCount;
                                        if (_dcFanCount > 0) loadData['Solar DC Fan'] = _dcFanCount;
                                        if (_bulbCount > 0) loadData['LED Bulb / Tube'] = _bulbCount;
                                        if (_fridgeCount > 0) {
                                          loadData[_isFridgeInverter ? 'Inverter Refrigerator' : 'Standard Refrigerator'] = _fridgeCount;
                                        }
                                        if (_ovenCount > 0) loadData['Microwave / Oven'] = _ovenCount;
                                        if (_pumpCount > 0) loadData['Water Pump'] = _pumpCount;

                                        if (loadData.isEmpty && appState.appliances.isNotEmpty) {
                                          for (final app in appState.appliances) {
                                            if (app.quantity > 0) {
                                              loadData[app.name] = (loadData[app.name] ?? 0) + app.quantity;
                                            }
                                          }
                                        }
                                      }

                                      final double totalKw = activeLoadWatts / 1000.0;
                                      await N8nAuditService.requestAndShowAudit(
                                        context,
                                        loadData: loadData,
                                        totalKw: totalKw,
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
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
                                  },
                          ),
                          const SizedBox(height: 12),
                          */
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),

          // Ad Banner for financial sustainability
          const AdmobBanner(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: const Color(0xFF1D9E75).withValues(alpha: 0.06),
        width: double.infinity,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: Color(0xFF1D9E75),
          ),
        ),
      ),
    );
  }

  Future<void> _showSettingsSheet(SolarAppState appState) async {
    final nameController = TextEditingController(text: appState.userName);
    final accountController = TextEditingController(
      text: appState.installerAccountNumber.isNotEmpty
          ? appState.installerAccountNumber
          : _accountNoController.text,
    );
    bool isInstaller = appState.isInstaller;
    String selectedLanguage = _activeLang;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, color: Color(0xFF1D9E75)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isInstaller,
                      activeColor: const Color(0xFF1D9E75),
                      title: const Text(
                        'I am an installer',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onChanged: (value) =>
                          setSheetState(() => isInstaller = value ?? false),
                    ),
                    if (isInstaller) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: accountController,
                        decoration: const InputDecoration(
                          labelText: 'Installer Account / IBAN Number',
                          prefixIcon: Icon(Icons.payment),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLanguage,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        prefixIcon: Icon(Icons.language),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'mix',
                          child: Text('Roman Urdu Mix'),
                        ),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ur', child: Text('اردو')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedLanguage = value);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter your name.'),
                            ),
                          );
                          return;
                        }
                        await appState.saveUserSetup(
                          name: nameController.text,
                          isInstaller: isInstaller,
                          languageCode: selectedLanguage,
                          installerAccountNumber: accountController.text,
                        );
                        if (!mounted || !sheetContext.mounted) return;
                        setState(() {
                          _activeLang = selectedLanguage;
                          _installerNameController.text = nameController.text
                              .trim();
                          if (isInstaller) {
                            _accountNoController.text = accountController.text
                                .trim();
                          }
                        });
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    accountController.dispose();
  }

  Widget _buildPresetButton(String code, String text) {
    return InkWell(
      onTap: () => _applyPreset(code),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF4A5D4E).withValues(alpha: 0.08),
          border: Border.all(
            color: const Color(0xFF4A5D4E).withValues(alpha: 0.25),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4A5D4E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplianceItem({
    required String icon,
    required String name,
    required String subtitle,
    required int count,
    bool showInverterCheckbox = false,
    required VoidCallback onDec,
    required VoidCallback onInc,
    ValueChanged<bool?>? onCheckboxChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4A5D4E).withValues(alpha: 0.08),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showInverterCheckbox && onCheckboxChanged != null) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _isFridgeInverter,
                          activeColor: const Color(0xFF4A5D4E),
                          onChanged: onCheckboxChanged,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _activeLang == 'en'
                              ? 'Inverter model'
                              : 'انورٹر والا ہے',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.blueGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: onDec,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E1CC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$count",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onInc,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5D4E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputDetailRow({
    required String label,
    required String value,
    required String desc,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Color(0xFF4A5D4E),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(width: 2),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged ?? (_) => setState(() {}),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
            fontSize: 11,
          ),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF4A5D4E)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickToolsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _activeLang == 'ur'
                      ? '🛠️ مخصوص ٹولز اور چیکرز'
                      : '🛠️ DEDICATED TOOLS & CHECKERS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Color(0xFF4A5D4E),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _activeLang == 'ur' ? 'مزید ٹولز' : 'More Tools',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B7E5D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildToolChip(
                label: _activeLang == 'ur' ? '🔋 بیٹری سائزنگ' : '🔋 Battery Sizer',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BatterySizerScreen()),
                ),
              ),
              const SizedBox(width: 6),
              _buildToolChip(
                label: _activeLang == 'ur' ? '⚙️ انورٹر چیکر' : '⚙️ Inverter Check',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InverterCheckerScreen()),
                ),
              ),
              const SizedBox(width: 6),
              _buildToolChip(
                label: _activeLang == 'ur' ? '☀️ پینل سائزنگ' : '☀️ Panel Sizer',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PanelSizerScreen()),
                ),
              ),
              const SizedBox(width: 6),
              _buildToolChip(
                label: _activeLang == 'ur' ? '📈 واپڈا بچت (ROI)' : '📈 ROI Payback',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoiCalculatorScreen()),
                ),
              ),
              const SizedBox(width: 6),
              _buildToolChip(
                label: _activeLang == 'ur' ? '⚡ تفصیلی لوڈ' : '⚡ Detailed Load',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoadCalculatorScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolChip({required String label, required VoidCallback onTap}) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE9E1CC)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: Color(0xFF4A5D4E),
        ),
      ),
      onPressed: onTap,
    );
  }
}
