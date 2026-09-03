import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/cari_model.dart';
import '../services/api_service.dart';
import 'cari_detail_screen.dart';

class MusterilerScreen extends StatefulWidget {
  const MusterilerScreen({super.key});

  @override
  State<MusterilerScreen> createState() => _MusterilerScreenState();
}

class _MusterilerScreenState extends State<MusterilerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  final TextEditingController _searchController = TextEditingController();
  List<CariSummary> _debtors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDebtors();
  }

  Future<void> _loadDebtors() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getDebtors();
      setState(() {
        _debtors = list;
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

    final filteredList = _debtors.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.cariAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.vergiNo != null && c.vergiNo!.contains(_searchQuery));
    }).toList();

    final totalDebt = filteredList.fold<double>(0, (sum, item) => sum + item.bakiye);

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: RefreshIndicator(
        onRefresh: _loadDebtors,
        color: AppTheme.primaryBlue,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Top Ciro & Borç Özeti
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.slate900, Color(0xFF1E293B)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MÜŞTERİ BORÇLULARI (≥ 3.000 ₺)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                  const SizedBox(height: 6),
                  Text(
                    _currency.format(totalDebt),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text('${filteredList.length} Cari Hesap • Canlı Zirve Entegre', style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Arama Çubuğu
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari unvanı veya vergi no ile ara...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('MÜŞTERİ LİSTESİ & BAĞLANTILAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                Text('${filteredList.length} Cari', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              ],
            ),
            const SizedBox(height: 8),

            ...filteredList.map((cari) => _buildCariCard(cari)),
          ],
        ),
      ),
    );
  }

  Widget _buildCariCard(CariSummary cari) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CariDetailScreen(cariAd: cari.cariAd, bakiye: cari.bakiye),
            ),
          );
        },
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text('👥', style: TextStyle(fontSize: 16))),
        ),
        title: Text(cari.cariAd, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('VKN: ${cari.vergiNo ?? '-'}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency.format(cari.bakiye),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryRose),
            ),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bağlantı & Detay ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                Icon(Icons.chevron_right, size: 12, color: AppTheme.primaryBlue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
