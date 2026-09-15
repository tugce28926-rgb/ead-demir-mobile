DateTime _parseEmailDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  try {
    return DateTime.parse(raw.toString());
  } catch (_) {
    return DateTime.now();
  }
}

class PendingEmail {
  final String id;
  final String operationType; // gelen-havale, giden-havale, virman
  final String? originalType;
  final String senderName;
  final String description;
  final String bankName;
  final String? targetBankName;
  final double amount;
  final double embeddedMasraf;
  final DateTime date;
  final String suggestedBank;
  final String suggestedCari;

  PendingEmail({
    required this.id,
    required this.operationType,
    this.originalType,
    required this.senderName,
    required this.description,
    required this.bankName,
    this.targetBankName,
    required this.amount,
    required this.embeddedMasraf,
    required this.date,
    required this.suggestedBank,
    required this.suggestedCari,
  });

  factory PendingEmail.fromJson(Map<String, dynamic> json) {
    return PendingEmail(
      id: (json['_id'] ?? '').toString(),
      operationType: (json['operationType'] ?? '').toString(),
      originalType: json['originalType']?.toString(),
      senderName: (json['senderName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      bankName: (json['bankName'] ?? '').toString(),
      targetBankName: json['targetBankName']?.toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse('${json['amount']}') ?? 0.0,
      embeddedMasraf: (json['embeddedMasraf'] is num) ? (json['embeddedMasraf'] as num).toDouble() : double.tryParse('${json['embeddedMasraf']}') ?? 0.0,
      date: _parseEmailDate(json['date'] ?? json['createdAt']),
      suggestedBank: (json['suggestedBank'] ?? '').toString(),
      suggestedCari: (json['suggestedCari'] ?? '').toString(),
    );
  }

  bool get isVirman => operationType == 'virman';
  bool get isGelir => operationType == 'gelen-havale' || originalType == 'gelen-havale';
}

class ApprovedEmail {
  final DateTime date;
  final String bankName;
  final String? targetBankName;
  final String operationType;
  final String senderName;
  final String description;
  final double amount;

  ApprovedEmail({
    required this.date,
    required this.bankName,
    this.targetBankName,
    required this.operationType,
    required this.senderName,
    required this.description,
    required this.amount,
  });

  factory ApprovedEmail.fromJson(Map<String, dynamic> json) {
    return ApprovedEmail(
      date: _parseEmailDate(json['date'] ?? json['createdAt']),
      bankName: (json['bankName'] ?? '').toString(),
      targetBankName: json['targetBankName']?.toString(),
      operationType: (json['operationType'] ?? '').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.tryParse('${json['amount']}') ?? 0.0,
    );
  }
}
