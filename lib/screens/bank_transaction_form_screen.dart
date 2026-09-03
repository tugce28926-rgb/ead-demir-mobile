import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

enum TransactionFormType { gelenHavale, gidenHavale, virman, giderFisi, fonAlSat }

class BankTransactionFormScreen extends StatefulWidget {
  final String sourceBankName;
  final TransactionFormType formType;

  const BankTransactionFormScreen({
    super.key,
    required this.sourceBankName,
    required this.formType,
  });

  @override
  State<BankTransactionFormScreen> createState() => _BankTransactionFormScreenState();
}

class _BankTransactionFormScreenState extends State<BankTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _cariSearchController = TextEditingController();

  String? _selectedCari;
  String? _targetBankName;
  String? _selectedGiderType = 'POS Komisyonu';
  String? _selectedFon = 'KLU - Kuveyt Türk Kısa Vadeli Kira Sertifikası';
  String _fonIslemTuru = 'ALIS'; // 'ALIS' or 'SATIS'
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  final List<String> _giderTypes = [
    'POS Komisyonu',
    'Hesap İşletim / Kart Aidatı',
    'EFT / Havale Masrafı',
    'Banka Faiz / Komisyon Gideri',
    'Vergi / Harç Kesintisi',
    'Diğer Banka Masrafı',
  ];

  final List<String> _availableBanks = [
    'ZİRAAT BANKASI 5001',
    'GARANTİ BANKASI-6294859',
    'KUVEYT TÜRK',
    'KUVEYT TÜRK YATIRIM',
    'KUVEYT TÜRK FON HESABI',
    'İŞ BANKASI',
    'İŞ BANKASI KREDİ KARTI',
    'VAKIFKATILIM',
    'FİNANS BANK',
    'EMLAK KATILIM BANKASI',
  ];

  final List<String> _fonList = [
    'KLU - Kuveyt Türk Kısa Vadeli Kira Sertifikası',
    'KTV - Kuveyt Türk Katılım Fonu',
    'KSV - Kuveyt Türk Serbest Fon',
  ];

  @override
  void initState() {
    super.initState();
    _targetBankName = _availableBanks.firstWhere((b) => b != widget.sourceBankName, orElse: () => _availableBanks.first);
  }

  String get _title {
    switch (widget.formType) {
      case TransactionFormType.gelenHavale:
        return 'Gelen Havale Girişi';
      case TransactionFormType.gidenHavale:
        return 'Gönderilen Havale Girişi';
      case TransactionFormType.virman:
        return 'Banka Virman İşlemi';
      case TransactionFormType.giderFisi:
        return 'Banka Gider Fişi';
      case TransactionFormType.fonAlSat:
        return 'Fon Alış / Satış İşlemi';
    }
  }

  Color get _themeColor {
    switch (widget.formType) {
      case TransactionFormType.gelenHavale:
        return AppTheme.primaryEmerald;
      case TransactionFormType.gidenHavale:
        return AppTheme.primaryRose;
      case TransactionFormType.virman:
        return AppTheme.primaryPurple;
      case TransactionFormType.giderFisi:
        return AppTheme.primaryAmber;
      case TransactionFormType.fonAlSat:
        return AppTheme.primaryBlue;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tutar giriniz.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate API submission
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: _themeColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: _themeColor, size: 32),
              ),
              const SizedBox(height: 14),
              const Text('İşlem Başarılı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                '${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(amount)} tutarındaki işlem Zirve SQL hesabına başarıyla kaydedildi.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bank Info Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Icon(Icons.account_balance_rounded, color: _themeColor, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KAYNAK BANKA HESABI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                        Text(widget.sourceBankName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Virman Hedef Banka Seçici
            if (widget.formType == TransactionFormType.virman) ...[
              _buildSectionTitle('HEDEF BANKA HESABI'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _targetBankName,
                    isExpanded: true,
                    items: _availableBanks
                        .where((b) => b != widget.sourceBankName)
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (val) => setState(() => _targetBankName = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cari Arama / Seçimi (Havale İşlemleri İçin)
            if (widget.formType == TransactionFormType.gelenHavale || widget.formType == TransactionFormType.gidenHavale) ...[
              _buildSectionTitle(widget.formType == TransactionFormType.gelenHavale ? 'MÜŞTERİ / CARİ SEÇİMİ' : 'TEDARİKÇİ / CARİ SEÇİMİ'),
              TextFormField(
                controller: _cariSearchController,
                decoration: InputDecoration(
                  hintText: 'Cari unvanı veya vergi no yazınız...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Lütfen cari unvanını giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Gider Fişi Tür Seçimi
            if (widget.formType == TransactionFormType.giderFisi) ...[
              _buildSectionTitle('MASRAF / GİDER TÜRÜ'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGiderType,
                    isExpanded: true,
                    items: _giderTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedGiderType = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Fon Al / Sat Seçenekleri
            if (widget.formType == TransactionFormType.fonAlSat) ...[
              _buildSectionTitle('FON İŞLEM YÖNÜ'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _fonIslemTuru = 'ALIS'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _fonIslemTuru == 'ALIS' ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _fonIslemTuru == 'ALIS' ? AppTheme.primaryBlue : AppTheme.slate200, width: 2),
                        ),
                        child: Center(
                          child: Text('🟢 FON ALIŞ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _fonIslemTuru == 'ALIS' ? AppTheme.primaryBlue : AppTheme.slate600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _fonIslemTuru = 'SATIS'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _fonIslemTuru == 'SATIS' ? const Color(0xFFFFF1F2) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _fonIslemTuru == 'SATIS' ? AppTheme.primaryRose : AppTheme.slate200, width: 2),
                        ),
                        child: Center(
                          child: Text('🔴 FON SATIŞ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _fonIslemTuru == 'SATIS' ? AppTheme.primaryRose : AppTheme.slate600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('YATIRIM FONU'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFon,
                    isExpanded: true,
                    items: _fonList
                        .map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedFon = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // İşlem Tutarı
            _buildSectionTitle('İŞLEM TUTARI (₺)'),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slate900),
              decoration: InputDecoration(
                prefixText: '₺ ',
                prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _themeColor),
                hintText: '0,00',
                hintStyle: const TextStyle(fontSize: 18, color: AppTheme.slate300),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Lütfen tutar giriniz';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Açıklama
            _buildSectionTitle('AÇIKLAMA (OPSİYONEL)'),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Zirve fiş açıklaması yazabilirsiniz...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
              ),
            ),
            const SizedBox(height: 24),

            // Onayla ve Zirve'ye Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text('Zirve\'ye Kaydet', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500, letterSpacing: 0.5),
      ),
    );
  }
}
