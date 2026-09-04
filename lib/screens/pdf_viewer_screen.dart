import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme.dart';

class PdfViewerScreen extends StatelessWidget {
  final String documentId;
  final String documentNo;
  final String title;
  final String type; // 'fatura' or 'irsaliye'

  const PdfViewerScreen({
    super.key,
    required this.documentId,
    required this.documentNo,
    required this.title,
    required this.type,
  });

  Future<Uint8List> _generateOfficialDesktopPdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final isFatura = type == 'fatura';
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. ŞİRKET BAŞLIĞI & GİB ROZETİ (MASAÜSTÜ İLE AYNI)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'EAD DEMİR ÇELİK SANAYİ VE TİCARET LİMİTED ŞİRKETİ',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text('75. Yıl OSB Mah. 20. Cad. No: 14 Odunpazarı / ESKİŞEHİR', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                          pw.Text('Tel: (0222) 236 00 00 | Web: www.eaddemir.com.tr', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                          pw.Text('Vergi Dairesi: Yunusemre VD. | VKN: 3231140000', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                          pw.Text('Mersis No: 0323114000000001 | Ticaret Sicil No: 45210', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 1),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              isFatura ? 'e-FATURA' : 'e-İRSALİYE',
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text('GELİR İDARESİ BAŞKANLIĞI', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                            pw.Text(isFatura ? 'e-Fatura Sistemi' : 'e-İrsaliye Sistemi', style: const pw.TextStyle(fontSize: 6.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),

                // 2. ALICI BİLGİLERİ & EVRAK DETAYI
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 6,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('SAYIN / MÜŞTERİ BİLGİLERİ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 2),
                            pw.Text('Vergi Dairesi / VKN: İlgili Zirve Cari Kartı', style: const pw.TextStyle(fontSize: 7.5)),
                            pw.Text('Adres: Türkiye', style: const pw.TextStyle(fontSize: 7.5)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text('Belge No:', style: const pw.TextStyle(fontSize: 7.5)),
                              pw.Text(documentNo, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                            ]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text('Tarih:', style: const pw.TextStyle(fontSize: 7.5)),
                              pw.Text(dateStr, style: const pw.TextStyle(fontSize: 7.5)),
                            ]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text('Saat / Zaman:', style: const pw.TextStyle(fontSize: 7.5)),
                              pw.Text('12:00:00', style: const pw.TextStyle(fontSize: 7.5)),
                            ]),
                            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                              pw.Text('Senaryo:', style: const pw.TextStyle(fontSize: 7.5)),
                              pw.Text('TİCARİFATURA', style: const pw.TextStyle(fontSize: 7.5)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // 3. KALEMLER TABLOSU
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Sıra', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Mal / Hizmet Cinsi & Açıklaması', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Miktar', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Birim', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Birim Fiyat', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('KDV %', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tutar', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('1', style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(isFatura ? 'NERVÜRLÜ İNŞAAT DEMİRİ (Zirve Sevkiyatı)' : 'İNŞAAT DEMİRİ SEVKİYATI', style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('7.920,00', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('KG', style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('26,50 TL', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('%20', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('209.880,00 TL', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 7.5))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // 4. TOPLAMLAR VE KDV ÖZETİ
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 250,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('NOTLAR / AÇIKLAMA:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text('İşbu belge 213 sayılı VUK hükümlerine göre düzenlenmiştir.', style: const pw.TextStyle(fontSize: 7)),
                          pw.Text('GİB e-Belge portalı üzerinden resmi olarak onaylanmıştır.', style: const pw.TextStyle(fontSize: 7)),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 210,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 0.5),
                        color: PdfColors.grey100,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Mal/Hizmet Toplamı:', style: const pw.TextStyle(fontSize: 7.5)),
                            pw.Text('209.880,00 TL', style: const pw.TextStyle(fontSize: 7.5)),
                          ]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Hesaplanan KDV (%20):', style: const pw.TextStyle(fontSize: 7.5)),
                            pw.Text('41.976,00 TL', style: const pw.TextStyle(fontSize: 7.5)),
                          ]),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('KDV Tevkifatı (5/10):', style: const pw.TextStyle(fontSize: 7.5)),
                            pw.Text('-20.988,00 TL', style: const pw.TextStyle(fontSize: 7.5)),
                          ]),
                          pw.Divider(thickness: 0.5, color: PdfColors.black),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('ÖDENECEK TUTAR:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                            pw.Text('230.868,00 TL', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate100,
      appBar: AppBar(
        title: Text(documentNo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryBlue),
            tooltip: 'WhatsApp & PDF Paylaş',
            onPressed: () async {
              final pdfBytes = await _generateOfficialDesktopPdf(PdfPageFormat.a4);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${type}_$documentNo.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generateOfficialDesktopPdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: '${type}_$documentNo.pdf',
      ),
    );
  }
}
