class KpiData {
  final double bugunFaturaTutar;
  final int bugunFaturaAdet;
  final double bugunSevkKg;
  final int bugunSevkAdet;
  final double musteriBorclari;
  final double tedarikciBorcu;

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
      bugunFaturaTutar: (json['bugunFaturaTutar'] ?? 0).toDouble(),
      bugunFaturaAdet: json['bugunFaturaAdet'] ?? 0,
      bugunSevkKg: (json['bugunSevkKg'] ?? 0).toDouble(),
      bugunSevkAdet: json['bugunSevkAdet'] ?? 0,
      musteriBorclari: (json['musteriBorclari'] ?? 0).toDouble(),
      tedarikciBorcu: (json['tedarikciBorcu'] ?? 0).toDouble(),
    );
  }
}
