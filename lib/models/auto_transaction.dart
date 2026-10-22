/// Represents an automatically detected transaction from a payment notification.
class AutoTransaction {
  final int? id;
  final double amount;
  final String merchant;
  final String rawNotification;
  final String sourceApp;
  final String transactionType; // expense, income, transfer, refund, withdrawal, loan_payment
  final String category;
  final String confidence; // high, medium, low
  final String status; // auto_saved, pending_review, confirmed, rejected, duplicate
  final String? upiRef;
  final DateTime date;
  final int? linkedTransactionId;
  final String? duplicateGroupId;
  final DateTime createdAt;

  AutoTransaction({
    this.id,
    required this.amount,
    required this.merchant,
    this.rawNotification = '',
    required this.sourceApp,
    this.transactionType = 'expense',
    this.category = 'Other',
    this.confidence = 'low',
    this.status = 'pending_review',
    this.upiRef,
    required this.date,
    this.linkedTransactionId,
    this.duplicateGroupId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'merchant': merchant,
      'rawNotification': rawNotification,
      'sourceApp': sourceApp,
      'transactionType': transactionType,
      'category': category,
      'confidence': confidence,
      'status': status,
      'upiRef': upiRef,
      'date': date.toIso8601String(),
      'linkedTransactionId': linkedTransactionId,
      'duplicateGroupId': duplicateGroupId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AutoTransaction.fromMap(Map<String, dynamic> map) {
    return AutoTransaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      merchant: map['merchant'] as String? ?? '',
      rawNotification: map['rawNotification'] as String? ?? '',
      sourceApp: map['sourceApp'] as String? ?? '',
      transactionType: map['transactionType'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Other',
      confidence: map['confidence'] as String? ?? 'low',
      status: map['status'] as String? ?? 'pending_review',
      upiRef: map['upiRef'] as String?,
      date: DateTime.parse(map['date'] as String),
      linkedTransactionId: map['linkedTransactionId'] as int?,
      duplicateGroupId: map['duplicateGroupId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AutoTransaction copyWith({
    int? id,
    double? amount,
    String? merchant,
    String? rawNotification,
    String? sourceApp,
    String? transactionType,
    String? category,
    String? confidence,
    String? status,
    String? upiRef,
    DateTime? date,
    int? linkedTransactionId,
    String? duplicateGroupId,
  }) {
    return AutoTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      rawNotification: rawNotification ?? this.rawNotification,
      sourceApp: sourceApp ?? this.sourceApp,
      transactionType: transactionType ?? this.transactionType,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      upiRef: upiRef ?? this.upiRef,
      date: date ?? this.date,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      duplicateGroupId: duplicateGroupId ?? this.duplicateGroupId,
      createdAt: createdAt,
    );
  }
}
