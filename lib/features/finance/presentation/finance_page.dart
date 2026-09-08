import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/finance_models.dart';
import '../data/finance_repository.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _repo = FinanceRepository(Supabase.instance.client);
  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  List<FinanceTransaction> _items = [];
  FinanceSummary? _summary;
  bool _loading = true;
  String? _type;
  String _error = '';

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final items = await _repo.listTransactions(type: _type);
      final summary = await _repo.summary();
      if (mounted) setState(() { _items = items; _summary = summary; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _loading = false; }); }
  }

  Future<void> _add() async {
    final result = await showDialog<bool>(context: context, builder: (_) => _TransactionDialog(repo: _repo));
    if (result == true) _load();
  }

  @override Widget build(BuildContext context) {
    final s = _summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Farm Finance')), 
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Transaction')),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [Expanded(child: Text('Financial overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))), IconButton(onPressed: () => context.push('/finance/analytics'), icon: const Icon(Icons.insights_rounded), tooltip: 'Analytics')]),
        const SizedBox(height: 16),
        if (s != null) Row(children: [_StatCard(label: 'Profit', value: _money.format(s.net), icon: Icons.trending_up_rounded), const SizedBox(width: 10), _StatCard(label: 'Income', value: _money.format(s.income), icon: Icons.south_west_rounded), const SizedBox(width: 10), _StatCard(label: 'Expense', value: _money.format(s.expense), icon: Icons.north_east_rounded)]),
        const SizedBox(height: 18),
        SegmentedButton<String?>(segments: const [ButtonSegment<String?>(value: null, label: Text('All')), ButtonSegment<String?>(value: 'income', label: Text('Income')), ButtonSegment<String?>(value: 'expense', label: Text('Expense'))], selected: {_type}, onSelectionChanged: (v) { setState(() => _type = v.first); _load(); }),
        const SizedBox(height: 18),
        if (_error.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error))),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else if (_items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [Icon(Icons.receipt_long_rounded, size: 44), SizedBox(height: 10), Text('No transactions yet', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 5), Text('Add your first income or expense to start tracking farm profitability.')])) )
        else ..._items.map((tx) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: CircleAvatar(child: Icon(tx.type == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded)), title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${DateFormat('dd MMM yyyy').format(tx.transactionDate)}${tx.vendorBuyer == null ? '' : ' • ${tx.vendorBuyer}'}'), trailing: Text('${tx.type == 'income' ? '+' : '-'}${_money.format(tx.amount)}', style: const TextStyle(fontWeight: FontWeight.w800)), onLongPress: () async { await _repo.deleteTransaction(tx.id); _load(); })) ,),
        const SizedBox(height: 90),
      ])),
    );
  }
}

class _StatCard extends StatelessWidget { const _StatCard({required this.label, required this.value, required this.icon}); final String label, value; final IconData icon; @override Widget build(BuildContext c) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20), const SizedBox(height: 8), Text(label, style: Theme.of(c).textTheme.bodySmall), const SizedBox(height: 3), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))])))); }

class _TransactionDialog extends StatefulWidget { const _TransactionDialog({required this.repo}); final FinanceRepository repo; @override State<_TransactionDialog> createState() => _TransactionDialogState(); }
class _TransactionDialogState extends State<_TransactionDialog> {
  final _form = GlobalKey<FormState>(); final _amount = TextEditingController(); final _category = TextEditingController(); final _description = TextEditingController(); final _party = TextEditingController();
  String _type = 'expense'; DateTime _date = DateTime.now(); bool _saving = false;
  @override void dispose() { _amount.dispose(); _category.dispose(); _description.dispose(); _party.dispose(); super.dispose(); }
  Future<void> _save() async { if (!_form.currentState!.validate()) return; setState(() => _saving = true); try { await widget.repo.createTransaction(type: _type, category: _category.text, amount: double.parse(_amount.text), date: _date, description: _description.text, vendorBuyer: _party.text); if (mounted) Navigator.pop(context, true); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } finally { if (mounted) setState(() => _saving = false); } }
  @override Widget build(BuildContext context) => AlertDialog(title: const Text('Add transaction'), content: SingleChildScrollView(child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(value: _type, items: const [DropdownMenuItem(value: 'expense', child: Text('Expense')), DropdownMenuItem(value: 'income', child: Text('Income'))], onChanged: (v) => setState(() => _type = v!), decoration: const InputDecoration(labelText: 'Type')), TextFormField(controller: _category, decoration: const InputDecoration(labelText: 'Category', hintText: 'Seeds, fertilizer, sale...'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null), TextFormField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)'), validator: (v) => double.tryParse(v ?? '') == null || double.parse(v!) <= 0 ? 'Enter a valid amount' : null), TextFormField(controller: _party, decoration: const InputDecoration(labelText: 'Vendor / buyer')), TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description')), ListTile(contentPadding: EdgeInsets.zero, title: Text(DateFormat('dd MMM yyyy').format(_date)), trailing: const Icon(Icons.calendar_month_rounded), onTap: () async { final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1)), initialDate: _date); if (d != null) setState(() => _date = d); })])), actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'))]);
}
