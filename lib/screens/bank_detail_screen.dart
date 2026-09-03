import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../services/api_service.dart';
import 'bank_transaction_form_screen.dart';

class BankDetailScreen extends StatefulWidget {
  final String bankName;
  const BankDetailScreen({super.key, required this.bankName});

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
      final list = await _apiService.getBankTransactions(widget.bankName);
      setState(() {
        _transactions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openForm(TransactionFormType type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BankTransactionFormScreen(sourceBankName: widget.bankName, formType: type),
      ),
    );
    if (result == true) {
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: Text(widget.bankName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              color: AppTheme.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Hızlı İşlem Butonları (Grid)
                  _buildQuickActionButtons(),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('İŞLEM GEÇMİŞİ (İZOLASYONLU)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                      Text('${_transactions.length} Kayıt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_transactions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Bu banka için henüz işlem kaydı yok.')))
                  else
                    ..._transactions.map((tx) => _buildTransactionCard(tx)),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionButtons() {
    final isKuveytInvestment = widget.bankName.toUpperCase().contains('KUVEYT') &&
        (widget.bankName.toUpperCase().contains('YATIRIM') || widget.bankName.toUpperCase().contains('FON'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hızlı Banka İşlemleri', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  Icons.arrow_downward,
                  'Gelen Havale',
                  AppTheme.primaryEmerald,
                  const Color(0xFFECFDF5),
                  () => _openForm(TransactionFormType.gelenHavale),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  Icons.arrow_upward,
                  'Giden Havale',
                  AppTheme.primaryRose,
                  const Color(0xFFFFF1F2),
                  () => _openForm(TransactionFormType.gidenHavale),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  Icons.swap_horiz,
                  'Virman Yap',
                  AppTheme.primaryPurple,
                  const Color(0xFFFAF5FF),
                  () => _openForm(TransactionFormType.virman),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionBtn(
                  Icons.receipt_long,
                  'Gider Fişi',
                  AppTheme.primaryAmber,
                  const Color(0xFFFFFBEB),
                  () => _openForm(TransactionFormType.giderFisi),
                ),
              ),
            ],
          ),
          if (isKuveytInvestment) ...[
            const SizedBox(height: 8),
            _buildActionBtn(
              Icons.trending_up,
              'Fon Alış & Satış İşlemleri',
              AppTheme.primaryBlue,
              const Color(0xFFEFF6FF),
              () => _openForm(TransactionFormType.fonAlSat),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String title, Color color, Color bg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BankTransaction tx) {
    final isGider = tx.category == 'gider';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
              Text(
                DateFormat('dd.MM.yyyy').format(tx.date),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isGider ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isGider ? const Color(0xFFFFE4E6) : const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  tx.operationType.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isGider ? AppTheme.primaryRose : AppTheme.primaryEmerald),
                ),
              ),
            ],
          ),
          const Divider(height: 12, color: AppTheme.slate100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.cariName.isEmpty ? '-' : tx.cariName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tx.description,
                      style: const TextStyle(fontSize: 10, color: AppTheme.slate500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${isGider ? '-' : '+'}${_currency.format(tx.amount)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isGider ? AppTheme.primaryRose : AppTheme.primaryEmerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
