class BankAccount {
  final String name;
  final String? subtitle;
  final double balance;
  final String? type;
  final bool hidden;
  final String category; // 'main' or 'other'

  BankAccount({
    required this.name,
    this.subtitle,
    required this.balance,
    this.type,
    this.hidden = false,
    this.category = 'main',
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      name: json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      type: json['type'] ?? 'hesap',
      hidden: json['hidden'] ?? false,
      category: json['category'] ?? 'main',
    );
  }
}

class BankTransaction {
  final int? zirveRef;
  final DateTime date;
  final String cariName;
  final String description;
  final double amount;
  final String category; // 'gelir' (yeşil) or 'gider' (kırmızı)
  final String operationType;

  BankTransaction({
    this.zirveRef,
    required this.date,
    required this.cariName,
    required this.description,
    required this.amount,
    required this.category,
    required this.operationType,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      zirveRef: json['zirveRef'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      cariName: json['cariName'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'gelir',
      operationType: json['operationType'] ?? 'cari',
    );
  }
}
