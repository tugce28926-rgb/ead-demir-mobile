import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../models/pending_email_model.dart';
import '../services/api_service.dart';

class EmailApprovalsScreen extends StatefulWidget {
  const EmailApprovalsScreen({super.key});

  @override
  State<EmailApprovalsScreen> createState() => _EmailApprovalsScreenState();
}

class _EmailApprovalsScreenState extends State<EmailApprovalsScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  bool _isLoading = true;
  bool _isFetching = false;
  bool _isApproving = false;

  List<PendingEmail> _pending = [];
  List<ApprovedEmail> _approved = [];
  List<String> _cariOptions = [];
  List<String> _bankOptions = [];

  final Map<String, bool> _selected = {};
  final Map<String, String> _selectedBank = {};
  final Map<String, String> _selectedCari = {};
  final Map<String, TextEditingController> _eftControllers = {};
  // Kullanıcı bir kayıt için elle banka/cari seçtiyse id'si buraya eklenir —
  // sadece bunlar için mevcut seçim korunur, geri kalanı her yenilemede
  // sunucunun en güncel önerisiyle üzerine yazılır (aksi halde ilk görülen
  // öneri kalıcı olarak "kilitleniyordu", backend düzelse bile ekran hiç
  // güncellenmiyordu).
  final Set<String> _manualBankIds = {};
  final Set<String> _manualCariIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _eftControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getPendingEmails();
      final pending = data['pending'] as List<PendingEmail>;
      final approved = data['approved'] as List<ApprovedEmail>;
      final cariOptions = data['cariOptions'] as List<String>;
      final bankOptions = data['bankOptions'] as List<String>;

      // Önceki formdaki kullanıcı seçimlerini kaybetmemek için sadece hâlâ
      // bekleyen kayıtları koru, yenilerini öneriyle doldur.
      final stillPendingIds = pending.map((p) => p.id).toSet();
      _selected.removeWhere((id, _) => !stillPendingIds.contains(id));
      _selectedBank.removeWhere((id, _) => !stillPendingIds.contains(id));
      _selectedCari.removeWhere((id, _) => !stillPendingIds.contains(id));
      _manualBankIds.removeWhere((id) => !stillPendingIds.contains(id));
      _manualCariIds.removeWhere((id) => !stillPendingIds.contains(id));
      _eftControllers.removeWhere((id, c) {
        final drop = !stillPendingIds.contains(id);
        if (drop) c.dispose();
        return drop;
      });

      for (final p in pending) {
        _selected.putIfAbsent(p.id, () => true);
        // Sunucu bir banka önerisi bulamazsa alfabetik ilk bankayı seçili göstermek
        // yanlış bankaya kayıt atılmasına yol açabilir — öneri yoksa alan boş kalıp
        // kullanıcının elle seçmesi bekleniyor (cari alanında zaten böyle çalışıyordu).
        // Kullanıcı elle seçim yapmadıysa her yenilemede en güncel öneriyle
        // üzerine yazılır (aksi halde eski/yanlış bir öneri kalıcı kilitlenirdi).
        if (!_manualBankIds.contains(p.id)) {
          _selectedBank[p.id] = p.suggestedBank;
        }
        if (!_manualCariIds.contains(p.id)) {
          _selectedCari[p.id] = p.suggestedCari;
        }
        _eftControllers.putIfAbsent(p.id, () => TextEditingController(text: p.embeddedMasraf > 0 ? _currency.format(p.embeddedMasraf).trim() : ''));
      }

      setState(() {
        _pending = pending;
        _approved = approved;
        _cariOptions = cariOptions;
        _bankOptions = bankOptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Yüklenemedi: $e')));
      }
    }
  }

  Future<void> _fetchNewMails() async {
    setState(() => _isFetching = true);
    try {
      final count = await _apiService.fetchNewEmails();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.primaryEmerald, content: Text(count > 0 ? '$count yeni e-posta bulundu.' : 'Yeni e-posta bulunamadı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _deleteEmail(PendingEmail p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('E-postayı Sil'),
        content: const Text('Bu e-postayı onay havuzundan silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: AppTheme.primaryRose))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _apiService.deleteEmails([p.id]);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Silinemedi: $e')));
      }
    }
  }

  Future<void> _pickFromList({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String> onPicked,
  }) async {
    final searchController = TextEditingController();
    List<String> filtered = options;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppTheme.slate400)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      onChanged: (val) {
                        final q = val.trim().toLowerCase();
                        setModalState(() {
                          filtered = q.isEmpty ? options : options.where((o) => o.toLowerCase().contains(q)).toList();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final opt = filtered[i];
                        final isSel = opt == current;
                        return ListTile(
                          title: Text(opt, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.w900 : FontWeight.w500, color: isSel ? AppTheme.primaryBlue : AppTheme.slate800)),
                          trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 18) : null,
                          onTap: () {
                            onPicked(opt);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasMissingCari {
    for (final p in _pending) {
      if (_selected[p.id] != true) continue;
      final cari = _selectedCari[p.id] ?? '';
      if (cari.trim().isEmpty) return true;
    }
    return false;
  }

  bool get _hasMissingBank {
    for (final p in _pending) {
      if (_selected[p.id] != true) continue;
      final bank = _selectedBank[p.id] ?? '';
      if (bank.trim().isEmpty) return true;
    }
    return false;
  }

  int get _selectedCount => _pending.where((p) => _selected[p.id] == true).length;

  Future<void> _approveSelected() async {
    final selectedIds = _pending.where((p) => _selected[p.id] == true).map((p) => p.id).toList();
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen Zirve\'ye işlemek için en az bir e-posta seçin.')));
      return;
    }
    if (_hasMissingBank) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Lütfen seçili işlemler için banka seçimini yapın.')));
      return;
    }
    if (_hasMissingCari) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Lütfen seçili işlemler için Zirve Cari eşleştirmesini yapın.')));
      return;
    }

    setState(() => _isApproving = true);
    try {
      final items = <String, Map<String, String>>{};
      for (final id in selectedIds) {
        items[id] = {
          'bankName': _selectedBank[id] ?? '',
          'cariName': _selectedCari[id] ?? '',
          'eftFee': _eftControllers[id]?.text ?? '',
        };
      }
      final warning = await _apiService.approveEmails(selectedIds, items);
      if (mounted) {
        if (warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppTheme.primaryAmber, content: Text('${selectedIds.length} işlem Zirve\'ye işlendi ama: $warning')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppTheme.primaryEmerald, content: Text('${selectedIds.length} işlem Zirve\'ye işlendi.')),
          );
        }
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('E-Posta Onay Havuzu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isFetching ? null : _fetchNewMails,
            icon: _isFetching
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue))
                : const Icon(Icons.refresh_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Yeni Mailleri Çek',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                children: [
                  _buildPendingSectionHeader(),
                  const SizedBox(height: 10),
                  if (_pending.isEmpty)
                    _buildEmptyPending()
                  else ...[
                    _buildSelectAllBar(),
                    const SizedBox(height: 10),
                    ..._pending.map(_buildPendingCard),
                  ],
                  const SizedBox(height: 28),
                  _buildApprovedSectionHeader(),
                  const SizedBox(height: 10),
                  if (_approved.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.slate200)),
                      child: const Center(child: Text('İşlenmiş e-posta kaydı bulunmuyor.', style: TextStyle(color: AppTheme.slate400, fontSize: 11))),
                    )
                  else
                    ..._approved.map(_buildApprovedCard),
                ],
              ),
            ),
      bottomNavigationBar: (_pending.isEmpty || _isLoading)
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.slate200)),
                ),
                child: Row(
                  children: [
                    Text('$_selectedCount işlem seçili', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isApproving ? null : _approveSelected,
                      icon: _isApproving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                      label: const Text('Zirve\'ye İşle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPendingSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Onay Bekleyen İşlemler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(20)),
          child: Text('${_pending.length} Bekleyen', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4338CA))),
        ),
      ],
    );
  }

  Widget _buildApprovedSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Zirve\'ye İşlenmiş İşlemler', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
          child: Text('${_approved.length} İşlenmiş', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
        ),
      ],
    );
  }

  Widget _buildEmptyPending() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.slate200)),
      child: const Column(
        children: [
          Icon(Icons.mark_email_read_outlined, size: 40, color: AppTheme.slate300),
          SizedBox(height: 10),
          Text('Onay bekleyen e-posta yok.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          SizedBox(height: 4),
          Text('Yenile butonuna basarak gelen kutusunu tarayabilirsiniz.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppTheme.slate400)),
        ],
      ),
    );
  }

  Widget _buildSelectAllBar() {
    final allSelected = _pending.isNotEmpty && _pending.every((p) => _selected[p.id] == true);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                for (final p in _pending) {
                  _selected[p.id] = !allSelected;
                }
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: allSelected,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      for (final p in _pending) {
                        _selected[p.id] = val ?? false;
                      }
                    });
                  },
                ),
                const Text('Tümünü Seç', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
              ],
            ),
          ),
          Text('$_selectedCount işlem seçili', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
        ],
      ),
    );
  }

  Widget _buildPendingCard(PendingEmail p) {
    final isSel = _selected[p.id] == true;
    final bank = _selectedBank[p.id] ?? '';
    final cari = _selectedCari[p.id] ?? '';
    final showEft = p.operationType == 'giden-havale' || p.operationType == 'virman';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSel ? AppTheme.primaryBlue.withOpacity(0.4) : AppTheme.slate200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSel,
                activeColor: AppTheme.primaryBlue,
                onChanged: (val) => setState(() => _selected[p.id] = val ?? false),
              ),
              _buildTypeBadge(p.operationType),
              const SizedBox(width: 8),
              Text(_dateFormat.format(p.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const Spacer(),
              Text('${_currency.format(p.amount)} TL', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _deleteEmail(p),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.delete_outline_rounded, size: 19, color: AppTheme.slate400),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OKUNAN İSİM / AÇIKLAMA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(p.senderName.isNotEmpty ? p.senderName : 'Bilinmiyor', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate800)),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(p.description, style: const TextStyle(fontSize: 11, color: AppTheme.slate500)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildFieldPicker(
            label: 'Banka Seçimi',
            value: bank.isNotEmpty ? bank : 'Seçiniz...',
            highlight: bank.isEmpty,
            onTap: () => _pickFromList(
              title: 'Banka Seçin',
              options: _bankOptions,
              current: bank,
              onPicked: (v) => setState(() {
                _selectedBank[p.id] = v;
                _manualBankIds.add(p.id);
              }),
            ),
          ),
          const SizedBox(height: 8),
          _buildFieldPicker(
            label: p.isVirman ? 'Karşı Banka Eşleştirme' : 'Zirve Cari Eşleştirme',
            value: cari.isNotEmpty ? cari : 'Seçiniz...',
            highlight: cari.isEmpty,
            onTap: () => _pickFromList(
              title: p.isVirman ? 'Karşı Banka Seçin' : 'Cari Seçin',
              options: p.isVirman ? _bankOptions : _cariOptions,
              current: cari,
              onPicked: (v) => setState(() {
                _selectedCari[p.id] = v;
                _manualCariIds.add(p.id);
              }),
            ),
          ),
          if (showEft) ...[
            const SizedBox(height: 8),
            Text('EFT Masrafı (TL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
            const SizedBox(height: 4),
            TextField(
              controller: _eftControllers[p.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0,00',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldPicker({required String label, required String value, required VoidCallback onTap, bool highlight = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: highlight ? AppTheme.primaryRose.withOpacity(0.5) : AppTheme.slate200),
          color: AppTheme.slate50,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.slate400, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlight ? AppTheme.primaryRose : AppTheme.slate800), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.slate400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String operationType) {
    late Color bg, fg;
    late String text;
    late IconData icon;
    if (operationType == 'virman') {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF7C3AED);
      text = 'Virman';
      icon = Icons.swap_horiz_rounded;
    } else if (operationType == 'gelen-havale') {
      bg = const Color(0xFFD1FAE5);
      fg = AppTheme.primaryEmerald;
      text = 'Gelen Havale';
      icon = Icons.arrow_downward_rounded;
    } else {
      bg = const Color(0xFFFFE4E6);
      fg = AppTheme.primaryRose;
      text = 'Giden Havale';
      icon = Icons.arrow_upward_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: fg)),
        ],
      ),
    );
  }

  Widget _buildApprovedCard(ApprovedEmail a) {
    final isGelir = a.operationType == 'gelen-havale';
    final isVirman = a.operationType == 'virman';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeBadge(a.operationType),
              const SizedBox(width: 8),
              Text(_dateFormat.format(a.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slate400)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFA7F3D0))),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 11, color: Color(0xFF047857)),
                    SizedBox(width: 3),
                    Text('Zirve\'de Kayıtlı', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.senderName.isNotEmpty ? a.senderName : 'Bilinmiyor', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate800)),
                    const SizedBox(height: 2),
                    Text(
                      a.bankName + (isVirman && (a.targetBankName ?? '').isNotEmpty ? ' → ${a.targetBankName}' : ''),
                      style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
                    ),
                    if (a.description.isNotEmpty)
                      Text(a.description, style: const TextStyle(fontSize: 10, color: AppTheme.slate400), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isGelir ? '+ ' : (isVirman ? '' : '- ')}${_currency.format(a.amount)} TL',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isGelir ? AppTheme.primaryEmerald : (isVirman ? AppTheme.primaryPurple : AppTheme.primaryRose)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
