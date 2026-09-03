import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../services/api_service.dart';
import 'bank_detail_screen.dart';

class BankListScreen extends StatefulWidget {
  const BankListScreen({super.key});

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  List<BankAccount> _banks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getBanks();
      setState(() {
        _banks = data;
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

    final visibleBanks = _banks.where((b) => !b.hidden).toList();
    final hiddenBanks = _banks.where((b) => b.hidden).toList();

    return RefreshIndicator(
      onRefresh: _loadBanks,
      color: AppTheme.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BANKA HESAPLARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
              Text('${visibleBanks.length} Hesap', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
            ],
          ),
          const SizedBox(height: 10),

          ...visibleBanks.map((bank) => _buildBankCard(bank)),

          if (hiddenBanks.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text('Gizlenen Bankalar (${hiddenBanks.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
              children: hiddenBanks.map((bank) => _buildHiddenBankItem(bank)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankCard(BankAccount bank) {
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => BankDetailScreen(bankName: bank.name)));
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.slate100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue, size: 20)),
        ),
        title: Text(bank.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
        subtitle: Text(bank.subtitle ?? 'Zirve Entegre Hesap', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency.format(bank.balance),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: bank.balance < 0 ? AppTheme.primaryRose : AppTheme.slate900,
              ),
            ),
            const SizedBox(height: 2),
            const Text('Detay →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenBankItem(BankAccount bank) {
    return ListTile(
      title: Text(bank.name, style: const TextStyle(fontSize: 12, color: AppTheme.slate600)),
      trailing: TextButton(
        onPressed: () async {
          await _apiService.unhideBank(bank.name);
          _loadBanks();
        },
        child: const Text('Geri Aç', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
      ),
    );
  }
}
