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
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return KpiData(
      bugunFaturaTutar: parseDouble(json['bugunFaturaTutar'] ?? json['bugunFatura']),
      bugunFaturaAdet: parseInt(json['bugunFaturaAdet']),
      bugunSevkKg: parseDouble(json['bugunSevkKg'] ?? json['bugunSevk']),
      bugunSevkAdet: parseInt(json['bugunSevkAdet']),
      musteriBorclari: parseDouble(json['musteriBorclari'] ?? json['toplamAlacak']),
      tedarikciBorcu: parseDouble(json['tedarikciBorcu'] ?? json['toplamBorc']),
    );
  }
}
