import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/fatura_irsaliye_model.dart';
import '../services/api_service.dart';
import 'irsaliye_yeni_screen.dart';
import 'pdf_viewer_screen.dart';

class IrsaliyeScreen extends StatefulWidget {
  const IrsaliyeScreen({super.key});

  @override
  State<IrsaliyeScreen> createState() => _IrsaliyeScreenState();
}

class _IrsaliyeScreenState extends State<IrsaliyeScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');
  List<RecentWaybill> _waybills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaybills();
  }

  Future<void> _loadWaybills() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getRecentWaybills();
      setState(() {
        _waybills = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni İrsaliye', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const IrsaliyeYeniScreen()));
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadWaybills,
        color: AppTheme.primaryPurple,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('E-İRSALİYE SEVK LİSTESİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                Text('${_waybills.length} İrsaliye', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              ],
            ),
            const SizedBox(height: 10),

            ..._waybills.map((way) => _buildWaybillCard(way)),
          ],
        ),
      ),
    );
  }

  Widget _buildWaybillCard(RecentWaybill way) {
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
                title: 'e-İrsaliye Belgesi',
                documentNo: way.evrakRef,
                cariAd: way.cariAd,
                amount: way.miktarKg,
                type: 'irsaliye',
              ),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('🚚', style: TextStyle(fontSize: 18))),
        ),
        title: Text(way.cariAd, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${way.evrakRef} • ${DateFormat('dd.MM.yyyy').format(way.date)}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
            const SizedBox(height: 4),
            Row(
              children: [
                // Çift Durum Rozeti: GİB Gönderildi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('GÖNDERİLDİ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald)),
                ),
                const SizedBox(width: 4),
                // Çift Durum Rozeti: Faturalandı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text('FATURALANDI', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${_kgFormat.format(way.miktarKg)} KG', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
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
