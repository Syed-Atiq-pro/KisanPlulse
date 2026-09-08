class FinanceTransaction {
  const FinanceTransaction({required this.id, required this.userId, this.farmId, this.fieldId, this.cropId, required this.type, required this.category, required this.amount, required this.transactionDate, this.description, this.paymentMethod, this.vendorBuyer, this.reference, required this.createdAt, required this.updatedAt});
  final String id;
  final String userId;
  final String? farmId;
  final String? fieldId;
  final String? cropId;
  final String type;
  final String category;
  final double amount;
  final DateTime transactionDate;
  final String? description;
  final String? paymentMethod;
  final String? vendorBuyer;
  final String? reference;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory FinanceTransaction.fromMap(Map<String, dynamic> m) => FinanceTransaction(
    id: m['id'] as String,
    userId: m['user_id'] as String,
    farmId: m['farm_id'] as String?,
    fieldId: m['field_id'] as String?,
    cropId: m['crop_id'] as String?,
    type: m['type'] as String,
    category: m['category'] as String,
    amount: (m['amount'] as num).toDouble(),
    transactionDate: DateTime.parse(m['transaction_date'] as String),
    description: m['description'] as String?,
    paymentMethod: m['payment_method'] as String?,
    vendorBuyer: m['vendor_buyer'] as String?,
    reference: m['reference'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String),
    updatedAt: DateTime.parse(m['updated_at'] as String),
  );
}

class FarmBudget {
  const FarmBudget({required this.id, required this.userId, this.farmId, required this.year, this.month, required this.category, required this.amount, this.notes});
  final String id;
  final String userId;
  final String? farmId;
  final int year;
  final int? month;
  final String category;
  final double amount;
  final String? notes;

  factory FarmBudget.fromMap(Map<String, dynamic> m) => FarmBudget(id: m['id'] as String, userId: m['user_id'] as String, farmId: m['farm_id'] as String?, year: m['year'] as int, month: m['month'] as int?, category: m['category'] as String, amount: (m['amount'] as num).toDouble(), notes: m['notes'] as String?);
}

class FinanceSummary {
  const FinanceSummary({required this.income, required this.expense, required this.transactionCount}) : net = income - expense;
  final double income;
  final double expense;
  final int transactionCount;
  final double net;
}
