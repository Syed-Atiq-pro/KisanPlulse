import 'package:supabase_flutter/supabase_flutter.dart';
import 'finance_models.dart';

class FinanceRepository {
  FinanceRepository(this.client);
  final SupabaseClient client;

  String get _userId => client.auth.currentUser!.id;

  Future<List<FinanceTransaction>> listTransactions({String? type, DateTime? from, DateTime? to}) async {
    var query = client.from('finance_transactions').select('id,user_id,farm_id,field_id,crop_id,type,category,amount,transaction_date,description,payment_method,vendor_buyer,reference,created_at,updated_at').eq('user_id', _userId);
    if (type != null) query = query.eq('type', type);
    if (from != null) query = query.gte('transaction_date', from.toIso8601String().split('T').first);
    if (to != null) query = query.lte('transaction_date', to.toIso8601String().split('T').first);
    final rows = await query.order('transaction_date', ascending: false).limit(500);
    return (rows as List).map((r) => FinanceTransaction.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  Future<FinanceTransaction> createTransaction({required String type, required String category, required double amount, DateTime? date, String? description, String? paymentMethod, String? vendorBuyer, String? reference, String? farmId, String? fieldId, String? cropId}) async {
    final row = await client.from('finance_transactions').insert({'user_id': _userId, 'type': type, 'category': category.trim(), 'amount': amount, 'transaction_date': (date ?? DateTime.now()).toIso8601String().split('T').first, 'description': description?.trim().isEmpty == true ? null : description?.trim(), 'payment_method': paymentMethod, 'vendor_buyer': vendorBuyer?.trim().isEmpty == true ? null : vendorBuyer?.trim(), 'reference': reference?.trim().isEmpty == true ? null : reference?.trim(), 'farm_id': farmId, 'field_id': fieldId, 'crop_id': cropId}).select('id,user_id,farm_id,field_id,crop_id,type,category,amount,transaction_date,description,payment_method,vendor_buyer,reference,created_at,updated_at').single();
    return FinanceTransaction.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteTransaction(String id) async {
    await client.from('finance_transactions').delete().eq('id', id).eq('user_id', _userId);
  }

  Future<FinanceSummary> summary({DateTime? from, DateTime? to}) async {
    final rows = await listTransactions(from: from, to: to);
    var income = 0.0;
    var expense = 0.0;
    for (final tx in rows) {
      if (tx.type == 'income') income += tx.amount; else expense += tx.amount;
    }
    return FinanceSummary(income: income, expense: expense, transactionCount: rows.length);
  }

  Future<List<FarmBudget>> listBudgets({String? farmId, int? year}) async {
    var query = client.from('farm_budgets').select('id,user_id,farm_id,year,month,category,amount,notes').eq('user_id', _userId);
    if (farmId != null) query = query.eq('farm_id', farmId);
    if (year != null) query = query.eq('year', year);
    final rows = await query.order('year', ascending: false).order('month', ascending: false);
    return (rows as List).map((r) => FarmBudget.fromMap(Map<String, dynamic>.from(r))).toList();
  }
}
