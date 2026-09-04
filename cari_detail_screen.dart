import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/baglanti_model.dart';

class CariDetailScreen extends StatefulWidget {
  final String cariAd;
  final double bakiye;

  const CariDetailScreen({
    super.key,
    required this.cariAd,
    required this.bakiye,
  });

  @override
  State<CariDetailScreen> createState() => _CariDetailScreenState();
}

class _CariDetailScreenState extends State<CariDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');

  // Örnek Demir-Çelik Bağlantı Verileri
  late CariDetailData _detailData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _detailData = CariDetailData(
      cariAd: widget.cariAd,
      vergiNo: '1234567890',
      vergiDairesi: 'İSTANBUL VD.',
      telefon: '0532 123 45 67',
      sehir: 'İstanbul / Ümraniye',
      bakiye: widget.bakiye,
      toplamCiro: 4850000.0,
      kalanTutar: widget.bakiye,
      kalanBaglantiKg: 120500.0,
      toplamSatisKg: 340000.0,
      baglantilar: [
        BaglantiItem(
          id: 'BGL-2026-001',
          baslik: 'Nervürlü İnşaat Demiri Bağlantısı (12-32mm)',
          toplamKg: 200000,
          teslimEdilenKg: 140000,
          kalanKg: 60000,
          birimFiyat: 24.50,
          toplamTutar: 4900000,
          kalanTutar: 1470000,
          baslangicTarihi: DateTime(2026, 1, 10),
          bitisTarihi: DateTime(2026, 6, 30),
          isAktif: true,
        ),
        BaglantiItem(
          id: 'BGL-2026-002',
          baslik: 'Kutu Profil & Sanayi Borusu Alımı',
          toplamKg: 100000,
          teslimEdilenKg: 39500,
          kalanKg: 60500,
          birimFiyat: 28.00,
          toplamTutar: 2800000,
          kalanTutar: 1694000,
          baslangicTarihi: DateTime(2026, 2, 1),
          bitisTarihi: DateTime(2026, 8, 15),
          isAktif: true,
        ),
        BaglantiItem(
          id: 'BGL-2025-089',
          baslik: 'Hasır Çelik (Q Tipi) Sevk Projesi',
          toplamKg: 50000,
          teslimEdilenKg: 50000,
          kalanKg: 0,
          birimFiyat: 22.00,
          toplamTutar: 1100000,
          kalanTutar: 0,
          baslangicTarihi: DateTime(2025, 9, 1),
          bitisTarihi: DateTime(2025, 12, 31),
          isAktif: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final aktifBaglantilar = _detailData.baglantilar.where((b) => b.isAktif).toList();
    final gecmisBaglantilar = _detailData.baglantilar.where((b) => !b.isAktif).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Müşteri Bağlantı & Cari Detayı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Cari Üst Kartı
          _buildCariHeaderCard(),
          const SizedBox(height: 14),

          // 4'lü Demir-Çelik KPI Grid
          _buildKpiMetricsGrid(),
          const SizedBox(height: 18),

          // Bağlantı Sekmeleri
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.slate500,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Aktif Bağlantılar (${aktifBaglantilar.length})'),
                Tab(text: 'Geçmiş Bağlantılar (${gecmisBaglantilar.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bağlantı Kartları Listesi
          ...aktifBaglantilar.map((bgl) => _buildBaglantiCard(bgl)),
        ],
      ),
    );
  }

  Widget _buildCariHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ZİRVE CARİ KARTI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
              ),
              Text(
                'Bakiye: ${_currency.format(_detailData.bakiye)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _detailData.bakiye > 0 ? AppTheme.primaryRose : AppTheme.primaryEmerald),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _detailData.cariAd,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900),
          ),
          const SizedBox(height: 4),
          Text(
            'VKN: ${_detailData.vergiNo} • ${_detailData.vergiDairesi} • ${_detailData.sehir}',
            style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _buildMetricItem('TOPLAM CİRO', _currency.format(_detailData.toplamCiro), '💰', AppTheme.primaryBlue, const Color(0xFFEFF6FF)),
        _buildMetricItem('KALAN TUTAR', _currency.format(_detailData.kalanTutar), '📉', AppTheme.primaryRose, const Color(0xFFFFF1F2)),
        _buildMetricItem('KALAN BAĞLANTI', '${_kgFormat.format(_detailData.kalanBaglantiKg)} KG', '⚖️', AppTheme.primaryPurple, const Color(0xFFFAF5FF)),
        _buildMetricItem('TOPLAM SATIŞ', '${_kgFormat.format(_detailData.toplamSatisKg)} KG', '🚚', AppTheme.primaryEmerald, const Color(0xFFECFDF5)),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, String icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
              Text(icon, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBaglantiCard(BaglantiItem bgl) {
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
              Text(bgl.id, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate400)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bgl.isAktif ? const Color(0xFFECFDF5) : AppTheme.slate100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: bgl.isAktif ? const Color(0xFFA7F3D0) : AppTheme.slate200),
                ),
                child: Text(
                  bgl.isAktif ? 'AKTİF SEVKLER' : 'KAPANDI',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: bgl.isAktif ? AppTheme.primaryEmerald : AppTheme.slate500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(bgl.baslik, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 10),

          // İlerleme Çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: bgl.tamamlanmaOrani,
              backgroundColor: AppTheme.slate100,
              color: AppTheme.primaryBlue,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Teslim: ${_kgFormat.format(bgl.teslimEdilenKg)} KG',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              Text(
                'Kalan: ${_kgFormat.format(bgl.kalanKg)} KG',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
