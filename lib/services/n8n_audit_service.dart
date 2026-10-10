import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Service connecting RoshanGhar with a local n8n instance and Ollama (qwen3.5:4b)
/// for solar engineering load audits.
class N8nAuditService {
  /// Default endpoint for Android emulator.
  static const String defaultAndroidEmulatorUrl =
      'http://10.0.2.2:5678/webhook-test/solar-audit';

  /// Default endpoint for local machine (Windows / Desktop).
  static const String defaultLocalhostUrl =
      'http://127.0.0.1:5678/webhook-test/solar-audit';

  /// User-configurable custom endpoint URL.
  static String? customEndpoint;

  /// Resolves the current target endpoint URL based on configuration and platform.
  static String get endpoint {
    if (customEndpoint != null && customEndpoint!.trim().isNotEmpty) {
      return customEndpoint!.trim();
    }
    // Windows/Desktop connects directly to localhost:5678
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      return defaultLocalhostUrl;
    }
    // Android emulator forwards 10.0.2.2 to host's 127.0.0.1
    return defaultAndroidEmulatorUrl;
  }

  /// Sends appliance load breakdown and total peak kW to the local n8n AI Auditor webhook.
  ///
  /// Enforces a strict 15-second timeout.
  /// Returns the `ai_audit` text if successful, or `null` if unreachable, timed out, or invalid.
  static Future<String?> requestAudit({
    required Map<String, int> loadData,
    required double totalKw,
    String? overrideEndpoint,
    http.Client? client,
  }) async {
    final targetUrl = overrideEndpoint ?? endpoint;
    final Uri uri = Uri.parse(targetUrl);

    final Map<String, dynamic> payload = {
      'loadData': loadData,
      'totalKw': totalKw,
      'app': 'RoshanGhar Solar Calculator',
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final postFuture = client != null
          ? client.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
          : http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            );

      final response = await postFuture.timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final bodyText = response.body.trim();
        if (bodyText.isEmpty) {
          return null;
        }

        try {
          final dynamic decoded = jsonDecode(bodyText);
          if (decoded is Map<String, dynamic>) {
            if (decoded.containsKey('ai_audit') && decoded['ai_audit'] != null) {
              return decoded['ai_audit'].toString();
            }
            if (decoded.containsKey('audit') && decoded['audit'] != null) {
              return decoded['audit'].toString();
            }
            if (decoded.containsKey('response') && decoded['response'] != null) {
              return decoded['response'].toString();
            }
            if (decoded.containsKey('output') && decoded['output'] != null) {
              return decoded['output'].toString();
            }
            if (decoded.containsKey('message') && decoded['message'] != null) {
              return decoded['message'].toString();
            }
            if (decoded.containsKey('text') && decoded['text'] != null) {
              return decoded['text'].toString();
            }
          } else if (decoded is List && decoded.isNotEmpty) {
            final first = decoded.first;
            if (first is Map<String, dynamic>) {
              if (first.containsKey('ai_audit') && first['ai_audit'] != null) {
                return first['ai_audit'].toString();
              }
              if (first.containsKey('audit') && first['audit'] != null) {
                return first['audit'].toString();
              }
              if (first.containsKey('response') && first['response'] != null) {
                return first['response'].toString();
              }
            }
          }
        } catch (_) {
          // If response is raw markdown or text rather than JSON
          return bodyText;
        }

        return bodyText;
      } else {
        debugPrint(
          'N8nAuditService: Request failed with status ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('N8nAuditService: Request timed out after 15 seconds: $e');
      return null;
    } on SocketException catch (e) {
      debugPrint('N8nAuditService: SocketException (n8n unreachable): $e');
      return null;
    } on http.ClientException catch (e) {
      debugPrint('N8nAuditService: ClientException (n8n unreachable): $e');
      return null;
    } catch (e) {
      debugPrint('N8nAuditService: General error: $e');
      return null;
    }
  }

  /// Helper to trigger the full audit flow: displays loading modal,
  /// queries n8n webhook, dismisses loading, and shows the clean bottom sheet review
  /// or error SnackBar.
  static Future<void> requestAndShowAudit(
    BuildContext context, {
    required Map<String, int> loadData,
    required double totalKw,
  }) async {
    // 1. Display loading modal sheet / dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Requesting AI Engineering Audit...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Querying local n8n & Ollama (qwen3.5:4b)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 2. Perform the audit request
    final String? auditReview = await requestAudit(
      loadData: loadData,
      totalKw: totalKw,
    );

    // 3. Ensure context is still active
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

    // 4. Show audit review or SnackBar
    if (auditReview != null && auditReview.trim().isNotEmpty) {
      showAuditModalSheet(
        context,
        auditReview: auditReview,
        totalKw: totalKw,
        loadData: loadData,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local AI Auditor unreachable. Ensure n8n is running.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Displays the completed AI Audit inside a clean modal bottom sheet.
  static void showAuditModalSheet(
    BuildContext context, {
    required String auditReview,
    required double totalKw,
    required Map<String, int> loadData,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final totalApplianceCount =
            loadData.values.fold(0, (sum, count) => sum + count);

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: Color(0xFF38BDF8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Engineering Audit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ollama • qwen3.5:4b via n8n',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey[700],
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Load Info Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            '${totalKw.toStringAsFixed(2)} kW Total Load',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.devices, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          Text(
                            totalApplianceCount > 0
                                ? '$totalApplianceCount Appliances'
                                : 'Custom Profile',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Review Content Body
              Flexible(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      auditReview,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF334155)),
                      label: const Text(
                        'Copy Audit',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: auditReview));
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text('Audit review copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
