import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

class PdfViewerScreen extends StatefulWidget {
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

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _numFmt = NumberFormat('#,##0.00', 'tr_TR');
  final NumberFormat _kgFmt = NumberFormat('#,##0.##', 'tr_TR');

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = widget.type == 'fatura'
          ? await _apiService.getFaturaDetail(widget.documentNo)
          : await _apiService.getIrsaliyeDetail(widget.documentNo);
      setState(() { _data = result; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ==================== PDF OLUŞTURMA (MASAÜSTÜ GİB TASARIMI) ====================
  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();
    final data = _data;
    if (data == null) return pdf.save();

    final baslik = data['baslik'] as Map<String, dynamic>? ?? {};
    final gonderici = data['gonderici'] as Map<String, dynamic>? ?? {};
    final kalemler = (data['kalemler'] as List<dynamic>?) ?? [];
    final toplamlar = data['toplamlar'] as Map<String, dynamic>? ?? {};

    final isFatura = widget.type == 'fatura';
    final evrakNo = baslik['evrakNo']?.toString() ?? widget.documentNo;
    final cariAd = baslik['cariAd']?.toString() ?? widget.title;
    final vergiNo = baslik['vergiNo']?.toString() ?? '';
    final vergiD = baslik['vergiDairesi']?.toString() ?? '';
    final cariAdres = baslik['cariAdres']?.toString() ?? 'Türkiye';
    final gibEvrakNo = baslik['gibEvrakNo']?.toString() ?? '';
    final tur = baslik['tur']?.toString() ?? (isFatura ? 'e-Fatura' : 'e-İrsaliye');
    final isIptal = baslik['isIptal'] == true;

    final tarih = baslik['evrakTarihi'] != null
        ? DateFormat('dd.MM.yyyy').format(DateTime.tryParse(baslik['evrakTarihi'].toString()) ?? DateTime.now())
        : DateFormat('dd.MM.yyyy').format(DateTime.now());

    final gUnvan = gonderici['unvan']?.toString() ?? 'EAD DEMİR ÇELİK SANAYİ VE TİCARET LİMİTED ŞİRKETİ';
    final gAdres = gonderici['adres']?.toString() ?? '75. Yıl OSB Mah. 20. Cad. No: 14 Odunpazarı / ESKİŞEHİR';
    final gVkn = gonderici['vkn']?.toString() ?? '3231028021';
    final gVergiD = gonderici['vergiDairesi']?.toString() ?? 'Yunusemre VD.';
    final gTel = gonderici['tel']?.toString() ?? '(0222) 236 00 00';
    final gWeb = gonderici['web']?.toString() ?? 'www.eaddemir.com.tr';

    final malTopla = (toplamlar['malHizmetTopla'] ?? toplamlar['toplamTutar'] ?? 0).toDouble();
    final kdvTopla = (toplamlar['kdvTopla'] ?? 0).toDouble();
    final genelTopla = (toplamlar['genelTopla'] ?? (malTopla + kdvTopla)).toDouble();
    final toplamKg = (toplamlar['toplamKg'] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(18),
        build: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 1. BAŞLIK: Gönderici + GİB Rozeti ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(gUnvan, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(gAdres, style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('Tel: $gTel  |  Web: $gWeb', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('Vergi Dairesi: $gVergiD  |  VKN: $gVkn', style: const pw.TextStyle(fontSize: 7.5)),
                        if (gUnvan.contains('EAD'))
                          pw.Text('Mersis No: 0323114000000001  |  Ticaret Sicil No: 45210', style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    width: 145,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          isFatura ? 'e-FATURA' : 'e-İRSALİYE',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('GELİR İDARESİ BAŞKANLIĞI',
                          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center),
                        pw.Text(isFatura ? 'e-Fatura Sistemi' : 'e-İrsaliye Sistemi',
                          style: const pw.TextStyle(fontSize: 6),
                          textAlign: pw.TextAlign.center),
                        if (gibEvrakNo.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text('GİB No:', style: const pw.TextStyle(fontSize: 5.5)),
                          pw.Text(gibEvrakNo, style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.8, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // ── 2. ALICI + EVRAK BİLGİSİ ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.4)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('SAYIN / MÜŞTERİ BİLGİLERİ',
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text(cariAd, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          if (vergiD.isNotEmpty) pw.Text('Vergi Dairesi: $vergiD', style: const pw.TextStyle(fontSize: 7.5)),
                          if (vergiNo.isNotEmpty) pw.Text('VKN / TCKN: $vergiNo', style: const pw.TextStyle(fontSize: 7.5)),
                          if (cariAdres.isNotEmpty && cariAdres.trim() != 'Türkiye')
                            pw.Text('Adres: $cariAdres', style: const pw.TextStyle(fontSize: 7)),
                          if (isIptal)
                            pw.Text('*** BELGE İPTAL EDİLMİŞTİR ***',
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Container(
                    width: 145,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.4)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfRow('Belge No:', evrakNo),
                        _pdfRow('Tarih:', tarih),
                        _pdfRow('Tür:', tur),
                        if (!isFatura) _pdfRow('GİB Durumu:', baslik['gibDurumu']?.toString() ?? 'Bekliyor'),
                        if (!isFatura) _pdfRow('Faturalandı:', baslik['isFaturalandi'] == true ? 'Evet' : 'Hayır'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── 3. KALEMLER TABLOSU ──
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
                columnWidths: isFatura
                  ? {
                      0: const pw.FixedColumnWidth(22),
                      1: const pw.FlexColumnWidth(4),
                      2: const pw.FixedColumnWidth(55),
                      3: const pw.FixedColumnWidth(30),
                      4: const pw.FixedColumnWidth(55),
                      5: const pw.FixedColumnWidth(30),
                      6: const pw.FixedColumnWidth(58),
                    }
                  : {
                      0: const pw.FixedColumnWidth(22),
                      1: const pw.FlexColumnWidth(4),
                      2: const pw.FixedColumnWidth(65),
                      3: const pw.FixedColumnWidth(35),
                      4: const pw.FixedColumnWidth(60),
                    },
                children: [
                  // Başlık satırı
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: isFatura
                      ? ['No', 'Mal/Hizmet Cinsi', 'Miktar', 'Birim', 'Birim Fiyat', 'KDV%', 'Tutar']
                          .map((h) => _thCell(h)).toList()
                      : ['No', 'Mal/Hizmet Cinsi', 'Miktar (KG)', 'Birim', 'Tutar']
                          .map((h) => _thCell(h)).toList(),
                  ),
                  // Kalemler
                  ...kalemler.asMap().entries.map((entry) {
                    final i = entry.key;
                    final l = entry.value as Map<String, dynamic>;
                    final miktar = (l['MIKTAR'] ?? 0).toDouble();
                    final birim = l['BIRIM']?.toString() ?? 'KG';
                    final birimFiyat = (l['BIRIM_FIYAT'] ?? 0).toDouble();
                    final kdvOran = (l['KDV_ORAN'] ?? 0).toDouble();
                    final tutar = (l['TUTAR'] ?? 0).toDouble();
                    final stokAdi = l['STOKADI']?.toString() ?? '';

                    return pw.TableRow(children: isFatura
                      ? [
                          _tdCell('${i + 1}'),
                          _tdCell(stokAdi, align: pw.TextAlign.left),
                          _tdCell(_kgFmt.format(miktar), align: pw.TextAlign.right),
                          _tdCell(birim),
                          _tdCell('${_numFmt.format(birimFiyat)} ₺', align: pw.TextAlign.right),
                          _tdCell('%${kdvOran.toInt()}', align: pw.TextAlign.center),
                          _tdCell('${_numFmt.format(tutar)} ₺', align: pw.TextAlign.right),
                        ]
                      : [
                          _tdCell('${i + 1}'),
                          _tdCell(stokAdi, align: pw.TextAlign.left),
                          _tdCell(_kgFmt.format(miktar), align: pw.TextAlign.right),
                          _tdCell(birim),
                          _tdCell(tutar > 0 ? '${_numFmt.format(tutar)} ₺' : '-', align: pw.TextAlign.right),
                        ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── 4. TOPLAMLAR ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 230,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.4)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NOTLAR / AÇIKLAMA:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text('İşbu belge 213 sayılı VUK hükümlerine göre düzenlenmiştir.',
                          style: const pw.TextStyle(fontSize: 6.5)),
                        pw.Text('GİB e-Belge portalı üzerinden resmi olarak onaylanmıştır.',
                          style: const pw.TextStyle(fontSize: 6.5)),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 195,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.5),
                      color: PdfColors.grey100,
                    ),
                    child: pw.Column(
                      children: [
                        if (!isFatura)
                          _pdfRowBold('Toplam Miktar:', '${_kgFmt.format(toplamKg)} KG'),
                        if (isFatura)
                          _pdfRowBold('Mal/Hizmet Toplamı:', '${_numFmt.format(malTopla)} ₺'),
                        if (isFatura && kdvTopla > 0)
                          _pdfRowBold('Hesaplanan KDV:', '${_numFmt.format(kdvTopla)} ₺'),
                        pw.Divider(thickness: 0.5, color: PdfColors.black),
                        _pdfRowBoldLarge(
                          isFatura ? 'GENEL TOPLAM:' : 'TOPLAM TUTAR:',
                          isFatura ? '${_numFmt.format(genelTopla)} ₺' : (malTopla > 0 ? '${_numFmt.format(malTopla)} ₺' : '${_numFmt.format(toplamKg)} KG'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ── YARDIMCI: PDF tablo hücre widgetları ──
  pw.Widget _thCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(3),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
  );

  pw.Widget _tdCell(String text, {pw.TextAlign align = pw.TextAlign.center}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 7.5), textAlign: align),
  );

  pw.Widget _pdfRow(String label, String value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 7.5)),
      pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
    ],
  );

  pw.Widget _pdfRowBold(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5)),
        pw.Text(value, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );

  pw.Widget _pdfRowBoldLarge(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate100,
      appBar: AppBar(
        title: Text(widget.documentNo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _data != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppTheme.primaryBlue),
              tooltip: 'PDF Paylaş / Yazdır',
              onPressed: () async {
                try {
                  final bytes = await _buildPdf(PdfPageFormat.a4);
                  await Printing.sharePdf(bytes: bytes, filename: '${widget.type}_${widget.documentNo}.pdf');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF paylaşım hatası: $e')));
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 12),
                  Text('Belge yükleniyor...', style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppTheme.primaryRose, size: 48),
                        const SizedBox(height: 12),
                        const Text('Belge yüklenemedi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(fontSize: 11, color: AppTheme.slate500), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Tekrar Dene'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  build: (format) => _buildPdf(format),
                  allowPrinting: true,
                  allowSharing: true,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  pdfFileName: '${widget.type}_${widget.documentNo}.pdf',
                ),
    );
  }
}
