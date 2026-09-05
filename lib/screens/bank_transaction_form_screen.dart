import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../services/api_service.dart';

class BankTransactionFormScreen extends StatefulWidget {
  final BankAccount sourceBank;
  final List<BankAccount> allBanks;
  final String initialType;

  const BankTransactionFormScreen({
    super.key,
    required this.sourceBank,
    required this.allBanks,
    this.initialType = 'virman',
  });

  @override
  State<BankTransactionFormScreen> createState() => _BankTransactionFormScreenState();
}

class _BankTransactionFormScreenState extends State<BankTransactionFormScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late String _operationType;
  late BankAccount _sourceBank;
  BankAccount? _targetBank;
  CariSummary? _selectedCari;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _eftFeeController = TextEditingController();

  List<CariSummary> _caris = [];
  List<Map<String, dynamic>> _giders = [];
  Map<String, dynamic>? _selectedGider;
  bool _isLoadingCaris = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _operationType = widget.initialType;
    _sourceBank = widget.sourceBank;
    final otherBanks = widget.allBanks.where((b) => b.bankName != _sourceBank.bankName).toList();
    if (otherBanks.isNotEmpty) _targetBank = otherBanks.first;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingCaris = true);
    try {
      final cariList = await _apiService.getAllCaris();
      final giderList = await _apiService.getGiders();
      setState(() {
        _caris = cariList;
        _giders = giderList;
        _isLoadingCaris = false;
      });
    } catch (e) {
      setState(() => _isLoadingCaris = false);
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen geçerli bir tutar girin.')));
      return;
    }
    final eftFee = double.tryParse(_eftFeeController.text.replaceAll(',', '.')) ?? 0.0;

    setState(() => _isSubmitting = true);
    try {
      final ok = await _apiService.createBankTransaction(
        operationType: _operationType,
        sourceBank: _sourceBank.bankName,
        targetBank: _targetBank?.bankName,
        cariRef: _selectedCari?.cariKod,
        cariName: _selectedCari?.cariAd,
        amount: amount,
        description: _descController.text,
        expenseItem: _selectedGider?['GIDERKOD']?.toString(),
        eftFee: eftFee,
      );
      setState(() => _isSubmitting = false);
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppTheme.primaryEmerald, content: Text('İşlem Zirveye başarıyla kaydedildi!')),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarısız oldu.')));
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final otherBanks = widget.allBanks.where((b) => b.bankName != _sourceBank.bankName).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Banka İşlemi / Zirve Fişi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // İşlem Türü
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _buildTypeTab('Virman', 'virman'),
                _buildTypeTab('Tahsilat', 'gelen_havale'),
                _buildTypeTab('Ödeme', 'giden_havale'),
                _buildTypeTab('Gider', 'gider'),
              ]),
            ),
            const SizedBox(height: 16),

            // Kaynak Banka
            _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('KAYNAK BANKA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const SizedBox(height: 4),
              Text(_sourceBank.bankName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
              Text('Bakiye: ${currency.format(_sourceBank.bakiye)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ])),
            const SizedBox(height: 14),

            // Hedef Banka (sadece virman)
            if (_operationType == 'virman') ...[
              _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('HEDEF BANKA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                const SizedBox(height: 6),
                DropdownButtonFormField<BankAccount>(
                  value: _targetBank,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  items: otherBanks.map((b) => DropdownMenuItem(value: b, child: Text('${b.bankName} (${currency.format(b.bakiye)})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) => setState(() => _targetBank = val),
                ),
              ])),
              const SizedBox(height: 14),
            ],

            // Cari (tahsilat / ödeme)
            if (_operationType == 'gelen_havale' || _operationType == 'giden_havale') ...[
              _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ZİRVE CARİ HESABI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                const SizedBox(height: 6),
                Autocomplete<CariSummary>(
                  displayStringForOption: (c) => c.cariAd,
                  optionsBuilder: (v) {
                    if (v.text.isEmpty) return const Iterable<CariSummary>.empty();
                    return _caris.where((c) => c.cariAd.toLowerCase().contains(v.text.toLowerCase()));
                  },
                  onSelected: (c) => setState(() => _selectedCari = c),
                  fieldViewBuilder: (ctx, ctrl, fn, onSubmit) => TextField(
                    controller: ctrl,
                    focusNode: fn,
                    decoration: InputDecoration(
                      hintText: 'Cari unvanı yazın...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                      prefixIcon: const Icon(Icons.person_search_rounded, color: AppTheme.primaryBlue, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_selectedCari != null) ...[
                  const SizedBox(height: 6),
                  Text('Seçilen: ${_selectedCari!.cariAd} (${_selectedCari!.cariKod})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                ],
              ])),
              const SizedBox(height: 14),
            ],

            // Tutar
            _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('İŞLEM TUTARI (₺)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                decoration: InputDecoration(
                  hintText: '0,00',
                  prefixText: '₺ ',
                  prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => (val == null || val.isEmpty) ? 'Lütfen tutar girin' : null,
              ),
            ])),
            const SizedBox(height: 14),

            // Gider Kalemi (sadece gider)
            if (_operationType == 'gider') ...[
              _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('GİDER KALEMİ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                const SizedBox(height: 6),
                _isLoadingCaris
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedGider,
                        isExpanded: true,
                        hint: const Text('Gider kalemi seçin...', style: TextStyle(fontSize: 12)),
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                        items: _giders.map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('${g['GIDERKOD']} - ${g['GIDERADI']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedGider = val),
                      ),
              ])),
              const SizedBox(height: 14),
            ],

            // EFT/Havale Masrafı (virman ve ödeme)
            if (_operationType == 'virman' || _operationType == 'giden_havale') ...[
              _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('EFT / HAVALE MASRAFI (Varsa)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _eftFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0,00',
                    prefixText: '₺ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ])),
              const SizedBox(height: 14),
            ],

            // Açıklama
            _buildCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AÇIKLAMA / DEKONT NOTU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  hintText: 'Örn: Demir bedeli virmanı / Tahsilat...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ])),
            const SizedBox(height: 24),

            // Kaydet
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Zirveye Kaydet & Onayla',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: child,
    );
  }

  Widget _buildTypeTab(String label, String key) {
    final isSelected = _operationType == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _operationType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.slate600,
                )),
          ),
        ),
      ),
    );
  }
}
