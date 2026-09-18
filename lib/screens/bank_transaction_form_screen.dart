import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../services/api_service.dart';

class BankTransactionFormScreen extends StatefulWidget {
  final BankAccount sourceBank;
  final List<BankAccount> allBanks;
  final String initialType; // 'virman', 'gelen_havale', 'giden_havale', 'gider'

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
  final TextEditingController _cariSearchController = TextEditingController();
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
    if (otherBanks.isNotEmpty) {
      _targetBank = otherBanks.first;
    }
    _loadCarisAndGiders();
  }

  Future<void> _loadCarisAndGiders() async {
    setState(() => _isLoadingCaris = true);
    try {
      final list = await _apiService.getAllCaris();
      final gList = await _apiService.getGiders();
      setState(() {
        _caris = list;
        _giders = gList;
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
      final warning = await _apiService.createBankTransaction(
        operationType: _operationType,
        sourceBank: _sourceBank.bankName,
        targetBank: _targetBank?.bankName,
        cariRef: _selectedCari?.cariKod,
        cariName: _selectedCari?.cariAd,
        amount: amount,
        description: _descController.text,
        expenseItem: _selectedGider?['GIDERADI']?.toString() ?? _selectedGider?['GIDERKOD']?.toString(),
        eftFee: eftFee,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;
      if (warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.primaryAmber, content: Text('Kayıt Zirve\'ye işlendi ama: $warning')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppTheme.primaryEmerald, content: Text('İşlem Zirve veritabanına başarıyla kaydedildi!')),
        );
      }
      Navigator.pop(context, true);
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
        title: const Text('Banka İşlemi / Zirve Fişi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // İşlem Türü Seçici
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _buildTypeTab('Virman', 'virman'),
                  _buildTypeTab('Tahsilat', 'gelen_havale'),
                  _buildTypeTab('Ödeme', 'giden_havale'),
                  _buildTypeTab('Gider', 'gider'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kaynak Banka Kartı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('KAYNAK BANKA (HESAP)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                  const SizedBox(height: 4),
                  Text(_sourceBank.bankName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                  Text('Mevcut Bakiye: ' + currency.format(_sourceBank.bakiye), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Virman ise Hedef Banka Seçimi
            if (_operationType == 'virman') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HEDEF BANKA (PARANIN GEÇECEĞİ HESAP)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<BankAccount>(
                      value: _targetBank,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: otherBanks.map((b) {
                        return DropdownMenuItem(value: b, child: Text('${b.bankName} (' + currency.format(b.bakiye) + ')', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                      }).toList(),
                      onChanged: (val) => setState(() => _targetBank = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Havale / Tahsilat ise Zirve Cari Arama
            if (_operationType == 'gelen_havale' || _operationType == 'giden_havale') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ZİRVE CARİ HESABI SEÇİN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    Autocomplete<CariSummary>(
                      displayStringForOption: (c) => c.cariAd,
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<CariSummary>.empty();
                        return _caris.where((c) => c.cariAd.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (c) => setState(() => _selectedCari = c),
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Cari unvanı yazın...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                            prefixIcon: const Icon(Icons.person_search_rounded, color: AppTheme.primaryBlue, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                    if (_selectedCari != null) ...[
                      const SizedBox(height: 6),
                      Text('Seçilen: ${_selectedCari!.cariAd} (${_selectedCari!.cariKod})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Tutar Girişi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Lütfen tutar girin';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Gider ise Gider Kalemi
            if (_operationType == 'gider') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GİDER KALEMİ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedGider,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: _giders.map((g) {
                        return DropdownMenuItem(value: g, child: Text('${g['GIDERKOD']} - ${g['GIDERADI']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGider = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Virman veya Giden Havale ise EFT Ücreti
            if (_operationType == 'virman' || _operationType == 'giden_havale') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EFT/HAVALE MASRAFI (Varsa)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
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
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Açıklama
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kaydet Butonu
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
                          Text('Zirveye Kaydet & Onayla', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.slate600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
