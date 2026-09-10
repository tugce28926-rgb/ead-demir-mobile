import 'login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/kpi_model.dart';
import '../models/fatura_irsaliye_model.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'bank_list_screen.dart';
import 'musteriler_screen.dart';
import 'irsaliye_screen.dart';
import 'fatura_screen.dart';
import 'pdf_viewer_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentTabIndex = 0;
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');

  KpiData? _kpiData;
  List<RecentInvoice> _recentInvoices = [];
  List<RecentWaybill> _recentWaybills = [];
  double _netDurumKg = 0.0;
  bool _isLoading = true;
  String _activeTab = 'fat'; // 'fat' or 'irs'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _apiService.setCompany(AppConstants.defaultCompany);

    try {
      final kpi = await _apiService.getKpiData();
      if (mounted) setState(() => _kpiData = kpi);
    } catch (e) {
      debugPrint('KPI Error: $e');
    }

    try {
      final invs = await _apiService.getRecentInvoices();
      if (mounted) setState(() => _recentInvoices = invs);
    } catch (e) {
      debugPrint('Invoices Error: $e');
    }

    try {
      final ways = await _apiService.getRecentWaybills();
      if (mounted) setState(() => _recentWaybills = ways);
    } catch (e) {
      debugPrint('Waybills Error: $e');
    }

    try {
      final netDurum = await _apiService.getNetDurum();
      if (mounted) setState(() => _netDurumKg = netDurum);
    } catch (e) {
      debugPrint('Net Durum Error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: _buildAppBar(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = ApiService.currentUser;
    final initials = user.length >= 2 ? user.substring(0, 2) : (user.isNotEmpty ? user : 'EA');

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: const Center(
              child: Text(
                'EAD',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EAD DEMİR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              ),
              Row(
                children: [
                  const Text('●', style: TextStyle(fontSize: 8, color: Color(0xFF10B981))),
                  const SizedBox(width: 4),
                  Text('Zirve: $user', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.refresh_rounded, color: AppTheme.slate700, size: 18),
          ),
          tooltip: 'Yenile',
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (val) {
            if (val == 'logout') {
              ApiService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aktif Kullanıcı: ' + user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.slate900)),
                  const Text('Zirve Kayıt Yetkisi Açık', style: TextStyle(fontSize: 10, color: AppTheme.slate400)),
                  const Divider(),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppTheme.primaryRose, size: 18),
                  SizedBox(width: 8),
                  Text('Çıkış Yap', style: TextStyle(color: AppTheme.primaryRose, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppTheme.slate900, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const MusterilerScreen();
      case 2:
        return const IrsaliyeScreen();
      case 3:
        return const FaturaScreen();
      case 4:
        return const BankListScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Üst Yönetici Özeti (Hero Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Finans & Yönetim Portalı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate300)),
                    Text(
                      'EAD_DEMIR_2026T',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7)),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'EAD DEMİR ÇELİK',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'Zirve e-Fatura, e-İrsaliye ve Banka Yönetim Sistemi',
                  style: TextStyle(fontSize: 10, color: AppTheme.slate400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Grid: Bugün Fatura & Bugün Sevk
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentTabIndex = 3),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('BUGÜN FATURA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                            Text('📄', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currencyFormat.format(_kpiData?.bugunFaturaTutar ?? 0),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('${_kpiData?.bugunFaturaAdet ?? 0} Adet Kesildi', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentTabIndex = 2),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('BUGÜN SEVK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                            Text('🚚', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_kgFormat.format(_kpiData?.bugunSevkKg ?? 0)} KG',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text('${_kpiData?.bugunSevkAdet ?? 0} İrsaliye Çıktı', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Müşteri Borçları & Net Durum
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentTabIndex = 1),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('MÜŞTERİ BORÇLARI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                              Text('👥', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currencyFormat.format(_kpiData?.musteriBorclari ?? 0),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryRose),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text('Toplam Alacağımız', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('NET DURUM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                            Text('⚖️', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_kgFormat.format(_netDurumKg)} KG',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text('FerroxPro Stok Özeti', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Son İşlemler
          const Text('SON İŞLEMLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
          const SizedBox(height: 10),

          // Fatura / İrsaliye — kapalı gelir, açılınca son 10 kaydı gösterir.
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                iconColor: AppTheme.primaryBlue,
                collapsedIconColor: AppTheme.slate400,
                title: const Text('Fatura / İrsaliye', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                subtitle: const Text('Son 10 işlemi görmek için dokunun', style: TextStyle(fontSize: 10, color: AppTheme.slate400)),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            _buildTabButton('Faturalar', 'fat'),
                            _buildTabButton('İrsaliyeler', 'irs'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_activeTab == 'fat') ...[
                    if (_recentInvoices.isEmpty)
                      _buildEmptyState('Henüz kayıtlı fatura bulunamadı.')
                    else
                      ..._recentInvoices.take(10).map((inv) => _buildInvoiceCard(inv)),
                  ] else ...[
                    if (_recentWaybills.isEmpty)
                      _buildEmptyState('Henüz kayıtlı irsaliye bulunamadı.')
                    else
                      ..._recentWaybills.take(10).map((way) => _buildWaybillCard(way)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isSelected = _activeTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: isSelected ? AppTheme.slate900 : AppTheme.slate500,
          ),
        ),
      ),
    );
  }

  void _openPdf(String documentId, String documentNo, String title, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(documentId: documentId, documentNo: documentNo, title: title, type: type),
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
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: textCol)),
    );
  }

  // Fatura ekranındaki (fatura_screen.dart) kartın birebir aynısı.
  Widget _buildInvoiceCard(RecentInvoice inv) {
    return InkWell(
      onTap: () => _openPdf(inv.id.toString(), inv.evrakRef, inv.cariAd, 'fatura'),
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
                  _currencyFormat.format(inv.tutar),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                ),
              ],
            ),
            if (inv.birimFiyat > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Birim Fiyat (KDV Dahil): ${_currencyFormat.format(inv.birimFiyatKdvDahil)}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${inv.evrakRef} • ${DateFormat("dd.MM.yyyy").format(inv.date)}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
                InkWell(
                  onTap: () => _openPdf(inv.id.toString(), inv.evrakRef, inv.cariAd, 'fatura'),
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
            Row(
              children: [
                _buildBadge(inv.tur, const Color(0xFFEFF6FF), AppTheme.primaryBlue),
                const SizedBox(width: 6),
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

  // İrsaliye ekranındaki (irsaliye_screen.dart) kartın birebir aynısı.
  Widget _buildWaybillCard(RecentWaybill way) {
    return InkWell(
      onTap: () => _openPdf(way.id.toString(), way.evrakRef, way.cariAd, 'irsaliye'),
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
                  child: Text(
                    way.cariAd,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_kgFormat.format(way.miktarKg)} KG',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${way.evrakRef} • ${DateFormat("dd.MM.yyyy").format(way.date)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500),
                ),
                InkWell(
                  onTap: () => _openPdf(way.id.toString(), way.evrakRef, way.cariAd, 'irsaliye'),
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
                        Icon(Icons.print_rounded, size: 11, color: AppTheme.primaryEmerald),
                        SizedBox(width: 3),
                        Text('PDF / GİB', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (way.isIptal)
                  _buildBadge('İPTAL EDİLDİ', const Color(0xFFFEF2F2), AppTheme.primaryRose)
                else if (way.isGibGonderildi)
                  _buildBadge('Gönderildi', const Color(0xFFF0FDF4), AppTheme.primaryEmerald)
                else
                  _buildBadge('Bekliyor', const Color(0xFFFFFBEB), AppTheme.primaryAmber),
                const SizedBox(width: 6),
                if (way.isFaturalandi)
                  _buildBadge(
                    way.faturaNo.isNotEmpty ? 'Faturalandı (${way.faturaNo})' : 'Faturalandı',
                    const Color(0xFFEFF6FF),
                    AppTheme.primaryBlue,
                  )
                else
                  _buildBadge('Faturalanmadı', const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
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
        child: Text(msg, style: const TextStyle(fontSize: 11, color: AppTheme.slate400, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
