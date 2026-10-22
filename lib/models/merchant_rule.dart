/// Stores user-corrected merchant-to-category mappings.
/// When a user corrects a category for a merchant, that preference
/// is saved here and used for future auto-categorization.
class MerchantRule {
  final int? id;
  final String merchantPattern; // Normalized merchant name/pattern
  final String category;
  final String transactionType; // expense, income, transfer
  final DateTime createdAt;
  final DateTime updatedAt;

  MerchantRule({
    this.id,
    required this.merchantPattern,
    required this.category,
    this.transactionType = 'expense',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantPattern': merchantPattern,
      'category': category,
      'transactionType': transactionType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MerchantRule.fromMap(Map<String, dynamic> map) {
    return MerchantRule(
      id: map['id'] as int?,
      merchantPattern: map['merchantPattern'] as String,
      category: map['category'] as String,
      transactionType: map['transactionType'] as String? ?? 'expense',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  MerchantRule copyWith({
    String? category,
    String? transactionType,
  }) {
    return MerchantRule(
      id: id,
      merchantPattern: merchantPattern,
      category: category ?? this.category,
      transactionType: transactionType ?? this.transactionType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
