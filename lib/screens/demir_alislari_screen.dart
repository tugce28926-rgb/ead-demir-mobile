import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/siparis_model.dart';
import '../services/api_service.dart';

class DemirAlislariScreen extends StatefulWidget {
  const DemirAlislariScreen({super.key});

  @override
  State<DemirAlislariScreen> createState() => _DemirAlislariScreenState();
}

class _DemirAlislariScreenState extends State<DemirAlislariScreen> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');

  List<Siparis> _siparisler = [];
  bool _isLoading = true;
  String? _error;

  // Masaüstündeki "Bekleyen Siparişler / Depoya Gelenler" sekme ayrımı: sabit
  // bir alan değil, siparişe bağlı depo girişi toplamına göre hesaplanıyor
  // (Siparis.depoyaGeldi -> gelenKg > 0). "Fatura Gelenleri Göster" filtresi
  // sadece "Depoya Gelenler" sekmesinde anlamlı, masaüstüyle aynı mantık.
  String _activeTab = 'beklemede';
  bool _faturaGoster = false;

  List<Siparis> get _gorunurListe {
    final depoda = _activeTab == 'depoda';
    final temel = _siparisler.where((s) => depoda ? s.depoyaGeldi : !s.depoyaGeldi);
    if (!depoda) return temel.toList();
    return temel.where((s) => _faturaGoster ? s.faturaGeldi : !s.faturaGeldi).toList();
  }

  // "Ödemesi Gelenler": ödeme tarihi bugüne kadar (bugün dahil) gelmiş ama hâlâ
  // ödenmemiş siparişler — masaüstündeki "Günlük Ödemeler" ekranının salt
  // okunur, tarihe bağlı görünümüyle aynı mantık. En yakın/geciken en üstte.
  List<Siparis> get _odemesiGelenSiparisler {
    final bugun = DateTime.now();
    final bugunStr = '${bugun.year.toString().padLeft(4, '0')}-${bugun.month.toString().padLeft(2, '0')}-${bugun.day.toString().padLeft(2, '0')}';
    final liste = _siparisler.where((s) => !s.odendi && s.odemeTarihi.isNotEmpty && s.odemeTarihi.compareTo(bugunStr) <= 0).toList();
    liste.sort((a, b) => a.odemeTarihi.compareTo(b.odemeTarihi));
    return liste;
  }

  // "Nakliye Ödemeleri": depoya gelmiş ama nakliyesi ne fiyata dahil edilmiş
  // ne de ayrıca ödenmiş siparişler — masaüstündeki "Ödenmeyen Nakliyeler" modu.
  List<Siparis> get _nakliyeOdemesiGelenSiparisler {
    return _siparisler.where((s) => s.depoyaGeldi && !s.nakliyeDahil && !s.nakliyeOdendi).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _apiService.getDemirAlislari();
      if (mounted) setState(() { _siparisler = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Siparişler yüklenemedi: $e'; _isLoading = false; });
    }
  }

  static DateTime? _parseTarih(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }

  static String _fmtTarih(String raw) {
    final d = _parseTarih(raw);
    return d == null ? raw : DateFormat('dd.MM.yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Demir Alışları', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showYeniSiparisForm,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni Sipariş', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppTheme.primaryBlue,
                    child: _error != null
                        ? ListView(
                            padding: const EdgeInsets.all(14),
                            children: [_buildErrorState(_error!)],
                          )
                        : _activeTab == 'odeme'
                            ? _buildOdemeGelenlerListesi()
                            : _gorunurListe.isEmpty
                                ? ListView(
                                    padding: const EdgeInsets.all(14),
                                    children: [_buildEmptyState(_activeTab == 'beklemede' ? 'Bekleyen sipariş yok.' : 'Depoya gelen sipariş yok.')],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                                    itemCount: _gorunurListe.length,
                                    itemBuilder: (context, index) => _activeTab == 'beklemede'
                                        ? _buildBekleyenCard(_gorunurListe[index])
                                        : _buildDepodaCard(_gorunurListe[index]),
                                  ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTab('Bekleyen', 'beklemede')),
              const SizedBox(width: 6),
              Expanded(child: _buildTab('Depoya Gelenler', 'depoda')),
              const SizedBox(width: 6),
              Expanded(child: _buildTab('Ödemeler', 'odeme')),
            ],
          ),
          if (_activeTab == 'depoda') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _faturaGoster,
                  onChanged: (v) => setState(() => _faturaGoster = v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _faturaGoster = !_faturaGoster),
                  child: const Text('Fatura Gelenleri Göster', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String label, String key) {
    final selected = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : AppTheme.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppTheme.slate600),
        ),
      ),
    );
  }

  Widget _buildBekleyenCard(Siparis s) {
    return InkWell(
      onTap: () => _showSiparisDetail(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.tedarikciAd,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _currency.format(s.toplamTutar),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_kgFormat.format(s.miktarKg)} KG • ${_currency.format(s.alimFiyati)}/Ton • ${_fmtTarih(s.siparisTarihi)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (s.plakaAtanmis)
                  _buildBadge('${s.plaka} • ${s.isimSoyisim ?? ''}', const Color(0xFFECFDF5), AppTheme.primaryEmerald)
                else
                  _buildBadge('PLAKA ATANMADI', const Color(0xFFFFFBEB), AppTheme.primaryAmber),
                const SizedBox(width: 6),
                if (s.odendi)
                  _buildBadge('ÖDENDİ', const Color(0xFFEFF6FF), AppTheme.primaryBlue)
                else
                  _buildBadge('BEKLİYOR', AppTheme.slate100, AppTheme.slate500),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // "Depoya Gelenler" sekmesi: masaüstündeki gibi sipariş anındaki miktar/tutar
  // yerine, o siparişe bağlı depo girişlerinden gelen KG/ödenecek tutar/geliş
  // tarihi/plaka bilgisi gösteriliyor (bunlar depo_girisleri'nden hesaplanıyor).
  Widget _buildDepodaCard(Siparis s) {
    return InkWell(
      onTap: () => _showSiparisDetail(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.tedarikciAd,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _currency.format(s.odenecekTutar),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_kgFormat.format(s.gelenKg)} KG geldi'
              '${s.gelisTarihleri.isNotEmpty ? ' • Geliş: ${s.gelisTarihleri.map(_fmtTarih).join(', ')}' : ''}',
              style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (s.faturaGeldi)
                  _buildBadge('FATURA GELDİ', const Color(0xFFF0FDF4), AppTheme.primaryEmerald)
                else
                  _buildBadge('FATURA BEKLİYOR', const Color(0xFFFFFBEB), AppTheme.primaryAmber),
                const SizedBox(width: 6),
                if (s.plakalar.isNotEmpty)
                  Expanded(child: _buildBadge(s.plakalar.join(', '), AppTheme.slate100, AppTheme.slate600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // "Ödemeler" sekmesi: masaüstündeki "Günlük Ödemeler" ekranının salt okunur
  // görünümü — iki ayrı liste: vadesi gelmiş sipariş ödemeleri ve depoya gelmiş
  // ama nakliyesi hâlâ ödenmemiş siparişler. Ödeme yapma/işaretleme YOK, sadece görüntüleme.
  Widget _buildOdemeGelenlerListesi() {
    final siparisOdemeleri = _odemesiGelenSiparisler;
    final nakliyeOdemeleri = _nakliyeOdemesiGelenSiparisler;
    if (siparisOdemeleri.isEmpty && nakliyeOdemeleri.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(14),
        children: [_buildEmptyState('Ödemesi gelen sipariş veya nakliye yok.')],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        if (siparisOdemeleri.isNotEmpty) ...[
          const Text('SİPARİŞ ÖDEMELERİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
          const SizedBox(height: 8),
          ...siparisOdemeleri.map(_buildSiparisOdemesiCard),
          const SizedBox(height: 10),
        ],
        if (nakliyeOdemeleri.isNotEmpty) ...[
          const Text('NAKLİYE ÖDEMELERİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
          const SizedBox(height: 8),
          ...nakliyeOdemeleri.map(_buildNakliyeOdemesiCard),
        ],
      ],
    );
  }

  Widget _buildSiparisOdemesiCard(Siparis s) {
    final bugun = DateTime.now();
    final odemeTarihi = _parseTarih(s.odemeTarihi);
    final gecikmeGunu = odemeTarihi == null ? 0 : DateTime(bugun.year, bugun.month, bugun.day).difference(DateTime(odemeTarihi.year, odemeTarihi.month, odemeTarihi.day)).inDays;
    return InkWell(
      onTap: () => _showSiparisDetail(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.slate200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(s.tedarikciAd, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(_currency.format(s.toplamTutar), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Ödeme Tarihi: ${_fmtTarih(s.odemeTarihi)}', style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
                const SizedBox(width: 8),
                if (gecikmeGunu > 0)
                  _buildBadge('$gecikmeGunu GÜN GECİKTİ', const Color(0xFFFFF1F2), AppTheme.primaryRose)
                else
                  _buildBadge('BUGÜN', const Color(0xFFFFFBEB), AppTheme.primaryAmber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNakliyeOdemesiCard(Siparis s) {
    return InkWell(
      onTap: () => _showSiparisDetail(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.slate200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(s.tedarikciAd, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.slate900), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                _buildBadge('NAKLİYE', const Color(0xFFFAF5FF), AppTheme.primaryPurple),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_kgFormat.format(s.gelenKg)} KG geldi${s.plakalar.isNotEmpty ? ' • ${s.plakalar.join(', ')}' : ''}',
              style: const TextStyle(fontSize: 10, color: AppTheme.slate400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: textCol.withOpacity(0.3))),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: textCol), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.slate200)),
      child: Center(child: Text(msg, style: const TextStyle(fontSize: 11, color: AppTheme.slate400, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
    );
  }

  Widget _buildErrorState(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFE4E6))),
      child: Text(msg, style: const TextStyle(fontSize: 11, color: AppTheme.primaryRose)),
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        ],
      ),
    );
  }

  void _showSiparisDetail(Siparis s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SiparisDetailSheet(
        siparis: s,
        apiService: _apiService,
        currency: _currency,
        kgFormat: _kgFormat,
        fmtTarih: _fmtTarih,
        onPlakaAtandi: _loadData,
      ),
    );
  }

  void _showYeniSiparisForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _YeniSiparisFormSheet(
        apiService: _apiService,
        onCreated: _loadData,
      ),
    );
  }
}

// ==================== Sipariş Detay + Depo Girişleri ====================

class _SiparisDetailSheet extends StatefulWidget {
  final Siparis siparis;
  final ApiService apiService;
  final NumberFormat currency;
  final NumberFormat kgFormat;
  final String Function(String) fmtTarih;
  final VoidCallback onPlakaAtandi;

  const _SiparisDetailSheet({
    required this.siparis,
    required this.apiService,
    required this.currency,
    required this.kgFormat,
    required this.fmtTarih,
    required this.onPlakaAtandi,
  });

  @override
  State<_SiparisDetailSheet> createState() => _SiparisDetailSheetState();
}

class _SiparisDetailSheetState extends State<_SiparisDetailSheet> {
  List<DepoGirisi> _girisler = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await widget.apiService.getDepoGirisleri(widget.siparis.id);
      if (mounted) setState(() { _girisler = list; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Depo girişleri yüklenemedi: $e'; _isLoading = false; });
    }
  }

  // WhatsApp'ı, kişi seçimi kullanıcıda kalacak şekilde (numara sabitlenmeden)
  // hazır mesajla açar. Gönderilip gönderilmediğini kesin bilemeyiz; uygulama
  // WhatsApp'a geçmeyi başardığı an "gönderildi" kabul edip masaüstündeki
  // aynı alanı (plaka_whatsapp_gonderildi) işaretleriz. Masaüstü uygulamayla
  // aynı kural: aynı plaka için daha önce gönderildiyse tekrar sorulmaz.
  Future<void> _sendPlakaWhatsapp({
    required String plaka,
    required String isimSoyisim,
    required String tcNo,
    required String cap,
  }) async {
    final s = widget.siparis;
    if (plaka.isEmpty) return;
    if (s.plakaWhatsappGonderildi == plaka) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bu sipariş için "$plaka" plaka bilgisi zaten WhatsApp\'tan gönderildi.')),
        );
      }
      return;
    }
    final mesaj = 'Plaka Bilgisi Bildirimi\n\n'
        'Tedarikçi: ${s.tedarikciAd}\n'
        'Sipariş Tarihi: ${widget.fmtTarih(s.siparisTarihi)}\n\n'
        'Plaka: $plaka\n'
        'Ad Soyad: $isimSoyisim\n'
        'TC No: $tcNo\n'
        'Çap: $cap';
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(mesaj)}');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('WhatsApp açılamadı');
      widget.apiService.markPlakaWhatsappGonderildi(s.id, plaka).catchError((_) {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: AppTheme.primaryAmber, content: Text('WhatsApp açılamadı (telefonda yüklü olmayabilir). Plaka bilgisi yine de kaydedildi.')),
        );
      }
    }
  }

  void _showPlakaAtaDialog() {
    final s = widget.siparis;
    final plakaCtrl = TextEditingController(text: s.plaka ?? '');
    final isimCtrl = TextEditingController(text: s.isimSoyisim ?? '');
    final tcCtrl = TextEditingController(text: s.tcNo ?? '');
    final capCtrl = TextEditingController(text: s.cap ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Plaka Ata', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: plakaCtrl, decoration: const InputDecoration(labelText: 'Plaka')),
                TextField(controller: isimCtrl, decoration: const InputDecoration(labelText: 'İsim Soyisim')),
                TextField(controller: tcCtrl, decoration: const InputDecoration(labelText: 'TC No'), keyboardType: TextInputType.number),
                TextField(controller: capCtrl, decoration: const InputDecoration(labelText: 'Çap')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (plakaCtrl.text.trim().isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        await widget.apiService.assignPlaka(
                          siparisId: s.id,
                          plaka: plakaCtrl.text.trim(),
                          isimSoyisim: isimCtrl.text.trim(),
                          tcNo: tcCtrl.text.trim(),
                          cap: capCtrl.text.trim(),
                        );
                        await _sendPlakaWhatsapp(
                          plaka: plakaCtrl.text.trim(),
                          isimSoyisim: isimCtrl.text.trim(),
                          tcNo: tcCtrl.text.trim(),
                          cap: capCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) Navigator.pop(context);
                        widget.onPlakaAtandi();
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Hata: $e')),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.siparis;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(s.tedarikciAd, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.slate400), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _detailChip('Miktar', '${widget.kgFormat.format(s.miktarKg)} KG'),
                  _detailChip('Bölge', s.bolge.isNotEmpty ? s.bolge : '-'),
                  _detailChip('Alım Fiyatı', '${widget.currency.format(s.alimFiyati)}/Ton'),
                  _detailChip('Toplam Tutar', widget.currency.format(s.toplamTutar)),
                  _detailChip('Sipariş Tarihi', widget.fmtTarih(s.siparisTarihi)),
                  _detailChip('Ödeme Tarihi', widget.fmtTarih(s.odemeTarihi)),
                  if (s.plakaAtanmis) _detailChip('Plaka', '${s.plaka} (${s.cap ?? '-'})'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPlakaAtaDialog,
                      icon: Icon(s.plakaAtanmis ? Icons.edit_rounded : Icons.local_shipping_rounded, size: 16),
                      label: Text(s.plakaAtanmis ? 'Plaka Bilgisini Güncelle' : 'Plaka Ata', style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  if (s.plakaAtanmis) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _sendPlakaWhatsapp(
                          plaka: s.plaka ?? '',
                          isimSoyisim: s.isimSoyisim ?? '',
                          tcNo: s.tcNo ?? '',
                          cap: s.cap ?? '',
                        ),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryEmerald, side: const BorderSide(color: AppTheme.primaryEmerald)),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('WhatsApp\'tan Gönder', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Align(alignment: Alignment.centerLeft, child: Text('DEPO GİRİŞLERİ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate500))),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(18), child: Text(_error!, style: const TextStyle(color: AppTheme.primaryRose, fontSize: 12))))
                      : _girisler.isEmpty
                          ? const Center(child: Text('Bu siparişe ait depo girişi bulunamadı.', style: TextStyle(color: AppTheme.slate400, fontSize: 12)))
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                              itemCount: _girisler.length,
                              separatorBuilder: (_, __) => const Divider(height: 18),
                              itemBuilder: (ctx, i) => _buildDepoGirisiRow(_girisler[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepoGirisiRow(DepoGirisi g) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.plaka.isNotEmpty ? g.plaka : '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                  const SizedBox(height: 2),
                  Text(widget.fmtTarih(g.tarih), style: const TextStyle(fontSize: 10, color: AppTheme.slate400)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${widget.kgFormat.format(g.toplamKg)} KG', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                Text(widget.currency.format(g.toplamTutar), style: const TextStyle(fontSize: 10, color: AppTheme.slate500)),
              ],
            ),
          ],
        ),
        if (g.capKirilimi.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: g.capKirilimi.entries.map((e) {
              final cap = e.key.replaceFirst('kg_', '');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.slate100, borderRadius: BorderRadius.circular(6)),
                child: Text('Ø$cap: ${widget.kgFormat.format(e.value)} KG', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppTheme.slate400)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        ],
      ),
    );
  }
}

// ==================== Yeni Sipariş Formu ====================

class _YeniSiparisFormSheet extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onCreated;

  const _YeniSiparisFormSheet({required this.apiService, required this.onCreated});

  @override
  State<_YeniSiparisFormSheet> createState() => _YeniSiparisFormSheetState();
}

class _YeniSiparisFormSheetState extends State<_YeniSiparisFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bolgeCtrl = TextEditingController(text: 'İzmir');
  final _alimFiyatiCtrl = TextEditingController();
  // Masaüstündeki gibi (main.js: formatTRNumber(27400)) miktar hep bu değerle geliyor.
  final _miktarKgCtrl = TextEditingController(text: '27400');
  // Aynı tedarikçi/fiyat/miktarla birden fazla sipariş (araç) tek seferde
  // girilebilsin diye — masaüstündeki "Sipariş Sayısı" ile birebir aynı:
  // her biri AYRI bir sipariş kaydı olarak oluşturulur (tek kayıtta toplanmaz).
  final _sayisiCtrl = TextEditingController(text: '1');
  final _notCtrl = TextEditingController();
  DateTime _siparisTarihi = DateTime.now();
  late DateTime _odemeTarihi;
  bool _saving = false;
  bool _nakliyeDahil = false;
  // Kullanıcı ödeme tarihini elle değiştirmediği sürece, sipariş tarihi
  // değiştikçe masaüstündeki gibi (haftaninCumaGunu) otomatik yeniden hesaplanır.
  bool _odemeElleDegisti = false;

  // Masaüstündeki main.js:haftaninCumaGunu ile birebir aynı: verilen tarihin
  // içinde bulunduğu haftanın Cuma günü; tarih zaten Cuma'yı geçtiyse
  // (Cumartesi/Pazar) bir sonraki haftanın Cuma'sına sarar.
  static DateTime _haftaninCumaGunu(DateTime d) {
    final gunIndex = d.weekday; // Dart: Pazartesi=1 ... Pazar=7 (JS'teki gunIndex ile birebir aynı)
    var fark = 5 - gunIndex;
    if (fark < 0) fark += 7;
    return DateTime(d.year, d.month, d.day).add(Duration(days: fark));
  }

  // Tedarikçi seçimi Zirve'den (CARIGEN, ALICIORSATICI=2) geliyor — masaüstündeki
  // gibi serbest metin değil, listeden seçilmiş gerçek bir REF olması gerekiyor.
  List<Tedarikci> _tedarikciler = [];
  bool _tedarikcilerLoading = true;
  String? _tedarikciYukleHata;
  Tedarikci? _secilenTedarikci;

  final DateFormat _dateFmt = DateFormat('dd.MM.yyyy');
  final NumberFormat _currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  final NumberFormat _kgFormat = NumberFormat('#,##0', 'tr_TR');

  @override
  void initState() {
    super.initState();
    _odemeTarihi = _haftaninCumaGunu(_siparisTarihi);
    // Toplam Miktar/Toplam Tutar özet kartları salt-okunur ve canlı hesaplanıyor;
    // bu üç alandan biri değiştikçe sadece ekranı yeniden çizdiriyoruz.
    final yenidenCiz = () => setState(() {});
    _alimFiyatiCtrl.addListener(yenidenCiz);
    _miktarKgCtrl.addListener(yenidenCiz);
    _sayisiCtrl.addListener(yenidenCiz);
    _loadTedarikciler();
  }

  Future<void> _loadTedarikciler() async {
    setState(() { _tedarikcilerLoading = true; _tedarikciYukleHata = null; });
    try {
      final list = await widget.apiService.getTedarikciler();
      if (mounted) setState(() { _tedarikciler = list; _tedarikcilerLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _tedarikciYukleHata = 'Tedarikçiler yüklenemedi: $e'; _tedarikcilerLoading = false; });
    }
  }

  // Masaüstündeki main.js:hesapla() ile birebir aynı mantık. alim_fiyati TON
  // başınadır. "Toplam Tutar" özet kartı, tedarikçiye tevkifatlı olarak ne
  // ödeneceğinin ÖN İZLEMESİDİR (toplamTutar/1.2*1.1) — her bir siparişe
  // kaydedilecek toplam_tutar bundan farklı, bkz. _birimToplamTutar.
  double get _fiyat => double.tryParse(_alimFiyatiCtrl.text.replaceAll(',', '.')) ?? 0;
  double get _miktar => double.tryParse(_miktarKgCtrl.text.replaceAll(',', '.')) ?? 0;
  int get _sayi => (int.tryParse(_sayisiCtrl.text.trim()) ?? 0).clamp(0, 999999).toInt();
  double get _toplamKg => _miktar * _sayi;
  // Tek bir siparişe (araca) kaydedilecek gerçek tutar — sayı ile çarpılmaz.
  double get _birimToplamTutar => (_miktar / 1000) * _fiyat;
  double get _toplamTutarOnizleme {
    final toplamTutarHam = (_toplamKg / 1000) * _fiyat;
    return (toplamTutarHam / 1.2) * 1.1;
  }

  Future<void> _pickDate(bool isSiparisTarihi) async {
    final initial = isSiparisTarihi ? _siparisTarihi : _odemeTarihi;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isSiparisTarihi) {
          _siparisTarihi = picked;
          if (!_odemeElleDegisti) _odemeTarihi = _haftaninCumaGunu(picked);
        } else {
          _odemeTarihi = picked;
          _odemeElleDegisti = true;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final tedarikci = _secilenTedarikci;
    if (tedarikci == null) return;
    if (_miktar <= 0 || _fiyat <= 0 || _sayi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Lütfen miktar, alım fiyatı ve sipariş sayısını girin.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Masaüstündeki gibi (main.js:kaydet) "Sipariş Sayısı" kadar AYRI sipariş
      // kaydı oluşturulur — tek kayıtta toplanmaz, her biri kendi id'sine sahip olur.
      for (var i = 0; i < _sayi; i++) {
        await widget.apiService.createSiparis(
          tedarikciRef: tedarikci.ref,
          tedarikciAd: tedarikci.ad,
          siparisTarihi: DateFormat('yyyy-MM-dd').format(_siparisTarihi),
          bolge: _bolgeCtrl.text.trim(),
          alimFiyati: _fiyat,
          miktarKg: _miktar,
          toplamTutar: _birimToplamTutar,
          odemeTarihi: DateFormat('yyyy-MM-dd').format(_odemeTarihi),
          notMetni: _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),
          nakliyeDahil: _nakliyeDahil,
        );
      }
      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.primaryRose, content: Text('Hata: $e')),
        );
      }
    }
  }

  Widget _buildTedarikciSecici() {
    if (_tedarikcilerLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue)),
            SizedBox(width: 10),
            Text('Tedarikçiler yükleniyor...', style: TextStyle(fontSize: 11, color: AppTheme.slate500)),
          ],
        ),
      );
    }
    if (_tedarikciYukleHata != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Expanded(child: Text(_tedarikciYukleHata!, style: const TextStyle(fontSize: 11, color: AppTheme.primaryRose))),
            TextButton(onPressed: _loadTedarikciler, child: const Text('Tekrar Dene', style: TextStyle(fontSize: 11))),
          ],
        ),
      );
    }
    return Autocomplete<Tedarikci>(
      displayStringForOption: (t) => t.ad,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Tedarikci>.empty();
        return _tedarikciler.where((t) => t.ad.toLowerCase().contains(q));
      },
      onSelected: (t) => setState(() => _secilenTedarikci = t),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(labelText: 'Tedarikçi Adı', helperText: 'Zirve\'den listeden seçin'),
          onChanged: (v) {
            if (_secilenTedarikci != null && v != _secilenTedarikci!.ad) {
              setState(() => _secilenTedarikci = null);
            }
          },
          validator: (v) => _secilenTedarikci == null ? 'Listeden geçerli bir tedarikçi seçin' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(opt.ad, style: const TextStyle(fontSize: 12)),
                    onTap: () => onSelected(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Masaüstündeki "Toplam Miktar/Toplam Tutar" özet kartları gibi salt okunur —
  // kullanıcı bunu elle düzenlemiyor, Miktar/Fiyat/Sayı'dan otomatik hesaplanıyor.
  Widget _buildOzetKart(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 14),
                const Text('Yeni Sipariş', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                const SizedBox(height: 16),
                _buildTedarikciSecici(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(true),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Sipariş Tarihi: ${_dateFmt.format(_siparisTarihi)}', style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _bolgeCtrl,
                        decoration: const InputDecoration(labelText: 'Bölge'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _alimFiyatiCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Alım Fiyatı (₺/Ton)'),
                        validator: (v) => (v == null || double.tryParse(v.trim().replaceAll(',', '.')) == null) ? 'Geçersiz' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _miktarKgCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Miktar (KG)'),
                        validator: (v) => (v == null || double.tryParse(v.trim().replaceAll(',', '.')) == null) ? 'Geçersiz' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sayisiCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sipariş Sayısı'),
                        validator: (v) => (v == null || int.tryParse(v.trim()) == null || int.parse(v.trim()) < 1) ? 'En az 1 olmalı' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(false),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Ödeme Tarihi: ${_dateFmt.format(_odemeTarihi)}', style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildOzetKart('Toplam Miktar', '${_kgFormat.format(_toplamKg)} Kg')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildOzetKart('Toplam Tutar', _currency.format(_toplamTutarOnizleme))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppTheme.slate700),
                          children: [
                            const TextSpan(text: 'Nakliye '),
                            TextSpan(text: _nakliyeDahil ? 'Dahil' : 'Hariç', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    Switch(value: _nakliyeDahil, onChanged: (v) => setState(() => _nakliyeDahil = v)),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Not (isteğe bağlı)', hintText: 'Bu siparişle ilgili kısa bir not...'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Siparişi Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
