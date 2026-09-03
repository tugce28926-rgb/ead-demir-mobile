class RecentInvoice {
  final int id;
  final String evrakRef;
  final DateTime date;
  final double tutar;
  final String cariAd;
  final String tur; // 'e-Fatura' or 'e-Arşiv'

  RecentInvoice({
    required this.id,
    required this.evrakRef,
    required this.date,
    required this.tutar,
    required this.cariAd,
    required this.tur,
  });

  factory RecentInvoice.fromJson(Map<String, dynamic> json) {
    return RecentInvoice(
      id: json['EVRAK_ID'] ?? 0,
      evrakRef: json['EVRAK_REF'] ?? '',
      date: json['EVRAK_TARIHI'] != null ? DateTime.parse(json['EVRAK_TARIHI']) : DateTime.now(),
      tutar: (json['EVRAK_TUTARI'] ?? 0).toDouble(),
      cariAd: json['CARI_AD'] ?? '',
      tur: json['FATURA_TURU'] ?? 'e-Fatura',
    );
  }
}

class RecentWaybill {
  final int id;
  final String evrakRef;
  final DateTime date;
  final String cariAd;
  final double miktarKg;

  RecentWaybill({
    required this.id,
    required this.evrakRef,
    required this.date,
    required this.cariAd,
    required this.miktarKg,
  });

  factory RecentWaybill.fromJson(Map<String, dynamic> json) {
    return RecentWaybill(
      id: json['EVRAK_ID'] ?? 0,
      evrakRef: json['EVRAK_REF'] ?? '',
      date: json['EVRAK_TARIHI'] != null ? DateTime.parse(json['EVRAK_TARIHI']) : DateTime.now(),
      cariAd: json['CARI_AD'] ?? '',
      miktarKg: (json['TOPLAM_MIKTAR'] ?? 0).toDouble(),
    );
  }
}
