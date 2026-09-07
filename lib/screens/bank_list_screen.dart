import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../services/api_service.dart';
import 'bank_detail_screen.dart';

class BankListScreen extends StatefulWidget {
  const BankListScreen({super.key});

  @override
  State<BankListScreen> createState() => _BankListScreenState();
}

class _BankListScreenState extends State<BankListScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  List<BankAccount> _banks = [];
  List<CariSummary> _caris = [];
  bool _isLoading = true;
  bool _showHidden = false;

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
                    // Üst Başlık & POS Tahsilatı Butonu
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Banka Hesapları',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.slate900,
                                ),
                              ),
                              Text(
                                'Tüm banka bakiyeleri ve hareketleri',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.slate400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Mor POS Tahsilatı Butonu
                          InkWell(
                            onTap: _showPosTahsilatModal,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.credit_card_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'POS Tahsilatı',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gizlenenleri Göster / Gizle Toggle Butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _showHidden = !_showHidden),
                          icon: Icon(
                            _showHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 16,
                            color: AppTheme.slate600,
                          ),
                          label: Text(
                            _showHidden ? 'Gizlenenleri Gizle' : 'Gizlenen Bankaları Göster',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate600),
                          ),
                        ),
                      ],
                    ),

                    // Banka Kartları Listesi
                    ..._banks.where((b) => _showHidden ? true : !b.hidden).map((bank) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildBankCard(bank),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBankCard(BankAccount bank) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bank.hidden ? AppTheme.slate200 : AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              bank.bankName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: bank.hidden ? AppTheme.slate400 : AppTheme.slate900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bank.hidden) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.slate200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Gizli', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.slate600)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bank.iban.isNotEmpty ? bank.iban : (bank.branch.isNotEmpty ? bank.branch : bank.accountType),
                        style: const TextStyle(fontSize: 11, color: AppTheme.slate400, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currency.format(bank.bakiye),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: bank.bakiye >= 0 ? AppTheme.primaryEmerald : AppTheme.primaryRose,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bank.bakiye >= 0 ? 'Net Bakiye' : 'Borç Bakiye',
                      style: const TextStyle(fontSize: 10, color: AppTheme.slate400, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _toggleHideBank(bank),
                  icon: Icon(
                    bank.hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 18,
                    color: AppTheme.slate400,
                  ),
                  tooltip: bank.hidden ? 'Bankayı Göster' : 'Bankayı Gizle',
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BankDetailScreen(
                          bank: bank,
                          allBanks: _banks,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: AppTheme.slate700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('Hareketleri Gör', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
