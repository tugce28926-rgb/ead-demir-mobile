import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/kpi_model.dart';
import '../models/fatura_irsaliye_model.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'login_screen.dart';
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
            const PopupMenuItem(
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
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GÜNCEL FİNANS ÖZETİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate300, letterSpacing: 0.5)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bu Ay: ${_kgFormat.format(_kpiData?.toplamSatisKg ?? 0)} KG',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOPLAM ALACAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            _currencyFormat.format(_kpiData?.toplamAlacak ?? 0),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOPLAM BORÇ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            _currencyFormat.format(_kpiData?.toplamBorc ?? 0),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFF87171)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('NET NAKİT / BANKA:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate300)),
                    Text(
                      _currencyFormat.format(_kpiData?.bankaNetBakiye ?? 0),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Segment Selector (Faturalar / İrsaliyeler)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 'fat'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 'fat' ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Son Faturalar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _activeTab == 'fat' ? Colors.white : AppTheme.slate600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 'irs'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 'irs' ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Son İrsaliyeler',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: _activeTab == 'irs' ? Colors.white : AppTheme.slate600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Liste Görünümü
          if (_activeTab == 'fat') ...[
            if (_recentInvoices.isEmpty)
              _buildEmptyPlaceholder('Kayıtlı fatura bulunamadı.')
            else
              ..._recentInvoices.map((inv) => _buildInvoiceCard(inv)),
          ] else ...[
            if (_recentWaybills.isEmpty)
              _buildEmptyPlaceholder('Kayıtlı irsaliye bulunamadı.')
            else
              ..._recentWaybills.map((w) => _buildWaybillCard(w)),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(RecentInvoice inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inv.evrakNo,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate500),
              ),
              Text(
                inv.tarih != null ? DateFormat('dd.MM.yyyy').format(inv.tarih!) : '',
                style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            inv.cariUnvan,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_kgFormat.format(inv.miktar)} KG',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate600),
              ),
              Text(
                _currencyFormat.format(inv.genelToplam),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaybillCard(RecentWaybill w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                w.irsaliyeNo,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate500),
              ),
              Text(
                w.tarih != null ? DateFormat('dd.MM.yyyy').format(w.tarih!) : '',
                style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            w.cariUnvan,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_kgFormat.format(w.miktar)} KG',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate600),
              ),
              Text(
                w.durum,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.slate400)),
      ),
    );
  }
}
