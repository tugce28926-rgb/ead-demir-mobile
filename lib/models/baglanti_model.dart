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
