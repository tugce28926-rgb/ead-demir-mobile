import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/kpi_model.dart';
import '../models/bank_model.dart';
import '../models/cari_model.dart';
import '../models/baglanti_model.dart';
import '../models/fatura_irsaliye_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  String activeCompany = AppConstants.defaultCompany;

  void setCompany(String companyDb) {
    activeCompany = companyDb;
    _dio.options.headers['X-Company-Db'] = companyDb;
  }

  Future<KpiData> getKpiData() async {
    final res = await _dio.get('/kpi', queryParameters: {'company': activeCompany});
    return KpiData.fromJson(res.data);
  }

  Future<List<RecentInvoice>> getRecentInvoices() async {
    final res = await _dio.get('/invoices/recent', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => RecentInvoice.fromJson(e)).toList();
  }

  Future<List<RecentWaybill>> getRecentWaybills() async {
    final res = await _dio.get('/waybills/recent', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => RecentWaybill.fromJson(e)).toList();
  }

  Future<List<BankAccount>> getBanks() async {
    final res = await _dio.get('/banks', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => BankAccount.fromJson(e)).toList();
  }

  Future<List<BankTransaction>> getBankTransactions(String bankName) async {
    final res = await _dio.get('/banks/${Uri.encodeComponent(bankName)}/transactions', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => BankTransaction.fromJson(e)).toList();
  }

  Future<bool> createBankTransaction({
    required String operationType,
    required String sourceBank,
    String? targetBank,
    String? cariRef,
    String? cariName,
    required double amount,
    String? description,
  }) async {
    final res = await _dio.post('/banks/transaction', data: {
      'company': activeCompany,
      'operationType': operationType,
      'sourceBank': sourceBank,
      'targetBank': targetBank,
      'cariRef': cariRef,
      'cariName': cariName,
      'amount': amount,
      'description': description,
    });
    return res.data['ok'] == true;
  }

  Future<List<CariSummary>> getDebtors() async {
    final res = await _dio.get('/cariler/borclular', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => CariSummary.fromJson(e)).toList();
  }

  Future<List<CariSummary>> getCreditors() async {
    final res = await _dio.get('/cariler/alacaklilar', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => CariSummary.fromJson(e)).toList();
  }

  Future<List<CariSummary>> getAllCaris() async {
    final res = await _dio.get('/cariler/tum', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => CariSummary.fromJson(e)).toList();
  }

  Future<List<Baglanti>> getBaglantilar() async {
    final res = await _dio.get('/baglantilar', queryParameters: {'company': activeCompany});
    return (res.data as List).map((e) => Baglanti.fromJson(e)).toList();
  }

  Future<bool> hideBank(String bankName) async {
    final res = await _dio.post('/banks/${Uri.encodeComponent(bankName)}/hide', data: {'company': activeCompany});
    return res.data['ok'] == true;
  }

  Future<bool> unhideBank(String bankName) async {
    final res = await _dio.post('/banks/${Uri.encodeComponent(bankName)}/unhide', data: {'company': activeCompany});
    return res.data['ok'] == true;
  }
}
