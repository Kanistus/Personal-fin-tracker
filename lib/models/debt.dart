class Debt {
  final int? id;
  final String personName;
  final double totalAmount;
  final double paidAmount;
  final bool isOwedToMe; // true = someone owes me, false = I owe someone
  final String description;
  final DateTime? dueDate;
  final DateTime createdDate;

  Debt({
    this.id,
    required this.personName,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.isOwedToMe,
    required this.description,
    this.dueDate,
    required this.createdDate,
  });

  double get remainingAmount => totalAmount - paidAmount;
  bool get isFullyPaid => paidAmount >= totalAmount;
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'isOwedToMe': isOwedToMe ? 1 : 0,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      personName: map['personName'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num).toDouble(),
      isOwedToMe: (map['isOwedToMe'] as int) == 1,
      description: map['description'] as String,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      createdDate: DateTime.parse(map['createdDate'] as String),
    );
  }

  Debt copyWith({
    double? paidAmount,
    double? totalAmount,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Debt(
      id: id,
      personName: personName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      isOwedToMe: isOwedToMe,
      description: description,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdDate: createdDate,
    );
  }
}
