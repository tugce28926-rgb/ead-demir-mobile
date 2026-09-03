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
    DateTime parsedDate = DateTime.now();
    if (json['EVRAK_TARIHI'] != null) {
      try {
        parsedDate = DateTime.parse(json['EVRAK_TARIHI'].toString());
      } catch (e) {
        parsedDate = DateTime.now();
      }
    }
    return RecentInvoice(
      id: (json['EVRAK_ID'] ?? 0) is int ? json['EVRAK_ID'] : int.tryParse(json['EVRAK_ID'].toString()) ?? 0,
      evrakRef: (json['EVRAK_REF'] ?? json['EVRAKNO'] ?? '').toString(),
      date: parsedDate,
      tutar: (json['EVRAK_TUTARI'] ?? json['GENELTOPLAM'] ?? 0).toDouble(),
      cariAd: (json['CARI_AD'] ?? json['CARIADI'] ?? '').toString(),
      tur: (json['FATURA_TURU'] ?? 'e-Fatura').toString(),
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
    DateTime parsedDate = DateTime.now();
    if (json['EVRAK_TARIHI'] != null) {
      try {
        parsedDate = DateTime.parse(json['EVRAK_TARIHI'].toString());
      } catch (e) {
        parsedDate = DateTime.now();
      }
    }
    return RecentWaybill(
      id: (json['EVRAK_ID'] ?? 0) is int ? json['EVRAK_ID'] : int.tryParse(json['EVRAK_ID'].toString()) ?? 0,
      evrakRef: (json['EVRAK_REF'] ?? json['EVRAKNO'] ?? '').toString(),
      date: parsedDate,
      cariAd: (json['CARI_AD'] ?? json['CARIADI'] ?? '').toString(),
      miktarKg: (json['TOPLAM_MIKTAR'] ?? 0).toDouble(),
    );
  }
}
