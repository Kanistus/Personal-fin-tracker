class Transaction {
  final int? id;
  final String title;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isIncome': isIncome ? 1 : 0,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      isIncome: (map['isIncome'] as int) == 1,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    bool? isIncome,
    String? category,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}
