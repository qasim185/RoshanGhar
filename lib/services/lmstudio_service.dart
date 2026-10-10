import 'nlp_load_parser.dart';

/// Legacy compatibility wrapper around [NlpLoadParser]
enum ExtractionSource {
  lmStudio,
  offlineRuleEngine,
}

class ApplianceExtractionResult {
  final int fan;
  final int dcFan;
  final int fridge;
  final int ac;
  final int oven;
  final int bulb;
  final int pump;
  final ExtractionSource source;
  final String? rawResponse;
  final String? note;

  const ApplianceExtractionResult({
    this.fan = 0,
    this.dcFan = 0,
    this.fridge = 0,
    this.ac = 0,
    this.oven = 0,
    this.bulb = 0,
    this.pump = 0,
    this.source = ExtractionSource.offlineRuleEngine,
    this.rawResponse,
    this.note,
  });

  int get totalCount => fan + dcFan + fridge + ac + oven + bulb + pump;

  dynamic operator [](String key) {
    switch (key) {
      case 'fan':
        return fan;
      case 'dc_fan':
      case 'dcFan':
        return dcFan;
      case 'fridge':
        return fridge;
      case 'ac':
        return ac;
      case 'oven':
        return oven;
      case 'bulb':
        return bulb;
      case 'pump':
        return pump;
      default:
        return null;
    }
  }

  factory ApplianceExtractionResult.fromMap(Map<String, int> map) {
    return ApplianceExtractionResult(
      fan: map['fan'] ?? 0,
      dcFan: map['dc_fan'] ?? 0,
      fridge: map['fridge'] ?? 0,
      ac: map['ac'] ?? 0,
      oven: map['oven'] ?? 0,
      bulb: map['bulb'] ?? 0,
      pump: map['pump'] ?? 0,
      source: ExtractionSource.offlineRuleEngine,
    );
  }
}

class LMStudioService {
  static Future<ApplianceExtractionResult> extractAppliances(
    String input, {
    String? endpoint,
    dynamic client,
  }) async {
    final parsed = NlpLoadParser.parse(input);
    return ApplianceExtractionResult.fromMap(parsed);
  }

  static ApplianceExtractionResult parseWithOfflineRuleEngine(String text) {
    final parsed = NlpLoadParser.parse(text);
    return ApplianceExtractionResult.fromMap(parsed);
  }
}
