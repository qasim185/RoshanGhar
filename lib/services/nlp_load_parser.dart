/// Zero-latency edge NLP load parser for English, Roman Urdu, Pashto, and Urdu script.
/// Completely offline, deterministic, and instant.
class NlpLoadParser {
  /// Arabic/Urdu digits to ASCII
  static String normalizeDigits(String text) {
    return text
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');
  }

  /// Phonetic and word numbers in English, Roman Urdu, Pashto, and Urdu/Arabic script
  static const Map<String, int> wordNumbers = {
    // English
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'a': 1,
    'an': 1,

    // Roman Urdu
    'ek': 1,
    'aik': 1,
    'yak': 1,
    'do': 2,
    'dow': 2,
    'teen': 3,
    'tin': 3,
    'char': 4,
    'chaar': 4,
    'paanch': 5,
    'panch': 5,
    'che': 6,
    'chhe': 6,
    'chay': 6,
    'saat': 7,
    'sat': 7,
    'aath': 8,
    'ath': 8,
    'nau': 9,
    'no': 9,
    'das': 10,

    // Pashto
    'yaw': 1,
    'yao': 1,
    'yo': 1,
    'yeo': 1,
    'dwa': 2,
    'dway': 2,
    'dre': 3,
    'dray': 3,
    'salor': 4,
    'tsalor': 4,
    'chalor': 4,
    'pinz': 5,
    'pinza': 5,
    'penza': 5,
    'shpag': 6,
    'shpak': 6,
    'shpa': 6,
    'owa': 7,
    'oowah': 7,
    'ata': 8,
    'atah': 8,
    'naha': 9,
    'nah': 9,
    'las': 10,

    // Urdu & Pashto Script
    'ایک': 1,
    'یو': 1,
    'دو': 2,
    'دوا': 2,
    'تین': 3,
    'درے': 3,
    'چار': 4,
    'څلور': 4,
    'پانچ': 5,
    'پنځه': 5,
    'چھ': 6,
    'شپږ': 6,
    'سات': 7,
    'اووه': 7,
    'آٹھ': 8,
    'اتہ': 8,
    'نو': 9,
    'نه': 9,
    'دس': 10,
    'لس': 10,
  };

  /// Parses natural language input and extracts appliance counts
  static Map<String, int> parse(String userInput) {
    final Map<String, int> counts = {
      'fan': 0,
      'dc_fan': 0,
      'fridge': 0,
      'ac': 0,
      'oven': 0,
      'bulb': 0,
      'pump': 0,
    };

    final trimmed = userInput.trim();
    if (trimmed.isEmpty) return counts;

    String workingText = normalizeDigits(trimmed).toLowerCase();

    final numberTokensRegex = wordNumbers.keys.map(RegExp.escape).join('|');

    // Ordered regex patterns: more specific patterns come before generic ones
    // Fans: 'fan', 'pankha', 'pankhay', 'paki'
    // DC Fans: 'dc fan', 'solar fan'
    // Fridge: 'fridge', 'frij', 'refrigerator', 'yakhchal'
    // AC: 'ac', 'air conditioner', 'inverter ac'
    // Oven: 'oven', 'microwave', 'tanor'
    // Bulbs: 'bulb', 'light', 'led', 'grop'
    // Motor: 'motor', 'pump', 'water pump'
    final applianceSpecs = <String, String>{
      'dc_fan':
          r'(?:dc\s+fans?|dc\s+pankh[a-z]*|dc\s+pak[a-z]*|solar\s+fans?|solar\s+pankh[a-z]*|solar\s+pak[a-z]*|12\s*v(?:olt)?\s+fans?|bldc\s+fans?|brushless\s+fans?|ڈی\s*سی\s*پنکھ[ہ|ا|ے]?|ڈی\s*سی\s*فین)',
      'oven':
          r'(?:microwave(?:\s+oven)?|micro\s+wave|baking\s+oven|oven[s]?|owen[s]?|owan[s]?|awan[s]?|tanor[s]?|tandoor[s]?|مائیکرو\s*ویو(?:\s*اوون)?|اوون|داش|تندور)',
      'pump':
          r'(?:water\s+pump[s]?|water\s+motor[s]?|pani\s+ki\s+motor|pani\s+wala\s+pump|paani\s+ki\s+motor|submersible(?:\s+pump)?|tube\s*well|motor[s]?|motar[s]?|pump[s]?|د\s*اوبو\s*موټر|پانی\s*کا\s*پمپ|موٹر|پمپ)',
      'fridge':
          r'(?:refrigerator[s]?|deep\s*freezer[s]?|freezer[s]?|fridge[s]?|frij[s]?|yakhchal[s]?|yakchal[s]?|یخچال|فریج|ریفریجریٹر)',
      'ac':
          r'(?:inverter\s+ac|air\s*conditioner[s]?|split\s+ac|split|a/c|\bac\b|eesee|aisi|ایئر\s*کنڈیشنر|اے\s*سی|اې\s*سی)',
      'bulb':
          r'(?:tube\s*lights?|tubelights?|led\s*bulbs?|led\s*lights?|\bled\b|bulbs?|balabs?|balbs?|blubs?|lights?|lamps?|batti(?:an|ya|s)?|batee|groopan?|groop|grop[s]?|ایل\s*ای\s*ڈی|بلب|بتیاں|بتی|گروپ|چراغ)',
      'fan':
          r'(?:ceiling\s+fans?|fans?|pankh[a-z]*|pak[eiy]+|pakha|pakhe|پنکھ[ہ|ا|ے]?|پکی|پکه)',
    };

    for (final entry in applianceSpecs.entries) {
      final key = entry.key;
      final pattern = entry.value;

      final regex = RegExp(pattern, unicode: true, caseSensitive: false);
      final matches = regex.allMatches(workingText).toList();

      for (final match in matches) {
        final matchStart = match.start;
        final matchEnd = match.end;

        // 1. Look for number preceding the appliance
        // e.g. "3 pankhe", "dwa paki", "2x fans", "teen dana pankhe"
        final precedingChunk = workingText.substring(
          matchStart >= 40 ? matchStart - 40 : 0,
          matchStart,
        );

        final precedingRegex = RegExp(
          r'(\d+|' +
              numberTokensRegex +
              r')\s*(?:x|adad|dana|danai|pcs|pieces?|ta|عدد|دانے|دانې)?\s*$',
          caseSensitive: false,
          unicode: true,
        );

        final prevMatch = precedingRegex.firstMatch(precedingChunk.trimRight());
        int extractedCount = 0;

        if (prevMatch != null) {
          final token = prevMatch.group(1)!.trim();
          extractedCount = int.tryParse(token) ?? (wordNumbers[token] ?? 1);
        } else {
          // 2. Look for number following the appliance
          // e.g. "fans 3", "ac: 2", "motor aik"
          final followingChunk = workingText.substring(
            matchEnd,
            matchEnd + 30 <= workingText.length
                ? matchEnd + 30
                : workingText.length,
          );

          final followingRegex = RegExp(
            r'^\s*(?::|=|-)?\s*(\d+|' + numberTokensRegex + r')\b',
            caseSensitive: false,
            unicode: true,
          );

          final nextMatch = followingRegex.firstMatch(followingChunk);
          if (nextMatch != null) {
            final token = nextMatch.group(1)!.trim();
            extractedCount = int.tryParse(token) ?? (wordNumbers[token] ?? 1);
          } else {
            // 3. Check for negation like "no ac", "without fan", "ac nahi"
            final checkNegation = RegExp(
              r'(?:no|zero|0|baghair|nahi|nahin|bina|nishta)\s*$',
              caseSensitive: false,
            );
            if (checkNegation.hasMatch(precedingChunk.trimRight())) {
              extractedCount = 0;
            } else {
              // Mentioned without explicit number -> default to 1
              extractedCount = 1;
            }
          }
        }

        counts[key] = (counts[key] ?? 0) + extractedCount;

        // Mask matched span in workingText so overlapping keywords don't re-match
        workingText = workingText.replaceRange(
          matchStart,
          matchEnd,
          ' ' * (matchEnd - matchStart),
        );
      }
    }

    return counts;
  }
}
