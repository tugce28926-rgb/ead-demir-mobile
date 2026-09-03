class CariSummary {
  final String cariKod;
  final String cariAd;
  final String? vergiNo;
  final double bakiye;
  final String tur; // 'borclu' or 'alacakli'

  CariSummary({
    required this.cariKod,
    required this.cariAd,
    this.vergiNo,
    required this.bakiye,
    required this.tur,
  });

  factory CariSummary.fromJson(Map<String, dynamic> json) {
    return CariSummary(
      cariKod: (json['cariKod'] ?? json['REF'] ?? '').toString(),
      cariAd: (json['cariAd'] ?? json['UNVAN'] ?? json['CARI_AD'] ?? '').toString(),
      vergiNo: json['vergiNo']?.toString() ?? json['VERGINO']?.toString(),
      bakiye: (json['bakiye'] ?? json['BORC_TUTARI'] ?? json['ALACAK_TUTARI'] ?? 0).toDouble(),
      tur: (json['tur'] ?? (json['BORC_TUTARI'] != null ? 'borclu' : 'alacakli')).toString(),
    );
  }
}
