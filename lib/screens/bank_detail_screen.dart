import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../services/api_service.dart';
import 'bank_transaction_form_screen.dart';

class BankDetailScreen extends StatefulWidget {
  final BankAccount bank;
  final List<BankAccount> allBanks;

  const BankDetailScreen({
    super.key,
    required this.bank,
    required this.allBanks,
  });

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  List<BankTransaction> _transactions = [];
  bool _isLoading = true;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getBankTransactions(widget.bank.bankName);
      setState(() {
        _transactions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTransaction(BankTransaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlemi Sil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${t.cariName.isNotEmpty ? t.cariName : t.description} tutarlı işlemi Zirveden silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRose),
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _apiService.deleteBankTransaction(t.hareketRef);
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppTheme.primaryEmerald, content: Text('İşlem Zirveden başarıyla silindi.')),
          );
          _loadTransactions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('İşlem silinemedi.')),
          );
        }
      }
    }
  }

  void _openTransactionForm(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BankTransactionFormScreen(
          sourceBank: widget.bank,
          allBanks: widget.allBanks,
          initialType: type,
        ),
      ),
    );
    if (result == true) {
      _loadTransactions();
    }
  }

  List<BankTransaction> get _filteredTransactions {
    if (_activeFilter == 'gelir') return _transactions.where((t) => t.isGiris && !t.isPos).toList();
    if (_activeFilter == 'gider') return _transactions.where((t) => !t.isGiris).toList();
    if (_activeFilter == 'pos') return _transactions.where((t) => t.isPos || t.operationType == 'pos').toList();
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.slate900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bank.bankName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900),
            ),
            Text(
              widget.bank.iban.isNotEmpty ? widget.bank.iban : widget.bank.accountType,
              style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.slate200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('HESAP BAKİYESİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.bank.bakiye >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.bank.bakiye >= 0 ? 'Artıda' : 'Ekside',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: widget.bank.bakiye >= 0 ? AppTheme.primaryEmerald : AppTheme.primaryRose,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _currency.format(widget.bank.bakiye),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: widget.bank.bakiye >= 0 ? AppTheme.slate900 : AppTheme.primaryRose,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildActionButton('Virman', Icons.swap_horiz_rounded, const Color(0xFF2563EB), () => _openTransactionForm('virman')),
                    const SizedBox(width: 8),
                    _buildActionButton('Gelen Havale', Icons.arrow_downward_rounded, AppTheme.primaryEmerald, () => _openTransactionForm('gelen_havale')),
                    const SizedBox(width: 8),
                    _buildActionButton('Giden Havale', Icons.arrow_upward_rounded, AppTheme.primaryRose, () => _openTransactionForm('giden_havale')),
                    const SizedBox(width: 8),
                    _buildActionButton('Gider', Icons.receipt_long_rounded, const Color(0xFFD97706), () => _openTransactionForm('gider')),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'Tüm Hareketler (${_transactions.length})'),
                const SizedBox(width: 6),
                _buildFilterChip('pos', 'POS Çekimleri'),
                const SizedBox(width: 6),
                _buildFilterChip('gelir', 'Gelenler / Tahsilat'),
                const SizedBox(width: 6),
                _buildFilterChip('gider', 'Gidenler / Ödeme'),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Text(
                          'Bu filtreye uygun hareket bulunamadı.',
                          style: TextStyle(color: AppTheme.slate400, fontWeight: FontWeight.bold),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTransactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => _buildTransactionCard(_filteredTransactions[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return InkWell(
      onTap: () => setState(() => _activeFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.slate200),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.slate600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BankTransaction t) {
    final isGiris = t.isGiris;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getOpTypeBgColor(t),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getOpTypeLabel(t),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: _getOpTypeTextColor(t),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.tarih != null ? _dateFormat.format(t.tarih!) : '',
                    style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                (isGiris ? '+ ' : '- ') + _currency.format(t.tutar),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isGiris ? AppTheme.primaryEmerald : AppTheme.primaryRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (t.cariName.isNotEmpty) ...[
            Text(
              t.cariName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.slate900,
              ),
            ),
            const SizedBox(height: 2),
          ],

          Text(
            t.description,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // SADECE GİDEN VE GERÇEK MASRAFI OLAN İŞLEMLERDE GÖRÜNÜR
          if (!t.isGiris && !t.isPos && t.eftFee > 0 && (t.operationType == 'giden_havale' || t.operationType == 'virman' || t.operationType == 'odeme' || t.operationType == 'gider')) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_rounded, size: 11, color: Color(0xFFDC2626)),
                  const SizedBox(width: 4),
                  Text(
                    'EFT Masrafı: ${_currency.format(t.eftFee)}',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _deleteTransaction(t),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFE11D48)),
                    SizedBox(width: 4),
                    Text(
                      'Kaydı Sil',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getOpTypeLabel(BankTransaction t) {
    if (t.isPos || t.operationType == 'pos') return 'POS Tahsilatı';
    if (t.operationType == 'virman') return 'Virman';
    if (t.operationType == 'gelen_havale' || (t.isGiris && t.operationType == 'gelir')) return 'Gelen Havale';
    if (t.operationType == 'giden_havale') return 'Giden Havale';
    if (t.operationType == 'gider') return 'Gider';
    return t.isGiris ? 'Giriş' : 'Çıkış';
  }

  Color _getOpTypeBgColor(BankTransaction t) {
    if (t.isPos || t.operationType == 'pos') return const Color(0xFFD1FAE5);
    if (t.operationType == 'virman') return const Color(0xFFDBEAFE);
    if (t.isGiris) return const Color(0xFFD1FAE5);
    return const Color(0xFFFEE2E2);
  }

  Color _getOpTypeTextColor(BankTransaction t) {
    if (t.isPos || t.operationType == 'pos') return const Color(0xFF059669);
    if (t.operationType == 'virman') return const Color(0xFF2563EB);
    if (t.isGiris) return const Color(0xFF059669);
    return const Color(0xFFDC2626);
  }
}
