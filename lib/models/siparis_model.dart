double _toDouble(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);
int _toInt(dynamic v) => v is num ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0);
bool _toBool(dynamic v) => v == true || v == 'true';

// Zirve CARIGEN'den (ALICIORSATICI=2) gelen tedarikçi kaydı — "Yeni Sipariş"
// formunda tedarikçi seçimi için kullanılır.
class Tedarikci {
  final int ref;
  final String ad;
  final String vergiNo;

  Tedarikci({required this.ref, required this.ad, this.vergiNo = ''});

  factory Tedarikci.fromJson(Map<String, dynamic> json) {
    return Tedarikci(
      ref: _toInt(json['ref']),
      ad: (json['ad'] ?? '').toString(),
      vergiNo: (json['vergiNo'] ?? '').toString(),
    );
  }
}

class Siparis {
  final String id;
  final int tedarikciRef;
  final String tedarikciAd;
  final String siparisTarihi;
  final String bolge;
  final double alimFiyati;
  final double miktarKg;
  final double toplamTutar;
  final String odemeTarihi;
  final bool faturaGeldi;
  final bool odendi;
  final double odenenTutar;
  final double nakliyeTutari;
  final bool nakliyeOdendi;
  final double gelenTutar;
  final String? notMetni;
  final bool nakliyeDahil;
  final bool gizli;
  final String? plaka;
  final String? isimSoyisim;
  final String? tcNo;
  final String? cap;
  final String? plakaWhatsappGonderildi;
  // Bu siparişe bağlı depo_girisleri toplamları (backend'de hesaplanıp eklenir).
  // Masaüstündeki "Bekleyen Siparişler / Depoya Gelenler" sekme ayrımı da
  // buna göre yapılıyor: gelenKg <= 0 ise bekleyen, > 0 ise depoya gelmiş demektir.
  final double gelenKg;
  final double odenecekTutar;
  final List<String> gelisTarihleri;
  final List<String> plakalar;

  Siparis({
    required this.id,
    required this.tedarikciRef,
    required this.tedarikciAd,
    required this.siparisTarihi,
    this.bolge = '',
    required this.alimFiyati,
    required this.miktarKg,
    required this.toplamTutar,
    required this.odemeTarihi,
    this.faturaGeldi = false,
    this.odendi = false,
    this.odenenTutar = 0,
    this.nakliyeTutari = 0,
    this.nakliyeOdendi = false,
    this.gelenTutar = 0,
    this.notMetni,
    this.nakliyeDahil = false,
    this.gizli = false,
    this.plaka,
    this.isimSoyisim,
    this.tcNo,
    this.cap,
    this.plakaWhatsappGonderildi,
    this.gelenKg = 0,
    this.odenecekTutar = 0,
    this.gelisTarihleri = const [],
    this.plakalar = const [],
  });

  bool get plakaAtanmis => (plaka ?? '').trim().isNotEmpty;
  bool get depoyaGeldi => gelenKg > 0;

  factory Siparis.fromJson(Map<String, dynamic> json) {
    return Siparis(
      id: (json['id'] ?? '').toString(),
      tedarikciRef: _toInt(json['tedarikci_ref']),
      tedarikciAd: (json['tedarikci_ad'] ?? '').toString(),
      siparisTarihi: (json['siparis_tarihi'] ?? '').toString(),
      bolge: (json['bolge'] ?? '').toString(),
      alimFiyati: _toDouble(json['alim_fiyati']),
      miktarKg: _toDouble(json['miktar_kg']),
      toplamTutar: _toDouble(json['toplam_tutar']),
      odemeTarihi: (json['odeme_tarihi'] ?? '').toString(),
      faturaGeldi: _toBool(json['fatura_geldi']),
      odendi: _toBool(json['odendi']),
      odenenTutar: _toDouble(json['odenen_tutar']),
      nakliyeTutari: _toDouble(json['nakliye_tutari']),
      nakliyeOdendi: _toBool(json['nakliye_odendi']),
      gelenTutar: _toDouble(json['gelen_tutar']),
      notMetni: json['not_metni']?.toString(),
      nakliyeDahil: _toBool(json['nakliye_dahil']),
      gizli: _toBool(json['gizli']),
      plaka: json['plaka']?.toString(),
      isimSoyisim: json['isim_soyisim']?.toString(),
      tcNo: json['tc_no']?.toString(),
      cap: json['cap']?.toString(),
      plakaWhatsappGonderildi: json['plaka_whatsapp_gonderildi']?.toString(),
      gelenKg: _toDouble(json['gelenKg']),
      odenecekTutar: _toDouble(json['odenecekTutar']),
      gelisTarihleri: (json['gelisTarihleri'] is List) ? (json['gelisTarihleri'] as List).map((e) => e.toString()).toList() : const [],
      plakalar: (json['plakalar'] is List) ? (json['plakalar'] as List).map((e) => e.toString()).toList() : const [],
    );
  }
}

class DepoGirisi {
  final String id;
  final String siparisId;
  final String tarih;
  final String plaka;
  final double toplamKg;
  final double toplamTutar;
  final double odenecekTutar;
  final Map<String, double> capKirilimi; // ör. {"kg_12": 4200.0, ...} sıfır olmayanlar

  DepoGirisi({
    required this.id,
    required this.siparisId,
    required this.tarih,
    required this.plaka,
    required this.toplamKg,
    required this.toplamTutar,
    required this.odenecekTutar,
    this.capKirilimi = const {},
  });

  factory DepoGirisi.fromJson(Map<String, dynamic> json) {
    final capKirilimi = <String, double>{};
    json.forEach((key, value) {
      if (key.startsWith('kg_')) {
        final v = _toDouble(value);
        if (v > 0) capKirilimi[key] = v;
      }
    });
    return DepoGirisi(
      id: (json['id'] ?? '').toString(),
      siparisId: (json['siparis_id'] ?? '').toString(),
      tarih: (json['tarih'] ?? '').toString(),
      plaka: (json['plaka'] ?? '').toString(),
      toplamKg: _toDouble(json['toplam_kg']),
      toplamTutar: _toDouble(json['toplam_tutar']),
      odenecekTutar: _toDouble(json['odenecek_tutar']),
      capKirilimi: capKirilimi,
    );
  }
}
