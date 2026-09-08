import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/baglanti_model.dart';
import '../services/api_service.dart';

class CariDetailScreen extends StatefulWidget {
  final String cariAd;
  final double bakiye;
  final String vergiNo;

  const CariDetailScreen({
    super.key,
    required this.cariAd,
    required this.bakiye,
    this.vergiNo = '',
  });

  @override
  State<CariDetailScreen> createState() => _CariDetailScreenState();
}

class _CariDetailScreenState extends State<CariDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');

  List<Baglanti> _baglantilar = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBaglantilar();
  }

  Future<void> _loadBaglantilar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (widget.vergiNo.trim().isEmpty) {
      setState(() {
        _baglantilar = [];
        _isLoading = false;
      });
      return;
    }
    try {
      final list = await _apiService.getBaglantilarForCari(widget.vergiNo);
      setState(() {
        _baglantilar = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Bağlantılar yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktif = _baglantilar.where((b) => b.status == 'aktif').toList();
    final gecmis = _baglantilar.where((b) => b.status != 'aktif').toList();

    // Üst özet: her bağlantı kendi KG'siyle listede ayrı ayrı gösteriliyor,
    // buradaki toplamlar sadece hızlı bir genel bakış için.
    final toplamKalanKg = aktif.fold<double>(0, (s, b) => s + b.kalanKg);
    final toplamKalanTutar = aktif.fold<double>(0, (s, b) => s + b.kalanTutar);
    final toplamSatisKg = _baglantilar.fold<double>(0, (s, b) => s + b.kullanilanKg);

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Müşteri Bağlantı & Cari Detayı', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadBaglantilar,
              color: AppTheme.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _buildCariHeaderCard(),
                  const SizedBox(height: 14),

                  _buildKpiMetricsGrid(aktif.length, toplamKalanKg, toplamKalanTutar, toplamSatisKg),
                  const SizedBox(height: 18),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE4E6)),
                      ),
                      child: Text(_error!, style: const TextStyle(fontSize: 11, color: AppTheme.primaryRose)),
                    )
                  else if (widget.vergiNo.trim().isEmpty)
                    _buildEmptyState('Bu carinin vergi numarası bulunamadığı için bağlantı geçmişi getirilemedi.')
                  else ...[
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
                          Tab(text: 'Aktif Bağlantılar (${aktif.length})'),
                          Tab(text: 'Geçmiş Bağlantılar (${gecmis.length})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 420,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBaglantiListView(aktif, 'Aktif bağlantı bulunamadı.'),
                          _buildBaglantiListView(gecmis, 'Geçmiş bağlantı bulunamadı.'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBaglantiListView(List<Baglanti> list, String emptyMsg) {
    if (list.isEmpty) return _buildEmptyState(emptyMsg);
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (context, index) => _buildBaglantiCard(list[index]),
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
                'Bakiye: ${_currency.format(widget.bakiye)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: widget.bakiye > 0 ? AppTheme.primaryRose : AppTheme.primaryEmerald),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.cariAd,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900),
          ),
          if (widget.vergiNo.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('VKN: ${widget.vergiNo}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid(int aktifSayisi, double kalanKg, double kalanTutar, double satisKg) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _buildMetricItem('AKTİF BAĞLANTI', '$aktifSayisi Adet', '🔗', AppTheme.primaryBlue, const Color(0xFFEFF6FF)),
        _buildMetricItem('KALAN TUTAR', _currency.format(kalanTutar), '📉', AppTheme.primaryRose, const Color(0xFFFFF1F2)),
        _buildMetricItem('TOPLAM KALAN', '${_kgFormat.format(kalanKg)} KG', '⚖️', AppTheme.primaryPurple, const Color(0xFFFAF5FF)),
        _buildMetricItem('TOPLAM SEVK', '${_kgFormat.format(satisKg)} KG', '🚚', AppTheme.primaryEmerald, const Color(0xFFECFDF5)),
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

  Widget _buildBaglantiCard(Baglanti bgl) {
    return InkWell(
      onTap: () => _showBaglantiDetail(bgl),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  child: Text(bgl.baglantiNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                ),
                if (bgl.tevkifat) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(4)),
                    child: const Text('TEVKİFAT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.primaryAmber)),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgl.status == 'aktif' ? const Color(0xFFECFDF5) : AppTheme.slate100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: bgl.status == 'aktif' ? const Color(0xFFA7F3D0) : AppTheme.slate200),
                  ),
                  child: Text(
                    bgl.status == 'aktif' ? 'AKTİF SEVKLER' : 'KAPANDI',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: bgl.status == 'aktif' ? AppTheme.primaryEmerald : AppTheme.slate500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_kgFormat.format(bgl.toplamKg)} KG • ${_currency.format(bgl.birimFiyat)}/KG${bgl.baglantiTarihi.isNotEmpty ? ' • ${bgl.baglantiTarihi}' : ''}',
              style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
            ),
            const SizedBox(height: 10),

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
                  'Sevk Edilen: ${_kgFormat.format(bgl.kullanilanKg)} KG',
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
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(fontSize: 11, color: AppTheme.slate400, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ),
    );
  }

  // Web paneldeki "openCariModal / renderCard" ile aynı mantık: bağlantıya tıklayınca
  // sevkiyat (satış) geçmişini ve ilerleme detayını gösteren alt panel.
  void _showBaglantiDetail(Baglanti bgl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(4))),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(bgl.baglantiNo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.slate400), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _detailChip('Toplam', '${_kgFormat.format(bgl.toplamKg)} KG'),
                    _detailChip('Birim Fiyat', _currency.format(bgl.birimFiyat)),
                    _detailChip('Sevk Edilen', '${_kgFormat.format(bgl.kullanilanKg)} KG'),
                    _detailChip('Kalan', '${_kgFormat.format(bgl.kalanKg)} KG'),
                    _detailChip('Kalan Tutar', _currency.format(bgl.kalanTutar)),
                    if (bgl.tevkifat) _detailChip('Tevkifat', 'Var'),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('SEVKİYAT GEÇMİŞİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                ),
              ),
              Expanded(
                child: bgl.satislar.isEmpty
                    ? const Center(child: Text('Bu bağlantıya ait sevkiyat kaydı bulunamadı.', style: TextStyle(color: AppTheme.slate400, fontSize: 12)))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        itemCount: bgl.satislar.length,
                        separatorBuilder: (_, __) => const Divider(height: 18),
                        itemBuilder: (ctx, i) {
                          final s = bgl.satislar[i];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.evrakNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                                    const SizedBox(height: 2),
                                    Text(s.tarih, style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${_kgFormat.format(s.toplamKg)} KG', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                                  Text(_currency.format(s.bagTutar), style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        ],
      ),
    );
  }
}
