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
  bool _isLoading = true;
  String _activeTab = 'fat'; // 'fat' or 'irs'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _apiService.setCompany(AppConstants.defaultCompany);
      final kpi = await _apiService.getKpiData();
      final invs = await _apiService.getRecentInvoices();
      final ways = await _apiService.getRecentWaybills();
      setState(() {
        _kpiData = kpi;
        _recentInvoices = invs;
        _recentWaybills = ways;
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
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          // Authentic EAD Blue Badge Logo
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EAD DEMİR',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              ),
              Row(
                children: [
                  Text('●', style: TextStyle(fontSize: 8, color: Color(0xFF10B981))),
                  SizedBox(width: 4),
                  Text('Zirve Çevrimiçi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
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
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppTheme.slate900, borderRadius: BorderRadius.circular(10)),
            child: const Center(
              child: Text('TU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
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
              // Bugün Fatura
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
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

              // Bugün Sevk
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
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
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

          // Alt Geniş Kart: Müşteri Borçları
          InkWell(
            onTap: () => setState(() => _currentTabIndex = 1),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE4E6)),
                        ),
                        child: const Center(child: Text('👥', style: TextStyle(fontSize: 18))),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MÜŞTERİ BORÇLARI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                          Text('Toplam Alacağımız', style: TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(_kpiData?.musteriBorclari ?? 1718285.87),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryRose),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Text('İncele', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryRose)),
                          Icon(Icons.chevron_right_rounded, size: 12, color: AppTheme.primaryRose),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Son İşlemler Başlığı & Sekmeler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SON İŞLEMLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
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

          // Son İşlemler Listesi
          if (_activeTab == 'fat') ...[
            if (_recentInvoices.isEmpty)
              _buildEmptyState('Henüz kayıtlı fatura bulunamadı.')
            else
              ..._recentInvoices.map((inv) => _buildInvoiceCard(inv)),
          ] else ...[
            if (_recentWaybills.isEmpty)
              _buildEmptyState('Henüz kayıtlı irsaliye bulunamadı.')
            else
              ..._recentWaybills.map((way) => _buildWaybillCard(way)),
          ],
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
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
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

  Widget _buildInvoiceCard(RecentInvoice inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.cariAd,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${inv.evrakRef} • ${DateFormat('dd/MM').format(inv.date)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: inv.tur == 'e-Fatura' ? const Color(0xFFEFF6FF) : const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inv.tur,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: inv.tur == 'e-Fatura' ? AppTheme.primaryBlue : AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(inv.tutar),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
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
                },
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
                      Icon(Icons.print_rounded, size: 10, color: AppTheme.primaryEmerald),
                      SizedBox(width: 3),
                      Text('PDF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaybillCard(RecentWaybill way) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  way.cariAd,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${way.evrakRef} • ${DateFormat('dd/MM').format(way.date)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_kgFormat.format(way.miktarKg)} KG',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        documentId: way.id.toString(),
                        documentNo: way.evrakRef,
                        title: way.cariAd,
                        type: 'irsaliye',
                      ),
                    ),
                  );
                },
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
                      Icon(Icons.print_rounded, size: 10, color: AppTheme.primaryEmerald),
                      SizedBox(width: 3),
                      Text('PDF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
