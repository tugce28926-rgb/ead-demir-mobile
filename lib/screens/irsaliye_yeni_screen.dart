import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class IrsaliyeKalemItem {
  String stokAdi;
  double miktarAdet;
  double miktarKg;
  double birimFiyat;

  IrsaliyeKalemItem({
    required this.stokAdi,
    required this.miktarAdet,
    required this.miktarKg,
    required this.birimFiyat,
  });

  double get toplamTutar => miktarKg * birimFiyat;
}

class IrsaliyeYeniScreen extends StatefulWidget {
  const IrsaliyeYeniScreen({super.key});

  @override
  State<IrsaliyeYeniScreen> createState() => _IrsaliyeYeniScreenState();
}

class _IrsaliyeYeniScreenState extends State<IrsaliyeYeniScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cariController = TextEditingController();
  final TextEditingController _plakaController = TextEditingController();
  final TextEditingController _soforController = TextEditingController();
  final TextEditingController _tcknController = TextEditingController();
  final TextEditingController _sevkAdresiController = TextEditingController();

  final List<IrsaliyeKalemItem> _kalemler = [
    IrsaliyeKalemItem(stokAdi: 'Ø 12 Nervürlü İnşaat Demiri (12m)', miktarAdet: 250, miktarKg: 2665, birimFiyat: 24.50),
    IrsaliyeKalemItem(stokAdi: 'Ø 16 Nervürlü İnşaat Demiri (12m)', miktarAdet: 180, miktarKg: 3410, birimFiyat: 24.50),
  ];

  double get _toplamKg => _kalemler.fold(0, (sum, k) => sum + k.miktarKg);
  double get _genelToplam => _kalemler.fold(0, (sum, k) => sum + k.toplamTutar);

  void _addKalem() {
    setState(() {
      _kalemler.add(
        IrsaliyeKalemItem(stokAdi: 'Yeni Malzeme Kalemi', miktarAdet: 100, miktarKg: 1000, birimFiyat: 25.00),
      );
    });
  }

  void _removeKalem(int index) {
    if (_kalemler.length > 1) {
      setState(() => _kalemler.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final kgFmt = NumberFormat('#,##0', 'tr_TR');

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Yeni e-İrsaliye Kes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // Cari Seçimi
            _buildSectionHeader('1. MÜŞTERİ / CARİ SEÇİMİ'),
            TextFormField(
              controller: _cariController,
              decoration: InputDecoration(
                hintText: 'Zirve cari adı veya VKN arayınız...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.slate400),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.slate400, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.slate200)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Cari seçiniz' : null,
            ),
            const SizedBox(height: 14),

            // Taşıma & Araç Bilgileri
            _buildSectionHeader('2. SEVK & TAŞIMA BİLGİLERİ'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _plakaController,
                          decoration: const InputDecoration(
                            labelText: 'Araç Plakası',
                            labelStyle: TextStyle(fontSize: 11),
                            hintText: '34 EAD 001',
                            prefixIcon: Icon(Icons.directions_car, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _soforController,
                          decoration: const InputDecoration(
                            labelText: 'Şoför Adı Soyadı',
                            labelStyle: TextStyle(fontSize: 11),
                            hintText: 'Ahmet Yılmaz',
                            prefixIcon: Icon(Icons.person, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _sevkAdresiController,
                    decoration: const InputDecoration(
                      labelText: 'Sevk / Şantiye Teslim Adresi',
                      labelStyle: TextStyle(fontSize: 11),
                      hintText: 'Şantiye teslim adresi...',
                      prefixIcon: Icon(Icons.location_on, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Malzeme Satırları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('3. DEMİR & ÇELİK MALZEME KALEMLERİ'),
                TextButton.icon(
                  onPressed: _addKalem,
                  icon: const Icon(Icons.add_circle, size: 16, color: AppTheme.primaryBlue),
                  label: const Text('Satır Ekle', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ),
              ],
            ),

            ..._kalemler.asMap().entries.map((entry) {
              final idx = entry.key;
              final k = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kalem #${idx + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryPurple)),
                        if (_kalemler.length > 1)
                          InkWell(
                            onTap: () => _removeKalem(idx),
                            child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.primaryRose),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(k.stokAdi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${k.miktarAdet.toInt()} Adet', style: const TextStyle(fontSize: 11, color: AppTheme.slate600)),
                        Text('${kgFmt.format(k.miktarKg)} KG', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                        Text(currency.format(k.toplamTutar), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 14),

            // Toplam Ağırlık & Tutar Kartı
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOPLAM TONAJ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryPurple)),
                      Text('${kgFmt.format(_toplamKg)} KG', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('GENEL TOPLAM (KDV DAHİL)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
                      Text(currency.format(_genelToplam * 1.20), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Zirve'ye İrsaliye Kaydet Butonu
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('İrsaliyeyi Zirve\'ye Kaydet & Oluştur', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('İrsaliye Kaydedildi', style: TextStyle(fontWeight: FontWeight.w900)),
                      content: const Text('İrsaliye başarıyla Zirve SQL tablolarına yazıldı ve GİB sevk kuyruğuna alındı.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)),
    );
  }
}
