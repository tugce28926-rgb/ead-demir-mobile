import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/fatura_irsaliye_model.dart';
import '../services/api_service.dart';
import 'pdf_viewer_screen.dart';

class FaturaScreen extends StatefulWidget {
  const FaturaScreen({super.key});

  @override
  State<FaturaScreen> createState() => _FaturaScreenState();
}

class _FaturaScreenState extends State<FaturaScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  List<RecentInvoice> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getRecentInvoices();
      setState(() {
        _invoices = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('e-Faturalar & e-Arşivler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadInvoices,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.slate700),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoices,
        color: AppTheme.primaryBlue,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('E-FATURA & E-ARŞİV LİSTESİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                Text('${_invoices.length} Fatura', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              ],
            ),
            const SizedBox(height: 10),

            ..._invoices.map((inv) => _buildInvoiceCard(inv)),
          ],
        ),
      ),
    );
  }

  void _openInvoicePdf(RecentInvoice inv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          documentId: inv.id.toString(),
          documentNo: inv.evrakRef,
          title: inv.cariAd,
          type: 'fatura',
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(RecentInvoice inv) {
    return InkWell(
      onTap: () => _openInvoicePdf(inv),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  inv.cariAd,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _currency.format(inv.tutar),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              ),
            ],
          ),
          if (inv.birimFiyat > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Birim Fiyat (KDV Dahil): ${_currency.format(inv.birimFiyatKdvDahil)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${inv.evrakRef} • ${DateFormat("dd.MM.yyyy").format(inv.date)}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
              InkWell(
                onTap: () => _openInvoicePdf(inv),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.print, size: 10, color: AppTheme.primaryEmerald),
                      SizedBox(width: 3),
                      Text('Göster & Yazdır', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // DOĞRU VE GERÇEK FATURA ROZETLERİ
          Row(
            children: [
              // 1. Fatura Türü
              _buildBadge(inv.tur, const Color(0xFFEFF6FF), AppTheme.primaryBlue),
              const SizedBox(width: 6),

              // 2. GİB Durumu
              if (inv.isIptal)
                _buildBadge('İPTAL EDİLDİ', const Color(0xFFFEF2F2), AppTheme.primaryRose)
              else if (inv.isGibGonderildi)
                _buildBadge('GİB Onaylı', const Color(0xFFF0FDF4), AppTheme.primaryEmerald)
              else
                _buildBadge('GİB Bekliyor (Taslak)', const Color(0xFFFFFBEB), AppTheme.primaryAmber),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textCol.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textCol),
      ),
    );
  }
}
