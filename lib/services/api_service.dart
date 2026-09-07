import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/kpi_model.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../models/baglanti_model.dart';
import '../models/fatura_irsaliye_model.dart';

class ApiService {
  static String currentUser = '';
  static bool isAdmin = false;
  static List<String> allowedOperations = [];
  static bool get isLoggedIn => currentUser.trim().isNotEmpty;

  static void setUser(String username, {bool admin = false, List<String>? ops}) {
    currentUser = username.trim();
    isAdmin = admin;
    allowedOperations = ops ?? [];
  }

  static void logout() {
    currentUser = '';
    isAdmin = false;
    allowedOperations = [];
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

  Future<bool> createBankTransaction({
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
    return res.data != null && res.data['ok'] == true;
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

  Future<bool> createPosTahsilat({
    required String bankName,
    required String cariName,
    String? cariRef,
    required double amount,
    String? description,
    DateTime? date,
    String? username,
  }) async {
    syncUserHeader();
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
    return res.data != null && res.data['ok'] == true;
  }

  Future<bool> deleteBankTransaction(dynamic ref) async {
    syncUserHeader();
    final res = await _dio.post('banks/transactions/$ref/delete', data: {
      'company': activeCompany,
    });
    return res.data != null && res.data['ok'] == true;
  }
}
