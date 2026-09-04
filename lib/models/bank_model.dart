class BankAccount {
  final String name;
  final String? subtitle;
  final double balance;
  final String? type;
  final bool hidden;
  final String category;
  final String branch;
  final String iban;
  final String accountType;

  // Aliases for perfect compatibility across all screens
  String get bankName => name;
  double get bakiye => balance;

  BankAccount({
    required this.name,
    this.subtitle,
    required this.balance,
    this.type,
    this.hidden = false,
    this.category = 'main',
    this.branch = '',
    this.iban = '',
    this.accountType = 'Vadesiz',
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    final bName = json['bankName'] ?? json['name'] ?? json['BANKAADI'] ?? '';
    final bBal = (json['bakiye'] ?? json['balance'] ?? json['STGT'] ?? 0).toDouble();
    final bBranch = json['branch'] ?? json['subtitle'] ?? json['SUBESI'] ?? '';
    final bIban = json['iban'] ?? json['IBAN'] ?? '';
    final bType = json['accountType'] ?? json['type'] ?? json['HESAPTIPI'] ?? 'Vadesiz';
    final bHidden = json['hidden'] ?? false;

    return BankAccount(
      name: bName.toString(),
      subtitle: bBranch.toString(),
      balance: bBal,
      type: bType.toString(),
      hidden: bHidden == true,
      category: json['category'] ?? 'main',
      branch: bBranch.toString(),
      iban: bIban.toString(),
      accountType: bType.toString(),
    );
  }
}

class BankTransaction {
  final int? zirveRef;
  final DateTime date;
  final String cariName;
  final String description;
  final double amount;
  final String category;
  final String operationType;
  final double borc;
  final double alacak;

  // Aliases
  DateTime get tarih => date;
  String get aciklama => description;

  BankTransaction({
    this.zirveRef,
    required this.date,
    required this.cariName,
    required this.description,
    required this.amount,
    required this.category,
    required this.operationType,
    this.borc = 0.0,
    this.alacak = 0.0,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    final dateVal = json['tarih'] ?? json['date'] ?? json['TARIH'];
    DateTime dt = DateTime.now();
    if (dateVal != null) {
      try {
        dt = DateTime.parse(dateVal.toString());
      } catch (_) {}
    }

    final bAmount = (json['tutar'] ?? json['amount'] ?? json['TUTAR'] ?? 0).toDouble();
    final bBorc = (json['borc'] ?? json['BORC'] ?? 0).toDouble();
    final bAlacak = (json['alacak'] ?? json['ALACAK'] ?? 0).toDouble();
    final desc = (json['aciklama'] ?? json['description'] ?? json['ACIKLAMA'] ?? '').toString();
    final cName = (json['cariName'] ?? json['CARI_AD'] ?? json['CARIADI'] ?? '').toString();

    return BankTransaction(
      zirveRef: json['zirveRef'] ?? json['HAREKETREF'],
      date: dt,
      cariName: cName,
      description: desc,
      amount: bAmount > 0 ? bAmount : (bBorc > 0 ? bBorc : bAlacak),
      category: bBorc > 0 ? 'gelir' : 'gider',
      operationType: json['operationType'] ?? 'cari',
      borc: bBorc,
      alacak: bAlacak,
    );
  }
}
