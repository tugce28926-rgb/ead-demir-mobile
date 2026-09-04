import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../services/api_service.dart';
import 'bank_detail_screen.dart';
import 'bank_transaction_form_screen.dart';

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
      final list = await _apiService.getBanks();
      setState(() {
        _banks = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _banks.where((b) => !b.hidden).fold<double>(0, (sum, b) => sum + b.bakiye);

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Banka & Kasa Yönetimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        actions: [
          IconButton(
            onPressed: _loadBanks,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.slate700),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadBanks,
              color: AppTheme.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Top Total Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.slate900, Color(0xFF1E293B), Color(0xFF312E81)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOPLAM NET BANKA BAKİYESİ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                        const SizedBox(height: 6),
                        Text(
                          _currency.format(totalBalance),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text('${_banks.length} Hesap • Canlı Zirve Bakiyeleri', style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Hızlı İşlem Butonları (Virman, Tahsilat, Ödeme)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_banks.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BankTransactionFormScreen(sourceBank: _banks.first, allBanks: _banks, initialType: 'virman'),
                                ),
                              ).then((_) => _loadBanks());
                            }
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                          label: const Text('Virman / Transfer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text('HESAPLAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                  const SizedBox(height: 8),

                  ..._banks.map((b) => _buildBankCard(b)),
                ],
              ),
            ),
    );
  }

  Widget _buildBankCard(BankAccount bank) {
    final isNegative = bank.bakiye < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue, size: 20),
          ),
        ),
        title: Text(
          bank.bankName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bank.branch.isNotEmpty) Text(bank.branch, style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
            if (bank.iban.isNotEmpty) Text(bank.iban, style: const TextStyle(fontSize: 9, color: AppTheme.slate400, fontFamily: 'monospace')),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency.format(bank.bakiye),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isNegative ? AppTheme.primaryRose : AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                bank.accountType.isNotEmpty ? bank.accountType : 'Vadesiz',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.slate600),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BankDetailScreen(bank: bank, allBanks: _banks)),
          ).then((_) => _loadBanks());
        },
      ),
    );
  }
}
