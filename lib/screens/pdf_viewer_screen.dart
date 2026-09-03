import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';

class NativePdfViewerScreen extends StatelessWidget {
  final String title;
  final String documentNo;
  final String cariAd;
  final double amount;
  final String type; // 'fatura' or 'irsaliye'

  const NativePdfViewerScreen({
    super.key,
    required this.title,
    required this.documentNo,
    required this.cariAd,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: AppTheme.slate900,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            Text(documentNo, style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'WhatsApp ile Paylaş',
            onPressed: () {
              Share.share('$title: $documentNo - $cariAd için oluşturulan resmi belge.');
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded, color: Colors.white),
            tooltip: 'Yazdır / PDF Kaydet',
            onPressed: () async {
              final doc = pw.Document();
              doc.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) {
                    return pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('EAD DEMIR CELIK - RESMI BELGE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 10),
                          pw.Text('Evrak No: $documentNo'),
                          pw.Text('Cari: $cariAd'),
                          pw.Text('Tutar: $amount TL'),
                        ],
                      ),
                    );
                  },
                ),
              );
              await Printing.layoutPdf(onLayout: (format) async => doc.save());
            },
          ),
        ],
      ),
      body: Container(
        color: AppTheme.slate100,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: type == 'fatura' ? const Color(0xFFEFF6FF) : const Color(0xFFFAF5FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(type == 'fatura' ? '📄' : '🚚', style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  type == 'fatura' ? 'e-Fatura & e-Arşiv Belgesi' : 'e-İrsaliye Sevk Belgesi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                ),
                const SizedBox(height: 4),
                Text(documentNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                const Divider(height: 24, color: AppTheme.slate200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Müşteri / Cari:', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
                    Text(cariAd, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GİB Karekod / Durum:', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
                    const Text('Resmi Onaylı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Share.share('$title: $documentNo - $cariAd için oluşturulan resmi belge.');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Yazdır', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          final doc = pw.Document();
                          doc.addPage(
                            pw.Page(
                              pageFormat: PdfPageFormat.a4,
                              build: (pw.Context context) {
                                return pw.Center(
                                  child: pw.Text('Resmi Belge: $documentNo - $cariAd'),
                                );
                              },
                            ),
                          );
                          await Printing.layoutPdf(onLayout: (format) async => doc.save());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
