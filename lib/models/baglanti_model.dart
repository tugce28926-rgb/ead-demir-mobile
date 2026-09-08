class Satis {
  final String evrakNo;
  final String tarih;
  final double toplamKg;
  final double birimFiyat;
  final double bagTutar;

  Satis({
    required this.evrakNo,
    required this.tarih,
    required this.toplamKg,
    required this.birimFiyat,
    required this.bagTutar,
  });

  factory Satis.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);
    return Satis(
      evrakNo: (json['evrakNo'] ?? '-').toString(),
      tarih: (json['tarih'] ?? '').toString(),
      toplamKg: toDouble(json['toplamKg'] ?? json['bagKg']),
      birimFiyat: toDouble(json['birimFiyat']),
      bagTutar: toDouble(json['bagTutar']),
    );
  }
}

class Baglanti {
  final dynamic id;
  final String baglantiNo;
  final String cariAd;
  final String cariVergiNo;
  final double toplamKg;
  final double kullanilanKg;
  final double kalanKg;
  final double birimFiyat;
  final double toplamTutar;
  final double kalanTutar;
  final String status;
  final bool tevkifat;
  final String baglantiTarihi;
  final double kullanimYuzdesi; // 0-100
  final List<Satis> satislar; // sevkiyat / çıkış geçmişi (cari-özel detay çağrısında dolu gelir)
  final int subCount; // aynı cariye ait kaç bağlantı gruplandı (özet listede)

  Baglanti({
    required this.id,
    required this.baglantiNo,
    required this.cariAd,
    this.cariVergiNo = '',
    required this.toplamKg,
    this.kullanilanKg = 0,
    required this.kalanKg,
    required this.birimFiyat,
    required this.toplamTutar,
    required this.kalanTutar,
    this.status = 'aktif',
    this.tevkifat = false,
    this.baglantiTarihi = '',
    this.kullanimYuzdesi = 0,
    this.satislar = const [],
    this.subCount = 1,
  });

  double get tamamlanmaOrani => toplamKg > 0 ? (kullanilanKg / toplamKg).clamp(0, 1) : 0;

  factory Baglanti.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);

    final miktar = toDouble(json['miktar'] ?? json['toplamKg']);
    final kullanilan = toDouble(json['kullanilanKg']);
    final kalan = json['kalanKg'] != null ? toDouble(json['kalanKg']) : (miktar - kullanilan);
    final bFiyat = toDouble(json['birimFiyat'] ?? json['birim_fiyat']);
    final bTutar = json['kalanTutar'] != null ? toDouble(json['kalanTutar']) : (kalan * bFiyat);

    return Baglanti(
      id: json['_id'] ?? json['id'] ?? 0,
      baglantiNo: (json['baglantiAdi'] ?? json['baglantiNo'] ?? json['ozel_ad'] ?? '1. Bağlantı').toString(),
      cariAd: (json['cariAdi'] ?? json['cariAd'] ?? json['ad'] ?? json['unvan'] ?? '').toString(),
      cariVergiNo: (json['cariVergiNo'] ?? json['vergino'] ?? '').toString(),
      toplamKg: miktar,
      kullanilanKg: kullanilan,
      kalanKg: kalan,
      birimFiyat: bFiyat,
      toplamTutar: miktar * bFiyat,
      kalanTutar: bTutar,
      status: (json['status'] ?? 'aktif').toString(),
      tevkifat: json['tevkifat'] == true || json['tevkifat'] == 'true',
      baglantiTarihi: (json['baglantiTarihi'] ?? '').toString(),
      kullanimYuzdesi: toDouble(json['kullanimYuzdesi']),
      satislar: (json['satislar'] is List)
          ? (json['satislar'] as List).map((e) => Satis.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
      subCount: (json['subCount'] is num) ? (json['subCount'] as num).toInt() : 1,
    );
  }
}
