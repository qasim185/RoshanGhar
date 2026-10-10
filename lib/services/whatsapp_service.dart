import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Formats the load details into a clean Roman Urdu & English message.
  /// IMPORTANT: Strictly excludes any system pricing, financial quotes, or vendor markups.
  static String formatLoadMessage({
    required Map<String, int> loadData,
    required double totalKw,
  }) {
    final buffer = StringBuffer();
    buffer.writeln("Assalam-o-Alaikum! I calculated my household load using RoshanGhar.");
    buffer.writeln();
    buffer.writeln("📋 *Selected Appliances:*");

    bool hasAppliance = false;
    loadData.forEach((name, quantity) {
      if (quantity > 0) {
        hasAppliance = true;
        buffer.writeln("• ${quantity}x $name");
      }
    });

    if (!hasAppliance) {
      buffer.writeln("• Custom continuous load profile");
    }

    buffer.writeln();
    buffer.writeln("⚡ *Estimated Total Load:* ${totalKw.toStringAsFixed(2)} kW");
    buffer.writeln();
    buffer.writeln(
      "Please review my load profile and provide a recommended solar system audit and quotation. JazakAllah!",
    );

    return buffer.toString();
  }

  /// Launches WhatsApp with the formatted load message without exposing prices.
  /// First tries native `whatsapp://send?text=...`, falling back to `https://wa.me/?text=...`.
  /// Returns `true` if launched successfully, `false` otherwise.
  static Future<bool> shareLoadToWhatsApp({
    required Map<String, int> loadData,
    required double totalKw,
  }) async {
    final String message = formatLoadMessage(loadData: loadData, totalKw: totalKw);
    final String encodedText = Uri.encodeComponent(message);

    final Uri nativeUri = Uri.parse("whatsapp://send?text=$encodedText");
    final Uri webUri = Uri.parse("https://wa.me/?text=$encodedText");

    // 1. Attempt native WhatsApp scheme first
    try {
      if (await canLaunchUrl(nativeUri)) {
        final launched = await launchUrl(
          nativeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (e) {
      debugPrint("Native WhatsApp launch error: $e");
    }

    // 2. Fallback to https://wa.me/
    try {
      if (await canLaunchUrl(webUri)) {
        final launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (e) {
      debugPrint("wa.me launch error: $e");
    }

    return false;
  }
}

/// Top-level helper function matching the exact specification:
/// `shareLoadToWhatsApp({required Map<String, int> loadData, required double totalKw})`
Future<bool> shareLoadToWhatsApp({
  required Map<String, int> loadData,
  required double totalKw,
}) =>
    WhatsAppService.shareLoadToWhatsApp(
      loadData: loadData,
      totalKw: totalKw,
    );
