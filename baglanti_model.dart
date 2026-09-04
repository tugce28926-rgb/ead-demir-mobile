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
  });

  factory Baglanti.fromJson(Map<String, dynamic> json) {
    final miktar = (json['miktar'] ?? json['toplamKg'] ?? 0).toDouble();
    final kullanilan = (json['kullanilanKg'] ?? 0).toDouble();
    final kalan = (json['kalanKg'] ?? json['kalanMiktar'] ?? (miktar - kullanilan)).toDouble();
    final bFiyat = (json['birimFiyat'] ?? json['birim_fiyat'] ?? 0).toDouble();
    final bTutar = (json['kalanTutar'] ?? (kalan * bFiyat)).toDouble();

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
    );
  }
}

class BaglantiItem {
  final String id;
  final String baslik;
  final double toplamKg;
  final double teslimEdilenKg;
  final double kalanKg;
  final double birimFiyat;
  final double toplamTutar;
  final double kalanTutar;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final bool isAktif;

  BaglantiItem({
    required this.id,
    required this.baslik,
    required this.toplamKg,
    required this.teslimEdilenKg,
    required this.kalanKg,
    required this.birimFiyat,
    required this.toplamTutar,
    required this.kalanTutar,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.isAktif,
  });

  double get tamamlanmaOrani => toplamKg > 0 ? (teslimEdilenKg / toplamKg) : 0;
}

class CariDetailData {
  final String cariAd;
  final String vergiNo;
  final String vergiDairesi;
  final String telefon;
  final String sehir;
  final double bakiye;
  final double toplamCiro;
  final double kalanTutar;
  final double kalanBaglantiKg;
  final double toplamSatisKg;
  final List<BaglantiItem> baglantilar;

  CariDetailData({
    required this.cariAd,
    required this.vergiNo,
    required this.vergiDairesi,
    required this.telefon,
    required this.sehir,
    required this.bakiye,
    required this.toplamCiro,
    required this.kalanTutar,
    required this.kalanBaglantiKg,
    required this.toplamSatisKg,
    required this.baglantilar,
  });
}
