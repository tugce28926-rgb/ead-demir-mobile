class RecentInvoice {
  final int id;
  final String evrakRef;
  final DateTime date;
  final double tutar;
  final String cariAd;
  final String tur;
  final bool isGibGonderildi;
  final bool isIptal;

  RecentInvoice({
    required this.id,
    required this.evrakRef,
    required this.date,
    required this.tutar,
    required this.cariAd,
    required this.tur,
    this.isGibGonderildi = false,
    this.isIptal = false,
  });

  factory RecentInvoice.fromJson(Map<String, dynamic> json) {
    DateTime dt = DateTime.now();
    final rawDate = json['EVRAK_TARIHI'] ?? json['date'] ?? json['EVRAKTAR'];
    if (rawDate != null) {
      try {
        dt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    return RecentInvoice(
      id: json['EVRAK_ID'] ?? json['id'] ?? json['SIRANO'] ?? 0,
      evrakRef: json['EVRAK_REF'] ?? json['evrakRef'] ?? json['EVRAKNO'] ?? '',
      date: dt,
      tutar: (json['EVRAK_TUTARI'] ?? json['tutar'] ?? json['GENELTOPLAM'] ?? 0).toDouble(),
      cariAd: json['CARI_AD'] ?? json['cariAd'] ?? json['CARIADI'] ?? '',
      tur: json['FATURA_TURU'] ?? json['tur'] ?? 'e-Fatura',
      isGibGonderildi: json['IS_GIB_GONDERILDI'] == 1 || json['isGibGonderildi'] == true,
      isIptal: json['IS_IPTAL'] == 1 || json['isIptal'] == true,
    );
  }
}

class RecentWaybill {
  final int id;
  final String evrakRef;
  final DateTime date;
  final String cariAd;
  final double miktarKg;
  final String faturaNo;
  final bool isFaturalandi;
  final bool isGibGonderildi;
  final bool isIptal;

  RecentWaybill({
    required this.id,
    required this.evrakRef,
    required this.date,
    required this.cariAd,
    required this.miktarKg,
    this.faturaNo = '',
    this.isFaturalandi = false,
    this.isGibGonderildi = false,
    this.isIptal = false,
  });

  factory RecentWaybill.fromJson(Map<String, dynamic> json) {
    DateTime dt = DateTime.now();
    final rawDate = json['EVRAK_TARIHI'] ?? json['date'] ?? json['EVRAKTAR'];
    if (rawDate != null) {
      try {
        dt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    return RecentWaybill(
      id: json['EVRAK_ID'] ?? json['id'] ?? json['SIRANO'] ?? 0,
      evrakRef: json['EVRAK_REF'] ?? json['evrakRef'] ?? json['EVRAKNO'] ?? '',
      date: dt,
      cariAd: json['CARI_AD'] ?? json['cariAd'] ?? json['CARIADI'] ?? '',
      miktarKg: (json['TOPLAM_MIKTAR'] ?? json['miktarKg'] ?? 0).toDouble(),
      faturaNo: (json['FATURA_NO'] ?? json['faturaNo'] ?? '').toString(),
      isFaturalandi: json['IS_FATURALANDI'] == 1 || json['isFaturalandi'] == true,
      isGibGonderildi: json['IS_GIB_GONDERILDI'] == 1 || json['isGibGonderildi'] == true,
      isIptal: json['IS_IPTAL'] == 1 || json['isIptal'] == true,
    );
  }
}
