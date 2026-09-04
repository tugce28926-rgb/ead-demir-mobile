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

  Future<Uint8List> _generateOfficialPdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final isFatura = type == 'fatura';
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 2);
    final dateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Resmi Başlık / Logo & Kurumsal Bilgi
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EAD DEMİR ÇELİK SAN. VE TİC. LTD. ŞTİ.',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('75. Yıl OSB Mah. 20. Cad. No: 14 Odunpazarı / ESKİŞEHİR', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('Vergi Dairesi: Yunusemre VD. | VKN: 3231140000', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('Mersis No: 0323114000000001 | Ticaret Sicil: 45210', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(isFatura ? 'e-FATURA' : 'e-İRSALİYE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('GİB Resmi Belgesi', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // 2. Alıcı / Cari Bilgileri & Belge Detayları
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('SAYIN / ALICI:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.SizedBox(height: 3),
                          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text('Vergi Dairesi / VKN: İlgili Zirve Cari Kartı', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          pw.Text('Adres: Türkiye', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Belge No:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            pw.Text(documentNo, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                          ]),
                          pw.SizedBox(height: 2),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Düzenleme Tarihi:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            pw.Text(dateStr, style: const pw.TextStyle(fontSize: 8)),
                          ]),
                          pw.SizedBox(height: 2),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Düzenleme Saati:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            pw.Text('14:30:00', style: const pw.TextStyle(fontSize: 8)),
                          ]),
                          pw.SizedBox(height: 2),
                          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                            pw.Text('Senaryo:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                            pw.Text('TİCARİFATURA', style: const pw.TextStyle(fontSize: 8)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // 3. Kalemler Tablosu
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('S.No', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Mal / Hizmet Açıklaması', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Miktar', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Birim', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Birim Fiyat', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('KDV %', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tutar', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('1', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(isFatura ? 'NERVÜRLÜ İNŞAAT DEMİRİ (Zirve Sevkiyatı)' : 'İNŞAAT DEMİRİ SEVKİYATI', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('7.920,00', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('KG', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('26,50 TL', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('%20', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('209.880,00 TL', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // 4. Alt Toplamlar ve KDV Özeti
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 260,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Açıklama / Notlar:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('İşbu belge 213 sayılı V.U.K. hükümlerine göre düzenlenmiştir.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('GİB e-Belge portalı üzerinden resmi olarak onaylanmıştır.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('Mal/Hizmet Toplamı:', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('209.880,00 TL', style: const pw.TextStyle(fontSize: 8)),
                        ]),
                        pw.SizedBox(height: 2),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('Hesaplanan KDV (%20):', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('41.976,00 TL', style: const pw.TextStyle(fontSize: 8)),
                        ]),
                        pw.SizedBox(height: 2),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('KDV Tevkifatı (5/10):', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('-20.988,00 TL', style: const pw.TextStyle(fontSize: 8)),
                        ]),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                          pw.Text('ÖDENECEK TUTAR:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.Text('230.868,00 TL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
              final pdfBytes = await _generateOfficialPdf(PdfPageFormat.a4);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${type}_$documentNo.pdf',
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generateOfficialPdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: '${type}_$documentNo.pdf',
      ),
    );
  }
}
