import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/appliance.dart';

class SolarAppState with ChangeNotifier {
  List<Appliance> _appliances = [];
  bool _isPremium = false;
  String _languageCode =
      'mix'; // 'mix' for Roman Urdu, 'en' for English, 'ur' for Urdu
  bool _setupComplete = false;
  String _userName = '';
  bool _isInstaller = false;
  String _installerAccountNumber = '';

  // App initialization state
  bool _isLoaded = false;

  List<Appliance> get appliances => _appliances;
  bool get isPremium => _isPremium;
  String get languageCode => _languageCode;
  bool get setupComplete => _setupComplete;
  String get userName => _userName;
  bool get isInstaller => _isInstaller;
  String get installerAccountNumber => _installerAccountNumber;
  bool get isLoaded => _isLoaded;

  // Constructor
  SolarAppState() {
    loadData();
  }

  // Get total continuous power draw (Watts)
  int get totalLoadWatts {
    int sum = 0;
    for (var app in _appliances) {
      sum += app.totalWatts;
    }
    return sum;
  }

  // Get total daytime power draw (Watts)
  int get daytimeWatts {
    int sum = 0;
    for (var app in _appliances) {
      if (app.isDaytime) {
        sum += app.totalWatts;
      }
    }
    return sum;
  }

  // Get total night power draw (Watts)
  int get nightWatts {
    int sum = 0;
    for (var app in _appliances) {
      if (!app.isDaytime) {
        sum += app.totalWatts;
      }
    }
    return sum;
  }

  // Total daily energy draw in kilowatt-hours (kWh)
  double get totalDailyKWh {
    double sum = 0.0;
    for (var app in _appliances) {
      sum += app.dailyKWh;
    }
    return sum;
  }

  // Load state from SharedPreferences (local persistence)
  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('is_premium') ?? false;
      _languageCode = prefs.getString('language_code') ?? 'mix';
      _setupComplete = prefs.getBool('setup_complete') ?? false;
      _userName = prefs.getString('user_name') ?? '';
      _isInstaller = prefs.getBool('is_installer') ?? false;
      _installerAccountNumber =
          prefs.getString('installer_account_number') ?? '';

      final String? appliancesJson = prefs.getString('user_appliances');
      if (appliancesJson != null) {
        final List<dynamic> decoded = jsonDecode(appliancesJson);
        _appliances = decoded.map((item) => Appliance.fromJson(item)).toList();
      } else {
        // Load default empty or sample lists
        _appliances = [
          Appliance(
            id: '1',
            name: 'LED Bulb',
            watts: 12,
            hoursPerDay: 8,
            quantity: 5,
            isDaytime: false,
          ),
          Appliance(
            id: '2',
            name: 'Ceiling Fan',
            watts: 75,
            hoursPerDay: 12,
            quantity: 3,
            isDaytime: true,
          ),
          Appliance(
            id: '3',
            name: 'Refrigerator',
            watts: 150,
            hoursPerDay: 24,
            quantity: 1,
            isDaytime: true,
          ),
        ];
      }
    } catch (e) {
      debugPrint("Error loading local storage data: $e");
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Save appliances list locally
  Future<void> saveAppliances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _appliances.map((app) => app.toJson()).toList(),
      );
      await prefs.setString('user_appliances', encoded);
    } catch (e) {
      debugPrint("Error saving appliances: $e");
    }
  }

  // Set premium status (called on successful virtual or real payment)
  Future<void> buyPremium() async {
    _isPremium = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
  }

  // Test toggle premium status
  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', _isPremium);
  }

  // Change language translation option
  Future<void> setLanguage(String code) async {
    if (code == 'en' || code == 'ur' || code == 'mix') {
      _languageCode = code;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', code);
    }
  }

  Future<void> saveUserSetup({
    required String name,
    required bool isInstaller,
    required String languageCode,
    String installerAccountNumber = '',
    bool completeSetup = true,
  }) async {
    _userName = name.trim();
    _isInstaller = isInstaller;
    _languageCode = languageCode;
    _installerAccountNumber = isInstaller ? installerAccountNumber.trim() : '';
    _setupComplete = completeSetup;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setBool('is_installer', _isInstaller);
    await prefs.setString('language_code', _languageCode);
    await prefs.setString('installer_account_number', _installerAccountNumber);
    await prefs.setBool('setup_complete', _setupComplete);
  }

  // Translation mapping dictionary helper
  String translate(String key) {
    if (_languageCode == 'ur') {
      return _urduTranslations[key] ?? key;
    }
    return _englishTranslations[key] ?? key;
  }

  // Add a new appliance
  void addAppliance(Appliance appliance) {
    _appliances.add(appliance);
    notifyListeners();
    saveAppliances();
  }

  // Update an appliance properties
  void updateAppliance(Appliance updated) {
    final index = _appliances.indexWhere((app) => app.id == updated.id);
    if (index != -1) {
      _appliances[index] = updated;
      notifyListeners();
      saveAppliances();
    }
  }

  // Delete appliance reference
  void removeAppliance(String id) {
    _appliances.removeWhere((app) => app.id == id);
    notifyListeners();
    saveAppliances();
  }

  // Clear appliance list
  void clearAppliances() {
    _appliances.clear();
    notifyListeners();
    saveAppliances();
  }

  // Dictionaries for localized phrases
  static const Map<String, String> _englishTranslations = {
    'appName': 'RoshanGhar',
    'tagline': 'Size your solar system in minutes',
    'loadCalc': 'Load Calculator',
    'batterySizer': 'Battery Sizer',
    'panelSizer': 'Panel Sizer',
    'roiCalc': 'ROI Payback',
    'inverterCheck': 'Inverter Check',
    'advancedTools': 'Advanced Tools',
    'premiumFeatures': 'Go Premium (Ad-Free & PDF)',
    'removeAds': 'Remove Ads - Rs. 99',
    'totalWatts': 'Total Watts',
    'dailyUnits': 'Daily Units',
    'daytimeLoad': 'Daytime Load',
    'nighttimeLoad': 'Night Load',
    'addAppliance': 'Add Appliance',
    'addPreset': 'Add Presets',
    'emptyLoadText':
        'No appliances added yet. Add some to estimate your solar sizing load!',
    'calculate': 'Calculate',
    'save': 'Save',
    'back': 'Back',
  };

  static const Map<String, String> _urduTranslations = {
    'appName': 'روشن گھر',
    'tagline': 'اپنے سولر سسٹم کا سائز منٹوں میں معلوم کریں',
    'loadCalc': 'لوڈ کیلکولیٹر',
    'batterySizer': 'بیٹری سائزنگ',
    'panelSizer': 'سولر پینل سائزنگ',
    'roiCalc': 'بچت اور واپسی',
    'inverterCheck': 'انورٹر چیکر',
    'advancedTools': 'اضافی فیچرز',
    'premiumFeatures': 'پریمیم ورژن خریدیں (بغیر اشتہارات)',
    'removeAds': 'کمرشل اشتہار ہٹائیں - 99 روپے',
    'totalWatts': 'کل واٹس',
    'dailyUnits': 'روزانہ کے یونٹ',
    'daytimeLoad': 'دن کا لوڈ',
    'nighttimeLoad': 'رات کا لوڈ',
    'addAppliance': 'نیا آلہ شامل کریں',
    'addPreset': 'پری سیٹ شامل کریں',
    'emptyLoadText':
        'ابھی تک کوئی آلہ شامل نہیں کیا گیا۔ سولر لوڈ معلوم کرنے کے لیے آلات شامل کریں!',
    'calculate': 'حساب لگائیں',
    'save': 'محفوظ کریں',
    'back': 'واپس جائیں',
  };
}
