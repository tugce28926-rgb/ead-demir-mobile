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

  Widget _buildInvoiceCard(RecentInvoice inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NativePdfViewerScreen(
                title: inv.tur,
                documentNo: inv.evrakRef,
                cariAd: inv.cariAd,
                amount: inv.tutar,
                type: 'fatura',
              ),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('📄', style: TextStyle(fontSize: 18))),
        ),
        title: Text(inv.cariAd, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inv.evrakRef} • ${DateFormat('dd.MM.yyyy').format(inv.date)}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(inv.tur, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('GİB ONAYLI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald)),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_currency.format(inv.tutar), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
            const SizedBox(height: 2),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.print, size: 10, color: AppTheme.primaryEmerald),
                SizedBox(width: 2),
                Text('Göster & Yazdır', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
