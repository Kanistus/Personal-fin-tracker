class Budget {
  final int? id;
  final String category;
  final double limit;
  final String month; // "2026-07" format

  Budget({
    this.id,
    required this.category,
    required this.limit,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budgetLimit': limit,
      'month': month,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      limit: (map['budgetLimit'] as num).toDouble(),
      month: map['month'] as String,
    );
  }

  Budget copyWith({double? limit}) {
    return Budget(
      id: id,
      category: category,
      limit: limit ?? this.limit,
      month: month,
    );
  }
}
