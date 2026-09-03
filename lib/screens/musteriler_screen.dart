import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/cari_model.dart';
import '../models/baglanti_model.dart';
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
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');
  final TextEditingController _searchController = TextEditingController();

  List<CariSummary> _borclular = [];
  List<CariSummary> _alacaklilar = [];
  List<CariSummary> _tumCariler = [];
  List<Baglanti> _baglantilar = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final borc = await _apiService.getDebtors();
      final alacak = await _apiService.getCreditors();
      final tum = await _apiService.getAllCaris();
      final bag = await _apiService.getBaglantilar();
      setState(() {
        _borclular = borc;
        _alacaklilar = alacak;
        _tumCariler = tum;
        _baglantilar = bag;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Müşteriler & Cariler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.slate500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Borçlular'),
            Tab(text: 'Alacaklılar'),
            Tab(text: 'Tüm Cariler'),
            Tab(text: 'Bağlantılar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : Column(
              children: [
                // Arama Kutusu
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari unvanı veya vergi no ile ara...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.slate200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.slate200)),
                    ),
                  ),
                ),
                // Tab İçerikleri
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCariList(_borclular, isBorclu: true),
                      _buildCariList(_alacaklilar, isBorclu: false),
                      _buildCariList(_tumCariler, isAll: true),
                      _buildBaglantiList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCariList(List<CariSummary> list, {bool isBorclu = true, bool isAll = false}) {
    final filtered = list.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.cariAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.vergiNo != null && c.vergiNo!.contains(_searchQuery));
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Kayıt bulunamadı.', style: TextStyle(color: AppTheme.slate400)));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final c = filtered[index];
          final isPositive = c.bakiye >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              title: Text(
                c.cariAd,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                c.vergiNo ?? c.cariKod,
                style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currency.format(c.bakiye.abs()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isBorclu || (isAll && isPositive) ? AppTheme.primaryRose : AppTheme.primaryEmerald,
                    ),
                  ),
                  Text(
                    isBorclu || (isAll && isPositive) ? 'Borçlu' : 'Alacaklı',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isBorclu || (isAll && isPositive) ? AppTheme.primaryRose : AppTheme.primaryEmerald,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CariDetailScreen(cariKod: c.cariKod, cariAd: c.cariAd)),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBaglantiList() {
    final filtered = _baglantilar.where((b) {
      if (_searchQuery.isEmpty) return true;
      return b.cariAd.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          b.baglantiNo.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('Aktif bağlantı bulunamadı.', style: TextStyle(color: AppTheme.slate400)));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final b = filtered[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.cariAd,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                      child: Text(b.baglantiNo, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sözleşme Tonajı', style: TextStyle(fontSize: 9, color: AppTheme.slate400)),
                        Text('${_kgFormat.format(b.toplamKg)} KG', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Kalan Tonaj', style: TextStyle(fontSize: 9, color: AppTheme.slate400)),
                        Text('${_kgFormat.format(b.kalanKg)} KG', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
