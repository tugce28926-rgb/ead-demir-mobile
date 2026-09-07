class KpiData {
  final double bugunFaturaTutar;
  final int bugunFaturaAdet;
  final double bugunSevkKg;
  final int bugunSevkAdet;
  final double musteriBorclari;
  final double tedarikciBorcu;

  // Compatibility aliases
  double get toplamAlacak => musteriBorclari;
  double get toplamBorc => tedarikciBorcu;
  double get toplamSatisKg => bugunSevkKg;
  double get bankaNetBakiye => 0.0;

  KpiData({
    required this.bugunFaturaTutar,
    required this.bugunFaturaAdet,
    required this.bugunSevkKg,
    required this.bugunSevkAdet,
    required this.musteriBorclari,
    required this.tedarikciBorcu,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      bugunFaturaTutar: (json['bugunFaturaTutar'] ?? json['bugunFatura'] ?? 0).toDouble(),
      bugunFaturaAdet: json['bugunFaturaAdet'] ?? 0,
      bugunSevkKg: (json['bugunSevkKg'] ?? json['bugunSevk'] ?? 0).toDouble(),
      bugunSevkAdet: json['bugunSevkAdet'] ?? 0,
      musteriBorclari: (json['musteriBorclari'] ?? json['toplamAlacak'] ?? 0).toDouble(),
      tedarikciBorcu: (json['tedarikciBorcu'] ?? json['toplamBorc'] ?? 0).toDouble(),
    );
  }
}
