import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solarcalcpk/services/n8n_audit_service.dart';

void main() {
  group('N8nAuditService Unit Tests', () {
    test('Default endpoint resolves appropriately', () {
      final endpoint = N8nAuditService.endpoint;
      expect(endpoint.contains('webhook-test/solar-audit'), isTrue);
    });

    test('Custom endpoint override works', () {
      N8nAuditService.customEndpoint = 'http://192.168.1.100:5678/webhook-test/solar-audit';
      expect(N8nAuditService.endpoint, 'http://192.168.1.100:5678/webhook-test/solar-audit');
      // Reset
      N8nAuditService.customEndpoint = null;
    });

    test('Parses ai_audit from valid JSON map response', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Content-Type'], 'application/json');
        final body = jsonDecode(request.body);
        expect(body['totalKw'], 3.5);
        expect(body['loadData']['Ceiling Fan (Standard)'], 4);

        return http.Response(
          jsonEncode({
            'ai_audit': 'Solar Load Engineering Audit: Recommended 5kW Hybrid Inverter with 8x 585W Tier-1 Panels.',
          }),
          200,
        );
      });

      final result = await N8nAuditService.requestAudit(
        loadData: {'Ceiling Fan (Standard)': 4},
        totalKw: 3.5,
        client: mockClient,
      );

      expect(result, isNotNull);
      expect(result, contains('Recommended 5kW Hybrid Inverter'));
    });

    test('Parses ai_audit from valid JSON list response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'ai_audit': 'Array response format audit: Peak load 2.0 kW is safely within inverter margins.',
            }
          ]),
          200,
        );
      });

      final result = await N8nAuditService.requestAudit(
        loadData: {'LED Bulb': 10},
        totalKw: 2.0,
        client: mockClient,
      );

      expect(result, isNotNull);
      expect(result, contains('safely within inverter margins'));
    });

    test('Handles non-200 error response by returning null without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await N8nAuditService.requestAudit(
        loadData: {'Inverter AC': 1},
        totalKw: 1.5,
        client: mockClient,
      );

      expect(result, isNull);
    });

    test('Handles client exception/network failure by returning null gracefully', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final result = await N8nAuditService.requestAudit(
        loadData: {'Inverter AC': 1},
        totalKw: 1.5,
        client: mockClient,
      );

      expect(result, isNull);
    });
  });
}
