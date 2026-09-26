import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/kpi_model.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../models/baglanti_model.dart';
import '../models/fatura_irsaliye_model.dart';
import '../models/pending_email_model.dart';
import '../models/siparis_model.dart';

class ApiService {
  static String currentUser = '';
  static bool isAdmin = false;
  static List<String> allowedOperations = [];
  static bool get isLoggedIn => currentUser.trim().isNotEmpty;

  static const _prefUser = 'ead_user';
  static const _prefAdmin = 'ead_is_admin';
  static const _prefOps = 'ead_allowed_ops';

  // Uygulama açılışında (main.dart) çağrılır: daha önce giriş yapılmışsa
  // kullanıcıyı hatırlar, tekrar giriş ekranı göstermez.
  static Future<void> loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString(_prefUser) ?? '';
      if (savedUser.trim().isNotEmpty) {
        currentUser = savedUser;
        isAdmin = prefs.getBool(_prefAdmin) ?? false;
        allowedOperations = prefs.getStringList(_prefOps) ?? [];
      }
    } catch (_) {
      // Kalıcı depoya erişilemezse sessizce normal giriş akışına düşer.
    }
  }

  static void setUser(String username, {bool admin = false, List<String>? ops}) {
    currentUser = username.trim();
    isAdmin = admin;
    allowedOperations = ops ?? [];
    _persistSession();
  }

  static Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUser, currentUser);
      await prefs.setBool(_prefAdmin, isAdmin);
      await prefs.setStringList(_prefOps, allowedOperations);
    } catch (_) {}
  }

  static void logout() {
    currentUser = '';
    isAdmin = false;
    allowedOperations = [];
    SharedPreferences.getInstance().then((prefs) => prefs.clear()).catchError((_) {});
  }

  late final Dio _dio;
  String activeCompany = AppConstants.defaultCompany;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://eadonline.site/api/v1/',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ));
    syncUserHeader();
  }

  void setCompany(String companyDb) {
    activeCompany = companyDb;
    _dio.options.headers['X-Company-Db'] = companyDb;
  }

  void syncUserHeader() {
    if (currentUser.isNotEmpty) {
      _dio.options.headers['X-User-Name'] = Uri.encodeComponent(currentUser);
    } else {
      _dio.options.headers.remove('X-User-Name');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await _dio.post('auth/login', data: {
        'username': username,
        'password': password,
      });
      if (res.data is Map && res.data['ok'] == true) {
        final uName = res.data['username'] ?? username;
        final isAdm = res.data['isAdmin'] == true;
        final ops = (res.data['allowedOperations'] as List?)?.map((e) => e.toString()).toList() ?? [];
        setUser(uName.toString(), admin: isAdm, ops: ops);
        syncUserHeader();
        return {'ok': true, 'username': uName, 'isAdmin': isAdm};
      }
      return {'ok': false, 'error': res.data['error'] ?? 'Giriş başarısız'};
    } on DioException catch (e) {
      final err = e.response?.data?['error'] ?? e.message ?? 'Bağlantı hatası';
      return {'ok': false, 'error': err.toString()};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  Future<KpiData> getKpiData() async {
    syncUserHeader();
    final res = await _dio.get('kpi', queryParameters: {'company': activeCompany});
    if (res.data is Map<String, dynamic>) {
      return KpiData.fromJson(res.data);
    } else if (res.data is Map) {
      return KpiData.fromJson(Map<String, dynamic>.from(res.data));
    }
    throw Exception('Geçersiz KPI yanıtı: ${res.data}');
  }

  Future<List<RecentInvoice>> getRecentInvoices() async {
    syncUserHeader();
    final res = await _dio.get('invoices/recent', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => RecentInvoice.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<RecentWaybill>> getRecentWaybills() async {
    syncUserHeader();
    final res = await _dio.get('waybills/recent', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => RecentWaybill.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<BankAccount>> getBanks() async {
    syncUserHeader();
    final res = await _dio.get('banks', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<BankTransaction>> getBankTransactions(String bankName) async {
    syncUserHeader();
    final res = await _dio.get('banks/${Uri.encodeComponent(bankName)}/transactions', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => BankTransaction.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getGiders() async {
    syncUserHeader();
    final res = await _dio.get('gider', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // Dönüş: null = temiz başarı, boş olmayan String = kayıt Zirve'ye işlendi
  // AMA muhasebe fişi (banka.rs'teki GMHK kontrolüyle aynı) oluşturulamadı —
  // bu uyarı metnini kullanıcıya göstermek çağıranın sorumluluğu.
  Future<String?> createBankTransaction({
    required String operationType,
    required String sourceBank,
    String? targetBank,
    String? cariRef,
    String? cariName,
    required double amount,
    String? description,
    String? expenseItem,
    double? eftFee,
    String? username,
  }) async {
    syncUserHeader();
    try {
      final res = await _dio.post('banks/transaction', data: {
        'company': activeCompany,
        'operationType': operationType,
        'sourceBank': sourceBank,
        'targetBank': targetBank,
        'cariRef': cariRef,
        'cariName': cariName,
        'amount': amount,
        'description': description,
        'expenseItem': expenseItem,
        'eftFee': eftFee,
        'username': username ?? currentUser,
        'kullanici': username ?? currentUser,
      });
      if (res.data != null && res.data['ok'] == true) {
        final warnings = res.data['warnings'];
        if (warnings is List && warnings.isNotEmpty) {
          return warnings.join(' | ');
        }
        return null;
      }
      final err = (res.data is Map) ? res.data['error'] : null;
      throw Exception(err ?? 'Kayıt başarısız oldu.');
    } on DioException catch (e) {
      final data = e.response?.data;
      final err = (data is Map) ? (data['error'] ?? e.message) : e.message;
      throw Exception(err ?? 'Bağlantı hatası');
    }
  }

  Future<List<CariSummary>> getDebtors() async {
    syncUserHeader();
    final res = await _dio.get('cariler/borclular', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => CariSummary.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<CariSummary>> getCreditors() async {
    syncUserHeader();
    final res = await _dio.get('cariler/alacaklilar', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => CariSummary.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<CariSummary>> getAllCaris() async {
    syncUserHeader();
    final res = await _dio.get('cariler/tum', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => CariSummary.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<Baglanti>> getBaglantilar() async {
    syncUserHeader();
    final res = await _dio.get('baglantilar', queryParameters: {'company': activeCompany});
    if (res.data is List) {
      return (res.data as List).map((e) => Baglanti.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  // Tek bir carinin TÜM bağlantılarını ayrı ayrı (gruplanmadan) döner — cari detay ekranı için.
  Future<List<Baglanti>> getBaglantilarForCari(String vergiNo) async {
    syncUserHeader();
    final res = await _dio.get('baglantilar/cari/${Uri.encodeComponent(vergiNo)}', queryParameters: {'company': activeCompany});
    final data = res.data;
    if (data is Map && data['baglantilar'] is List) {
      return (data['baglantilar'] as List).map((e) => Baglanti.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  // FerroxPro (MongoDB) "durum_ozet" koleksiyonundaki net_durum belgesinin kg alanı.
  Future<double> getNetDurum() async {
    syncUserHeader();
    final res = await _dio.get('net-durum');
    final data = res.data;
    if (data is Map && data['kg'] != null) {
      final kg = data['kg'];
      return kg is num ? kg.toDouble() : (double.tryParse(kg.toString()) ?? 0.0);
    }
    return 0.0;
  }

  // Tedarikçi listesi (Zirve CARIGEN, ALICIORSATICI=2) — "Yeni Sipariş" formunda seçim için.
  Future<List<Tedarikci>> getTedarikciler() async {
    syncUserHeader();
    final res = await _dio.get('demir-alislari/tedarikciler', queryParameters: {'company': activeCompany});
    final data = res.data;
    if (data is Map && data['tedarikciler'] is List) {
      return (data['tedarikciler'] as List).map((e) => Tedarikci.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  // Demir Alışları (FerroxPro Atlas -> siparisler / depo_girisleri). Şirket
  // bazlı bir Zirve kavramı değil, net-durum gibi tek ortak Mongo koleksiyonu.
  Future<List<Siparis>> getDemirAlislari() async {
    syncUserHeader();
    final res = await _dio.get('demir-alislari');
    final data = res.data;
    if (data is Map && data['siparisler'] is List) {
      return (data['siparisler'] as List).map((e) => Siparis.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  Future<List<DepoGirisi>> getDepoGirisleri(String siparisId) async {
    syncUserHeader();
    final res = await _dio.get('demir-alislari/${Uri.encodeComponent(siparisId)}/depo-girisleri');
    final data = res.data;
    if (data is Map && data['depoGirisleri'] is List) {
      return (data['depoGirisleri'] as List).map((e) => DepoGirisi.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  // Yeni sipariş oluşturur; SADECE bu alanlar gönderilir (ödeme/fatura/nakliye
  // TUTARI/gizli gibi diğer tüm alanlar mobilden hiç yazılmaz). notMetni ve
  // nakliyeDahil, masaüstünün "Yeni Sipariş" formunda da oluşturma anında
  // toplanan iki alan — sonradan yapılan bir işlem değil.
  Future<void> createSiparis({
    required int tedarikciRef,
    required String tedarikciAd,
    required String siparisTarihi,
    required String bolge,
    required double alimFiyati,
    required double miktarKg,
    required double toplamTutar,
    required String odemeTarihi,
    String? notMetni,
    bool nakliyeDahil = false,
  }) async {
    syncUserHeader();
    final res = await _dio.post('demir-alislari', data: {
      'tedarikciRef': tedarikciRef,
      'tedarikciAd': tedarikciAd,
      'siparisTarihi': siparisTarihi,
      'bolge': bolge,
      'alimFiyati': alimFiyati,
      'miktarKg': miktarKg,
      'toplamTutar': toplamTutar,
      'odemeTarihi': odemeTarihi,
      'notMetni': notMetni,
      'nakliyeDahil': nakliyeDahil,
    });
    if (res.data == null || res.data['ok'] != true) {
      throw Exception(res.data?['error'] ?? 'Sipariş oluşturulamadı.');
    }
  }

  // Plaka atama; SADECE bu 4 alan güncellenir.
  Future<void> assignPlaka({
    required String siparisId,
    required String plaka,
    required String isimSoyisim,
    required String tcNo,
    required String cap,
  }) async {
    syncUserHeader();
    final res = await _dio.post('demir-alislari/${Uri.encodeComponent(siparisId)}/plaka', data: {
      'plaka': plaka,
      'isimSoyisim': isimSoyisim,
      'tcNo': tcNo,
      'cap': cap,
    });
    if (res.data == null || res.data['ok'] != true) {
      throw Exception(res.data?['error'] ?? 'Plaka ataması yapılamadı.');
    }
  }

  // WhatsApp paylaşım penceresi açıldıktan sonra tek bir alanı ($set) işaretler.
  // Masaüstü uygulamayla aynı sözleşme: bu alana gönderilen PLAKANIN KENDİSİ
  // yazılır (zaman damgası değil) — "aynı plaka tekrar gönderilmesin" kontrolü buna göre yapılıyor.
  Future<void> markPlakaWhatsappGonderildi(String siparisId, String plaka) async {
    syncUserHeader();
    await _dio.post('demir-alislari/${Uri.encodeComponent(siparisId)}/whatsapp-gonderildi', data: {'plaka': plaka});
  }

  Future<bool> hideBank(String bankName) async {
    syncUserHeader();
    final res = await _dio.post('banks/${Uri.encodeComponent(bankName)}/hide', data: {'company': activeCompany});
    return res.data != null && res.data['ok'] == true;
  }

  Future<bool> unhideBank(String bankName) async {
    syncUserHeader();
    final res = await _dio.post('banks/${Uri.encodeComponent(bankName)}/unhide', data: {'company': activeCompany});
    return res.data != null && res.data['ok'] == true;
  }

  Future<Map<String, dynamic>> getFaturaDetail(String evrakno) async {
    syncUserHeader();
    final res = await _dio.get('fatura/${Uri.encodeComponent(evrakno)}', queryParameters: {'company': activeCompany});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getIrsaliyeDetail(String evrakno) async {
    syncUserHeader();
    final res = await _dio.get('irsaliye/${Uri.encodeComponent(evrakno)}', queryParameters: {'company': activeCompany});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Uint8List> getDocumentPdf(String type, String evrakno) async {
    syncUserHeader();
    final endpoint = type == 'fatura' ? 'fatura/pdf/' : 'irsaliye/pdf/';
    final res = await _dio.get(
      '$endpoint${Uri.encodeComponent(evrakno)}',
      queryParameters: {'company': activeCompany},
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return Uint8List.fromList(res.data);
  }

  // Dönüş: null = temiz başarı, boş olmayan String = POS kaydı Zirve'ye
  // işlendi AMA muhasebe fişi (GMHK kontrolü) oluşturulamadı. Kayıt
  // başarısız olursa (ok:false / ağ hatası) Exception fırlatır.
  Future<String?> createPosTahsilat({
    required String bankName,
    required String cariName,
    String? cariRef,
    required double amount,
    String? description,
    DateTime? date,
    String? username,
  }) async {
    syncUserHeader();
    try {
      final res = await _dio.post('pos-tahsilat', data: {
        'company': activeCompany,
        'bankName': bankName,
        'cariName': cariName,
        'cariRef': cariRef,
        'amount': amount,
        'description': description,
        'date': date?.toIso8601String(),
        'username': username ?? currentUser,
        'kullanici': username ?? currentUser,
      });
      if (res.data == null || res.data['ok'] != true) {
        final err = (res.data is Map) ? res.data['error'] : null;
        throw Exception(err ?? 'POS kaydı başarısız oldu.');
      }
      final warning = res.data['warning'];
      return (warning is String && warning.isNotEmpty) ? warning : null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final err = (data is Map) ? (data['error'] ?? e.message) : e.message;
      throw Exception(err ?? 'Bağlantı hatası');
    }
  }

  // Banka e-postalarından okunan, onay bekleyen (ve son onaylanmış) işlemler.
  Future<Map<String, dynamic>> getPendingEmails() async {
    syncUserHeader();
    final res = await _dio.get('emails/pending', queryParameters: {'company': activeCompany});
    final data = res.data;
    if (data is Map) {
      final pendingRaw = (data['pending'] as List?) ?? [];
      final approvedRaw = (data['approved'] as List?) ?? [];
      final cariRaw = (data['cariOptions'] as List?) ?? [];
      final bankRaw = (data['bankOptions'] as List?) ?? [];
      return {
        'pending': pendingRaw.map((e) => PendingEmail.fromJson(Map<String, dynamic>.from(e))).toList(),
        'approved': approvedRaw.map((e) => ApprovedEmail.fromJson(Map<String, dynamic>.from(e))).toList(),
        'cariOptions': cariRaw.map((e) => e.toString()).toList(),
        'bankOptions': bankRaw.map((e) => e.toString()).toList(),
      };
    }
    return {
      'pending': <PendingEmail>[],
      'approved': <ApprovedEmail>[],
      'cariOptions': <String>[],
      'bankOptions': <String>[],
    };
  }

  // Gelen kutusunu tarayıp yeni banka dekontu e-postalarını onay havuzuna ekler.
  Future<int> fetchNewEmails() async {
    syncUserHeader();
    try {
      final res = await _dio.post('emails/fetch', data: {'company': activeCompany});
      final data = res.data;
      if (data is Map && data['inserted'] != null) {
        final v = data['inserted'];
        return v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      final data = e.response?.data;
      final err = (data is Map) ? (data['error'] ?? e.message) : e.message;
      throw Exception(err ?? 'Bağlantı hatası');
    }
  }

  // Seçilen bekleyen e-posta işlemlerini Zirve'ye işler.
  // items: { id: { 'cariName': ..., 'bankName': ..., 'eftFee': ... } }
  // Dönüş: null = temiz başarı, boş olmayan String = kayıtlar Zirve'ye
  // işlendi AMA en az birinin muhasebe fişi (GMHK kontrolü) oluşturulamadı.
  Future<String?> approveEmails(List<String> ids, Map<String, Map<String, String>> items) async {
    syncUserHeader();
    try {
      final res = await _dio.post('emails/approve', data: {
        'company': activeCompany,
        'ids': ids,
        'items': items,
        'username': currentUser,
      });
      if (res.data == null || res.data['ok'] != true) {
        final err = (res.data is Map) ? res.data['error'] : null;
        throw Exception(err ?? 'Onaylama başarısız oldu.');
      }
      final warnings = res.data['warnings'];
      if (warnings is List && warnings.isNotEmpty) {
        return warnings.join(' | ');
      }
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final err = (data is Map) ? (data['error'] ?? e.message) : e.message;
      throw Exception(err ?? 'Bağlantı hatası');
    }
  }

  Future<void> deleteEmails(List<String> ids) async {
    syncUserHeader();
    try {
      final res = await _dio.post('emails/delete', data: {
        'company': activeCompany,
        'ids': ids,
      });
      if (res.data == null || res.data['ok'] != true) {
        final err = (res.data is Map) ? res.data['error'] : null;
        throw Exception(err ?? 'Silme başarısız oldu.');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final err = (data is Map) ? (data['error'] ?? e.message) : e.message;
      throw Exception(err ?? 'Bağlantı hatası');
    }
  }

  Future<bool> deleteBankTransaction(dynamic ref) async {
    syncUserHeader();
    final res = await _dio.post('banks/transactions/$ref/delete', data: {
      'company': activeCompany,
    });
    return res.data != null && res.data['ok'] == true;
  }
}
