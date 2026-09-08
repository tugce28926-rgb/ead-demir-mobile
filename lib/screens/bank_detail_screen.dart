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
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

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

                  // İŞLEM GEÇMİŞİ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İŞLEM GEÇMİŞİ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.3),
                      ),
                      Text(
                        '${_transactions.length} Kayıt',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.slate200)),
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
    final isGiris = t.isGiris;
    final amount = t.amount > 0 ? t.amount : (isGiris ? t.borc : t.alacak);
    final String badgeText = _getBadgeText(t);
    final Color badgeBg = _getBadgeBg(t);
    final Color badgeFg = _getBadgeFg(t);

    final String mainTitle = t.cariName.isNotEmpty
        ? t.cariName
        : (t.operationType == 'virman' ? 'Banka Virmanı' : (t.description.isNotEmpty ? t.description : 'Banka Hareketi'));

    final String subTitle = t.description.isNotEmpty ? t.description : 'Zirve Banka Fişi';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Satır: Tarih (Sol) - İşlem Türü Rozeti (Sağ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dateFormat.format(t.date),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Satır: Ana Başlık (Cari/Banka/Gider Adı) (Sol) - Tutar ₺ (Sağ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  mainTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (isGiris ? '+ ' : '- ') + _currency.format(amount > 0 ? amount : t.amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isGiris ? const Color(0xFF059669) : const Color(0xFFE11D48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 3. Satır: Açıklama / Dekont Notu
          Text(
            subTitle,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Varsa EFT / Havale Masrafı Rozeti
          if (!t.isGiris && !t.isPos && t.eftFee > 0 && (t.operationType == 'giden-havale' || t.operationType == 'virman' || t.operationType == 'odeme' || t.operationType == 'gider')) ...[
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
        ],
      ),
    );
  }

  String _getBadgeText(BankTransaction t) {
    if (t.isPos || t.operationType == 'pos') return 'POS Tahsilatı';
    final op = t.operationType.toLowerCase();
    if (op == 'virman') return 'Virman';
    if (op == 'gider') return 'Gider';
    if (op == 'gelen-havale' || op == 'tahsilat') return 'Gelen Havale';
    if (op == 'giden-havale' || op == 'gonderilen-havale' || op == 'odeme') return 'Giden Havale';
    return t.isGiris ? 'Gelen Havale' : 'Giden Havale';
  }

  Color _getBadgeBg(BankTransaction t) {
    if (t.isPos || t.operationType == 'pos') return const Color(0xFFD1FAE5);
    final op = t.operationType.toLowerCase();
    if (op == 'virman') return const Color(0xFFDBEAFE);
    if (op == 'gider') return const Color(0xFFFFE4E6);
    if (t.isGiris) return const Color(0xFFD1FAE5);
    return const Color(0xFFFFE4E6);
  }

  Color _getBadgeFg(BankTransaction t) {
    if (t.isPos || t.operationType == 'pos') return const Color(0xFF059669);
    final op = t.operationType.toLowerCase();
    if (op == 'virman') return const Color(0xFF2563EB);
    if (op == 'gider') return const Color(0xFFE11D48);
    if (t.isGiris) return const Color(0xFF059669);
    return const Color(0xFFE11D48);
  }
}
