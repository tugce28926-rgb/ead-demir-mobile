class CariSummary {
  final String cariAd;
  final String? vergiNo;
  final double bakiye;
  final String tur; // 'borclu' or 'alacakli'

  CariSummary({
    required this.cariAd,
    this.vergiNo,
    required this.bakiye,
    required this.tur,
  });

  factory CariSummary.fromJson(Map<String, dynamic> json) {
    return CariSummary(
      cariAd: json['CARI_AD'] ?? '',
      vergiNo: json['VERGI_NOSU'] ?? '',
      bakiye: (json['BORC_TUTARI'] ?? json['ALACAK_TUTARI'] ?? 0).toDouble(),
      tur: json['BORC_TUTARI'] != null ? 'borclu' : 'alacakli',
    );
  }
}
