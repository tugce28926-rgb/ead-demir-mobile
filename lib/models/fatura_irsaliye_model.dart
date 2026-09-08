class RecentInvoice {
class RecentInvoice {
  final int id;
  final String evrakRef;
  final DateTime date;
  final double tutar;
  final String cariAd;
  final String tur;
  final bool isGibGonderildi;
  final bool isIptal;
  final double birimFiyat;

  // Aliases for 100% build compatibility
  String get evrakNo => evrakRef;
  String get cariUnvan => cariAd;
  double get genelToplam => tutar;
  DateTime get tarih => date;
  double get miktar => 0.0;

  // NOT: backend BIRIM_FIYAT'ı zaten KDV DAHİL hesaplayıp gönderiyor
  // (fatura-liste.ejs ile aynı kanıtlanmış formül: TOPLAM_KDV * 6 / TOPLAM_MIKTAR).
  // Burada tekrar KDV eklemiyoruz, mükerrer hesap olur.
  double get birimFiyatKdvDahil => birimFiyat;

  RecentInvoice({
    required this.id,
    required this.evrakRef,
    required this.date,
    required this.tutar,
    required this.cariAd,
    required this.tur,
    this.isGibGonderildi = false,
    this.isIptal = false,
    this.birimFiyat = 0.0,
  });

  factory RecentInvoice.fromJson(Map<String, dynamic> json) {
    DateTime dt = DateTime.now();
    final rawDate = json['EVRAK_TARIHI'] ?? json['date'] ?? json['EVRAKTAR'] ?? json['tarih'];
    if (rawDate != null) {
      try {
        dt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    final numRaw = json['EVRAK_TUTARI'] ?? json['tutar'] ?? json['genelToplam'] ?? json['GENELTOPLAM'] ?? 0;
    final tutarVal = numRaw is num ? numRaw.toDouble() : (double.tryParse(numRaw.toString()) ?? 0.0);

    final birimFiyatRaw = json['BIRIM_FIYAT'] ?? json['birimFiyat'] ?? 0;
    final birimFiyatVal = birimFiyatRaw is num ? birimFiyatRaw.toDouble() : (double.tryParse(birimFiyatRaw.toString()) ?? 0.0);

    return RecentInvoice(
      id: int.tryParse((json['EVRAK_ID'] ?? json['id'] ?? json['SIRANO'] ?? 0).toString()) ?? 0,
      evrakRef: (json['EVRAK_REF'] ?? json['evrakRef'] ?? json['evrakNo'] ?? json['EVRAKNO'] ?? '').toString(),
      date: dt,
      tutar: tutarVal,
      cariAd: (json['CARI_AD'] ?? json['cariAd'] ?? json['cariUnvan'] ?? json['CARIADI'] ?? '').toString(),
      tur: (json['FATURA_TURU'] ?? json['tur'] ?? 'e-Fatura').toString(),
      isGibGonderildi: json['IS_GIB_GONDERILDI'] == 1 || json['isGibGonderildi'] == true || json['IS_GIB_GONDERILDI'] == '1',
      isIptal: json['IS_IPTAL'] == 1 || json['isIptal'] == true || json['IS_IPTAL'] == '1',
      birimFiyat: birimFiyatVal,
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

  // Aliases for 100% build compatibility
  String get irsaliyeNo => evrakRef;
  String get evrakNo => evrakRef;
  String get cariUnvan => cariAd;
  double get miktar => miktarKg;
  DateTime get tarih => date;
  String get durum => isFaturalandi ? 'Faturalandı' : 'Bekliyor';

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
    final rawDate = json['EVRAK_TARIHI'] ?? json['date'] ?? json['EVRAKTAR'] ?? json['tarih'];
    if (rawDate != null) {
      try {
        dt = DateTime.parse(rawDate.toString());
      } catch (_) {}
    }

    final fatNo = (json['FATURA_NO'] ?? json['faturaNo'] ?? '').toString();
    final isFat = json['IS_FATURALANDI'] == 1 ||
                  json['isFaturalandi'] == true ||
                  json['FATURA_DURUM'] == 'Faturalandı' ||
                  fatNo.trim().isNotEmpty;

    final miktarRaw = json['TOPLAM_MIKTAR'] ?? json['miktarKg'] ?? json['miktar'] ?? 0;
    final miktarVal = miktarRaw is num ? miktarRaw.toDouble() : (double.tryParse(miktarRaw.toString()) ?? 0.0);

    return RecentWaybill(
      id: int.tryParse((json['EVRAK_ID'] ?? json['id'] ?? json['SIRANO'] ?? 0).toString()) ?? 0,
      evrakRef: (json['EVRAK_REF'] ?? json['evrakRef'] ?? json['irsaliyeNo'] ?? json['EVRAKNO'] ?? '').toString(),
      date: dt,
      cariAd: (json['CARI_AD'] ?? json['cariAd'] ?? json['cariUnvan'] ?? json['CARIADI'] ?? '').toString(),
      miktarKg: miktarVal,
      faturaNo: fatNo,
      isFaturalandi: isFat,
      isGibGonderildi: json['IS_GIB_GONDERILDI'] == 1 || json['isGibGonderildi'] == true || json['IS_GIB_GONDERILDI'] == '1',
      isIptal: json['IS_IPTAL'] == 1 || json['isIptal'] == true || json['IS_IPTAL'] == '1',
    );
  }
}
