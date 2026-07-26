class DebtSettlement {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;
  final String note;

  DebtSettlement({
    this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtSettlement.fromMap(Map<String, dynamic> map) {
    return DebtSettlement(
      id: map['id'] as int?,
      debtId: map['debtId'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }
}
