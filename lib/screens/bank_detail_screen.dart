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
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  List<BankTransaction> _transactions = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: Text(widget.bank.bankName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              color: AppTheme.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Bank Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bank.bankName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        if (widget.bank.iban.isNotEmpty)
                          Text('IBAN: ${widget.bank.iban}', style: const TextStyle(fontSize: 10, color: AppTheme.slate300, fontFamily: 'monospace')),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GÜNCEL BAKİYE:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                            Text(_currency.format(widget.bank.bakiye), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4 QUICK ACTION BUTTONS (Tahsilat, Ödeme, Virman, Gider)
                  Row(
                    children: [
                      _buildQuickAction('Tahsilat', Icons.arrow_downward_rounded, 'gelen_havale', AppTheme.primaryEmerald),
                      const SizedBox(width: 6),
                      _buildQuickAction('Ödeme', Icons.arrow_upward_rounded, 'giden_havale', AppTheme.primaryRose),
                      const SizedBox(width: 6),
                      _buildQuickAction('Virman', Icons.swap_horiz_rounded, 'virman', AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      _buildQuickAction('Gider', Icons.receipt_long_rounded, 'gider', AppTheme.primaryAmber),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('SON HESAP HAREKETLERİ (CBK İŞLEMLERİ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                  const SizedBox(height: 8),

                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('Kayıtlı hesap hareketi bulunamadı.', style: TextStyle(color: AppTheme.slate400, fontSize: 11))),
                    )
                  else
                    ..._transactions.map((t) => _buildTransactionCard(t)),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, String type, Color color) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BankTransactionFormScreen(sourceBank: widget.bank, allBanks: widget.allBanks, initialType: type),
            ),
          ).then((_) => _loadTransactions());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BankTransaction t) {
    final isGiris = t.borc > 0;
    final amount = isGiris ? t.borc : t.alacak;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                  t.aciklama.isNotEmpty ? t.aciklama : (t.cariName.isNotEmpty ? t.cariName : 'Banka Hareketi'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd.MM.yyyy').format(t.tarih),
                  style: const TextStyle(fontSize: 9, color: AppTheme.slate400),
                ),
              ],
            ),
          ),
          Text(
            (isGiris ? '+ ' : '- ') + _currency.format(amount > 0 ? amount : t.amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: isGiris ? AppTheme.primaryEmerald : AppTheme.primaryRose,
            ),
          ),
        ],
      ),
    );
  }
}
