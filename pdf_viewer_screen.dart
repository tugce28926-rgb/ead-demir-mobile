import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
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
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocumentPdf();
  }

  Future<void> _loadDocumentPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bytes = await _apiService.getDocumentPdf(widget.type, widget.documentNo);
      if (bytes.isEmpty) {
        setState(() {
          _error = 'Belge veritabanında bulunamadı veya oluşturulamadı.';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Belge yükleme hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    if (_pdfBytes == null) return Uint8List(0);
    return _pdfBytes!;
  }

  @override
  Widget build(BuildContext context) {
    final docTitle = widget.documentNo.isNotEmpty ? widget.documentNo : (widget.type == 'fatura' ? 'e-Fatura' : 'e-İrsaliye');

    return Scaffold(
      backgroundColor: AppTheme.slate100,
      appBar: AppBar(
        title: Text(
          docTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.slate900),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (!_isLoading && _pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: AppTheme.primaryBlue),
              tooltip: 'Paylaş / Yazdır',
              onPressed: () async {
                try {
                  final bytes = await _buildPdf(PdfPageFormat.a4);
                  await Printing.sharePdf(bytes: bytes, filename: '${widget.type}_${widget.documentNo}.pdf');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Paylaşım hatası: $e')),
                    );
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
                  SizedBox(height: 14),
                  Text('Resmi GİB Belgesi Hazırlanıyor...', style: TextStyle(color: AppTheme.slate600, fontSize: 13, fontWeight: FontWeight.w600)),
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
                        const Text('Belge Yüklenemedi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(fontSize: 12, color: AppTheme.slate500), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDocumentPdf,
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
                  loadingWidget: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primaryBlue),
                        SizedBox(height: 12),
                        Text('PDF Oluşturuluyor...', style: TextStyle(color: AppTheme.slate500, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
    );
  }
}
