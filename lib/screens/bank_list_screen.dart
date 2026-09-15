import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../services/api_service.dart';
import 'bank_detail_screen.dart';
import 'email_approvals_screen.dart';

class BankListScreen extends StatefulWidget {
  const BankListScreen({super.key});

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: ' TL', decimalDigits: 2);
  final TextEditingController _searchController = TextEditingController();

  List<BankAccount> _banks = [];
  List<CariSummary> _caris = [];
  bool _isLoading = true;
  bool _showHidden = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getBanks();
      final cList = await _apiService.getAllCaris();
      setState(() {
        _banks = list;
        _caris = cList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHideBank(BankAccount bank) async {
    try {
      if (bank.hidden) {
        await _apiService.unhideBank(bank.bankName);
      } else {
        await _apiService.hideBank(bank.bankName);
      }
      _loadData();
    } catch (_) {}
  }

  void _showPosTahsilatModal() {
    if (_banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıtlı banka bulunamadı.')));
      return;
    }

    final activeBanks = _banks.where((b) => !b.hidden).toList();
    BankAccount selectedBank = activeBanks.isNotEmpty ? activeBanks.first : _banks.first;
    CariSummary? selectedCari;
    TextEditingController? activeCariTextController;
    final amountController = TextEditingController();
    final descController = TextEditingController(text: 'POS KART ÇEKİMİ');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.credit_card_rounded, color: Color(0xFF7C3AED), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'POS Kart Tahsilatı',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.slate400),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Banka Seçimi
                    const Text('POS HESABI / BANKA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<BankAccount>(
                      value: selectedBank,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: (activeBanks.isNotEmpty ? activeBanks : _banks).map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text(b.bankName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedBank = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Cari Arama
                    const Text('ZİRVE CARİ HESABI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    Autocomplete<CariSummary>(
                      displayStringForOption: (c) => c.cariAd,
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<CariSummary>.empty();
                        final q = textEditingValue.text.toLowerCase();
                        return _caris.where((c) => c.cariAd.toLowerCase().contains(q) || c.cariKod.toLowerCase().contains(q));
                      },
                      onSelected: (c) {
                        setModalState(() {
                          selectedCari = c;
                          if (activeCariTextController != null) {
                            activeCariTextController!.text = c.cariAd;
                          }
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        activeCariTextController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Cari unvanı veya kodu yazın...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                            prefixIcon: const Icon(Icons.person_search_rounded, color: Color(0xFF7C3AED), size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                    if (selectedCari != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Seçilen: ${selectedCari!.cariAd} (${selectedCari!.cariKod})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Tutar
                    const Text('ÇEKİM TUTARI (TL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                      decoration: InputDecoration(
                        hintText: '0,00',
                        prefixText: '₺ ',
                        prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Açıklama
                    const Text('AÇIKLAMA / NOT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        hintText: 'POS KART ÇEKİMİ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kaydet Butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final cariNameTyped = activeCariTextController?.text.trim() ?? '';
                                final finalCariName = selectedCari?.cariAd.trim().isNotEmpty == true ? selectedCari!.cariAd : cariNameTyped;
                                if (finalCariName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Lütfen bir cari hesap seçin veya unvan girin.')));
                                  return;
                                }

                                final amt = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
                                if (amt <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Lütfen geçerli bir tutar girin.')));
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                try {
                                  final ok = await _apiService.createPosTahsilat(
                                    bankName: selectedBank.bankName,
                                    cariName: finalCariName,
                                    cariRef: selectedCari?.cariKod,
                                    amount: amt,
                                    description: descController.text,
                                  );
                                  setModalState(() => isSubmitting = false);
                                  if (ok) {
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: AppTheme.primaryEmerald,
                                          content: Text('POS Tahsilatı Zirveye başarıyla işlendi!'),
                                        ),
                                      );
                                      _loadData();
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('POS kaydı başarısız oldu.')));
                                    }
                                  }
                                } catch (err) {
                                  setModalState(() => isSubmitting = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Hata: $err')));
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Zirveye POS Kaydını İşle',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<BankAccount> get _searchFilteredBanks {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _banks;
    return _banks.where((b) => b.bankName.toLowerCase().contains(q)).toList();
  }

  List<BankAccount> get mainBanks => _searchFilteredBanks.where((b) => !b.hidden).toList();
  List<BankAccount> get hiddenBanks => _searchFilteredBanks.where((b) => b.hidden).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    // Üst Başlık & POS Tahsilatı Butonu (Görsel 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Banka Hesapları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.slate900,
                            ),
                          ),
                          const Text(
                            'Tüm banka bakiyeleri ve hareketleri',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.slate400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Aksiyon Butonları: E-Posta Onayları + POS Tahsilatı
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailApprovalsScreen())).then((_) => _loadData());
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4338CA),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 15),
                                        SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            'E-Posta Onayları',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: _showPosTahsilatModal,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.credit_card_rounded, color: Colors.white, size: 15),
                                        SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            'POS Tahsilatı',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

            // Arama Kutusu (Görsel 2: Banka veya cari ara...)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Banka veya cari ara...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Banka Kartları Listesi (Görsel 2 tasarımı)
            if (mainBanks.isEmpty && hiddenBanks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Kayıtlı banka hesabı bulunamadı.', style: TextStyle(color: AppTheme.slate400)),
                ),
              )
            else ...[
              ...mainBanks.map((b) => _buildBankCard(b, isMain: true)),

              if (hiddenBanks.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _showHidden = !_showHidden),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.slate500),
                            const SizedBox(width: 8),
                            Text(
                              'DİĞER BANKALAR (${hiddenBanks.length})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate700),
                            ),
                          ],
                        ),
                        Icon(
                          _showHidden ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.slate500,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showHidden) ...[
                  const SizedBox(height: 8),
                  ...hiddenBanks.map((b) => _buildBankCard(b, isMain: false)),
                ],
              ],
            ],
          ],
                ),
        ),
      ),
    );
  }

  // Görsel 2 ile Birebir Aynı Banka Kartı
  Widget _buildBankCard(BankAccount bank, {required bool isMain}) {
    final isNegative = bank.bakiye < -0.01;
    final isFon = bank.bankName.toLowerCase().contains('fon') || bank.bankName.toLowerCase().contains('yatirim');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF06B6D4), // Görsel 2'deki Turkuaz / Cyan Çerçeve
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BankDetailScreen(bank: bank, allBanks: _banks),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: İkon + Banka Adı + Üç Nokta Menüsü
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFon ? const Color(0xFFE0F2FE) : const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        isFon ? Icons.pie_chart_rounded : Icons.account_balance_rounded,
                        color: isFon ? const Color(0xFF0284C7) : const Color(0xFF0891B2),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank.bankName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.slate900,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bank.branch.isNotEmpty ? bank.branch : 'Aktif Hesap',
                          style: const TextStyle(fontSize: 11, color: AppTheme.slate400, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.more_vert_rounded, size: 16, color: AppTheme.slate500),
                    ),
                    onSelected: (val) {
                      if (val == 'toggle_hide') _toggleHideBank(bank);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle_hide',
                        child: Row(
                          children: [
                            Icon(isMain ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16, color: AppTheme.slate700),
                            const SizedBox(width: 8),
                            Text(isMain ? 'Diğer Bankalara Taşı' : 'Ana Bankalara Taşı', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Alt Satır: BAKİYE (Sol) - Tutar TL (Sağ) (Görsel 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    'BAKİYE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.slate400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _currency.format(bank.bakiye),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isNegative ? const Color(0xFFE11D48) : AppTheme.slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
