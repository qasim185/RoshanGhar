import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfInvoiceService {
  static Future<void> generateAndPrintProposal({
    required String activeLang,
    required int totalLoadWatts,
    required double dailyKWh,
    required double monthlyKWh,
    required int panelsCount,
    required double panelPrice,
    required double inverterCost,
    required String panelModelName,
    required int panelNominalWatts,
    required double suggestedInverterKW,
    required String inverterType,
    required int recommendedBatteryCount,
    required double batteryPrice,
    required int distributionBoxCount,
    required double distributionBoxPrice,
    required double wiringCost,
    required double earthingCost,
    required double mountingCost,
    required double mc4Cost,
    required double laborCost,
    required double totalCost,
    required double monthlySaved,
    required double paybackYears,
    required String clientName,
    required String warranty,
    required String installerName,
    required String shopName,
    required String phone,
    required String license,
    required String bankName,
    required String accountNo,
    required String selectedCity,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final effectiveShopName = shopName.isNotEmpty ? shopName : 'Solar Solutions PK';
          final effectiveClientName = clientName.isNotEmpty ? clientName : 'Valued Client';
          final quotationId = 'Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
          final dateStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

          return [
            // Letterhead Title Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      effectiveShopName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    if (license.isNotEmpty)
                      pw.Text(
                        "NEPRA APV-CODE: $license",
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    pw.Text(
                      "Contact: $phone",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "SOLAR ACQUISITION PROPOSAL",
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      "Quotation ID: $quotationId",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      "Date: $dateStr",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.teal),
            pw.SizedBox(height: 10),

            // Prepared for client section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "PROPOSAL PREPARED FOR:",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      effectiveClientName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Target City: $selectedCity (Zone climate coefficient optimized)",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "OFFICIAL INSTALLED WARRANTY:",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      warranty,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                    pw.Text(
                      "Includes Output Sizing Guarantee",
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 1. Demand description
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: const pw.BoxDecoration(color: PdfColors.teal800),
              width: double.infinity,
              child: pw.Text(
                "1. HOUSEHOLD LOAD & ENERGY PROFILE DEMAND",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Sustained Continuous Sized Load",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "$totalLoadWatts Watts",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      "Daily energy consumption requirement",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "${dailyKWh.toStringAsFixed(1)} kWh / day",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Estimated monthly baseline target",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "${monthlyKWh.toStringAsFixed(0)} Units / month",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 2. Solar sizing specification
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: const pw.BoxDecoration(color: PdfColors.teal800),
              width: double.infinity,
              child: pw.Text(
                "2. SOLAR POWER COMPLIANCE SPECIFICATION",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SOLAR ARRAY SYSTEM SPECS:",
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        "$panelsCount Plates x $panelNominalWatts Watts Nominal ($panelModelName)",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "De-rated using temperature & dust coefficient factors for actual real-world output in hot summers.",
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "INVERTER PROCESSING EQUIPMENT:",
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        "${suggestedInverterKW.toStringAsFixed(1)} kW Unit ($inverterType)",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Dynamic high-density MPPT solar tracking to protect compressor inductive starts safely.",
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "LOADSHEDDING BATTERY BACKUP STATEMENT:",
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              recommendedBatteryCount > 0
                  ? "$recommendedBatteryCount Units Tall Tubular deep-cycle acid batteries arranged in safe Series string."
                  : "None (No Battery daytime backup direct solar flow only)",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),

            // 3. Billing detailed invoice
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: const pw.BoxDecoration(color: PdfColors.teal800),
              width: double.infinity,
              child: pw.Text(
                "3. ITEMIZED BILL-OF-MATERIALS CONTRACTOR INVOICE",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            _pdfPriceItem(
              "A. Solar Panels: $panelsCount plates x Rs. ${panelPrice.toStringAsFixed(0)} ($panelModelName)",
              "Rs. ${(panelsCount * panelPrice).toStringAsFixed(0)}",
            ),
            _pdfPriceItem(
              "B. Smart Inverter unit: ${suggestedInverterKW.toStringAsFixed(1)} kW ($inverterType)",
              "Rs. ${suggestedInverterKW > 0 ? suggestedInverterKW.toStringAsFixed(0) : '0'}",
              customValue: inverterCost,
            ),
            _pdfPriceItem(
              "C. Distribution AC/DC DB Safety breaker box ($distributionBoxCount unit)",
              "Rs. ${(distributionBoxCount * distributionBoxPrice).toStringAsFixed(0)}",
            ),
            if (recommendedBatteryCount > 0)
              _pdfPriceItem(
                "D. Deep-Cycle batteries storagebank: $recommendedBatteryCount units",
                "Rs. ${(recommendedBatteryCount * batteryPrice).toStringAsFixed(0)}",
              ),
            _pdfPriceItem(
              "E. Pure Copper AC/DC Cables & structural layouts wire",
              "Rs. ${wiringCost.toStringAsFixed(0)}",
            ),
            _pdfPriceItem(
              "F. Lightning protection & safety chemical Earthing bore",
              "Rs. ${earthingCost.toStringAsFixed(0)}",
            ),
            _pdfPriceItem(
              "G. Galvanized anti-corrosive Mounting brackets profile structure",
              "Rs. ${mountingCost.toStringAsFixed(0)}",
            ),
            _pdfPriceItem(
              "H. Safety MC4 connectors string locks & conduits packaging",
              "Rs. ${mc4Cost.toStringAsFixed(0)}",
            ),
            _pdfPriceItem(
              "I. Professional Technician layout design, installation & labor charges",
              "Rs. ${laborCost.toStringAsFixed(0)}",
            ),

            pw.Divider(thickness: 1, color: PdfColors.grey500),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "ESTIMATED TOTAL SYSTEM PROCUREMENT INVESTMENT:",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                pw.Text(
                  "Rs. ${totalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.teal,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 4. Financial projections
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              decoration: const pw.BoxDecoration(color: PdfColors.teal800),
              width: double.infinity,
              child: pw.Text(
                "4. FINANCIAL RETURN ON INVESTMENT OUTLOOK (25-YEARS)",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Estimated WAPDA bill saved per Month",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "Rs. ${monthlySaved.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      "Breakeven return payback period",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "${paybackYears.toStringAsFixed(1)} Years",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Net Life financial gain from solar array",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      "Rs. ${(monthlySaved * 12.0 * 25.0 - totalCost).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Bank Accounts reception instructions
            if (bankName.isNotEmpty && accountNo.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "BANK PAYMENT PROCESSING INFORMATION:",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 7,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Bank Name: $bankName",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "Account Number: $accountNo",
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Stamp boxes
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 100,
                      height: 0.5,
                      color: PdfColors.grey500,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Customer Acceptance Signature",
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      installerName.isNotEmpty ? installerName : 'Certified Solar Installer',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      width: 100,
                      height: 0.5,
                      color: PdfColors.grey500,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Authorized Designer Seal & Sign",
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final sanitizedName = clientName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'RoshanGhar_Proposal_${sanitizedName.isEmpty ? "Client" : sanitizedName}.pdf',
      );
    } catch (e) {
      debugPrint("PDF generation layout aborted: $e");
    }
  }

  static pw.Widget _pdfPriceItem(
    String name,
    String fallbackPrice, {
    double? customValue,
  }) {
    String outputStr = fallbackPrice;
    if (customValue != null) {
      outputStr = "Rs. ${customValue.toStringAsFixed(0)}";
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(name, style: const pw.TextStyle(fontSize: 7)),
          pw.Text(
            outputStr,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
