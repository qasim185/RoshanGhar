import 'package:flutter_test/flutter_test.dart';
import 'package:solarcalcpk/services/nlp_load_parser.dart';
import 'package:solarcalcpk/services/lmstudio_service.dart';

void main() {
  group('NlpLoadParser - Robust Edge NLP Engine', () {
    test('Extracts appliances from Roman Urdu', () {
      final text = '3 pankhay, 1 frij, 1 motor, 2 ac, 8 bulb aur 1 oven';
      final result = NlpLoadParser.parse(text);

      expect(result['fan'], 3);
      expect(result['fridge'], 1);
      expect(result['pump'], 1);
      expect(result['ac'], 2);
      expect(result['bulb'], 8);
      expect(result['oven'], 1);
      expect(result['dc_fan'], 0);
    });

    test('Differentiates between DC fans and AC fans', () {
      final text = '2 dc fans aur 4 ceiling fans';
      final result = NlpLoadParser.parse(text);

      expect(result['dc_fan'], 2);
      expect(result['fan'], 4);
    });

    test('Extracts appliances from Pashto language', () {
      // Pashto words: paki (fans), yakhchal (fridge), motor (pump)
      final text = '3 paki, 1 yakhchal, 1 ac ao 1 motor';
      final result = NlpLoadParser.parse(text);

      expect(result['fan'], 3);
      expect(result['fridge'], 1);
      expect(result['ac'], 1);
      expect(result['pump'], 1);
    });

    test('Extracts Pashto number words (dwa, yaw, dre, shpa)', () {
      final text = 'dwa paki ao yaw yakhchal ao yaw motor ao shpa bulb';
      final result = NlpLoadParser.parse(text);

      expect(result['fan'], 2);
      expect(result['fridge'], 1);
      expect(result['pump'], 1);
      expect(result['bulb'], 6);
    });

    test('Extracts Roman Urdu number words (ek, do, teen, chaar)', () {
      final text = 'chaar pankhay, do ac, ek frij, ek motor';
      final result = NlpLoadParser.parse(text);

      expect(result['fan'], 4);
      expect(result['ac'], 2);
      expect(result['fridge'], 1);
      expect(result['pump'], 1);
    });

    test('Extracts English sentence with words (one, two) and digits', () {
      final text =
          'I need solar power for five fans, 2 air conditioners, one refrigerator, 1 microwave oven, 10 led bulbs, and 1 water pump';
      final result = NlpLoadParser.parse(text);

      expect(result['fan'], 5);
      expect(result['ac'], 2);
      expect(result['fridge'], 1);
      expect(result['oven'], 1);
      expect(result['bulb'], 10);
      expect(result['pump'], 1);
    });

    test('Handles numbers following appliance names', () {
      final text = 'ac 2, fridge 1, fans 4, pump 1';
      final result = NlpLoadParser.parse(text);

      expect(result['ac'], 2);
      expect(result['fridge'], 1);
      expect(result['fan'], 4);
      expect(result['pump'], 1);
    });

    test('Extracts tanor, grop, light, solar fan, and inverter ac', () {
      final text = '1 solar fan, 1 inverter ac, 1 tanor, 6 grop, 2 tube lights';
      final result = NlpLoadParser.parse(text);

      expect(result['dc_fan'], 1);
      expect(result['ac'], 1);
      expect(result['oven'], 1);
      expect(result['bulb'], 8); // 6 + 2
    });

    test('Never throws uncaught error on empty or bizarre input', () {
      final result = NlpLoadParser.parse('!@#%^&*()');
      expect(result.values.reduce((a, b) => a + b), 0);

      final emptyResult = NlpLoadParser.parse('');
      expect(emptyResult.values.reduce((a, b) => a + b), 0);
    });
  });

  group('LMStudioService compatibility wrapper', () {
    test('Returns ApplianceExtractionResult from parseWithOfflineRuleEngine', () {
      final result = LMStudioService.parseWithOfflineRuleEngine('2 ac, 3 pankhay');
      expect(result.ac, 2);
      expect(result.fan, 3);
      expect(result.source, ExtractionSource.offlineRuleEngine);
    });

    test('Returns ApplianceExtractionResult from extractAppliances', () async {
      final result = await LMStudioService.extractAppliances('1 fridge, 1 pump');
      expect(result.fridge, 1);
      expect(result.pump, 1);
    });
  });
}
