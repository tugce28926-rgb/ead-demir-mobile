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
  String _selectedCompany = AppConstants.defaultCompany;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _apiService.setCompany(_selectedCompany);
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
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryBlue, Color(0xFF4F46E5)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.layers_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EAD DEMİR & YAPI',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              ),
              Text(
                _selectedCompany == 'EAD_DEMIR_2026T' ? 'EAD Demir Çelik' : 'HSC Yapı A.Ş.',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showCompanySelector,
          icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.slate700),
          tooltip: 'Şirket Değiştir',
        ),
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.slate700),
          tooltip: 'Yenile',
        ),
      ],
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentTabIndex) {
      case 1:
        return const MusterilerScreen();
      case 2:
        return const IrsaliyeScreen();
      case 3:
        return const FaturaScreen();
      case 4:
        return const BankListScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // 1. KPI Kartları
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'BUGÜN FATURA',
                  value: _currencyFormat.format(_kpiData?.bugunFaturaTutar ?? 0),
                  subtitle: '${_kpiData?.bugunFaturaAdet ?? 0} Adet Kesildi',
                  icon: '📄',
                  color: AppTheme.primaryBlue,
                  onTap: () => setState(() => _currentTabIndex = 3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  title: 'BUGÜN SEVK',
                  value: '${_kgFormat.format(_kpiData?.bugunSevkKg ?? 0)} KG',
                  subtitle: '${_kpiData?.bugunSevkAdet ?? 0} İrsaliye Çıktı',
                  icon: '🚚',
                  color: AppTheme.primaryPurple,
                  onTap: () => setState(() => _currentTabIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Müşteri Borçları KPI Kartı
          _buildDebtorsKpiCard(),
          const SizedBox(height: 18),

          // 3. Son İşlemler (Faturalar / İrsaliyeler)
          _buildRecentTransactionsSection(),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500),
                ),
                Text(icon, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtorsKpiCard() {
    return InkWell(
      onTap: () => setState(() => _currentTabIndex = 1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: const Center(child: Text('👥', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÜŞTERİ BORÇLARI',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500),
                    ),
                    Text(
                      'Toplam Alacağımız',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.slate400),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(_kpiData?.musteriBorclari ?? 1718285.87),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryRose),
                ),
                const Row(
                  children: [
                    Text(
                      'İncele ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryRose),
                    ),
                    Icon(Icons.chevron_right, size: 12, color: AppTheme.primaryRose),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'SON İŞLEMLER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTheme.slate200.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('fat', 'Faturalar'),
                      _buildTabButton('irs', 'İrsaliyeler'),
                    ],
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentTabIndex = _activeTab == 'fat' ? 3 : 2);
              },
              child: const Text('Tümü →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_activeTab == 'fat') ...[
          if (_recentInvoices.isEmpty)
            _buildEmptyState('Henüz kayıtlı fatura bulunamadı.')
          else
            ..._recentInvoices.take(5).map((inv) => _buildInvoiceItem(inv)),
        ] else ...[
          if (_recentWaybills.isEmpty)
            _buildEmptyState('Henüz kayıtlı irsaliye bulunamadı.')
          else
            ..._recentWaybills.take(5).map((way) => _buildWaybillItem(way)),
        ],
      ],
    );
  }

  Widget _buildTabButton(String tab, String title) {
    final isSelected = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2)] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.slate900 : AppTheme.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(RecentInvoice inv) {
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${inv.evrakRef} • ${DateFormat('dd.MM.yyyy').format(inv.date)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
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
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      inv.tur,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.print, size: 9, color: AppTheme.primaryEmerald),
                        SizedBox(width: 2),
                        Text(
                          'PDF',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaybillItem(RecentWaybill way) {
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${way.evrakRef} • ${DateFormat('dd.MM.yyyy').format(way.date)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
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
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: const Text(
                      'e-İrsaliye',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.print, size: 9, color: AppTheme.primaryEmerald),
                        SizedBox(width: 2),
                        Text(
                          'PDF',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryEmerald),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppTheme.slate400),
        ),
      ),
    );
  }

  void _showCompanySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Aktif Çalışılan Şirket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...AppConstants.companies.map((comp) {
                final isSelected = _selectedCompany == comp['db'];
                return ListTile(
                  title: Text(comp['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue) : null,
                  onTap: () {
                    setState(() => _selectedCompany = comp['db']!);
                    Navigator.pop(context);
                    _loadData();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
