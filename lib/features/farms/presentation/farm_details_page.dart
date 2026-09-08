import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/farm_models.dart';
import '../data/farm_repository.dart';

final fieldsProvider = FutureProvider.autoDispose.family<List<Field>, String>((ref, farmId) => FieldRepository(Supabase.instance.client).listFields(farmId));

class FarmDetailsPage extends ConsumerWidget {
  const FarmDetailsPage({super.key, required this.farmId, required this.farmName});
  final String farmId;
  final String farmName;

  Future<void> _addField(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final area = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Add field'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Field name')), TextField(controller: area, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Area (acres)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty || double.tryParse(area.text) == null) return; await FieldRepository(Supabase.instance.client).createField(farmId: farmId, name: name.text, areaAcres: double.parse(area.text)); if (context.mounted) Navigator.pop(context, true); }, child: const Text('Save'))]));
    name.dispose(); area.dispose();
    if (result == true) ref.invalidate(fieldsProvider(farmId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(fieldsProvider(farmId));
    return Scaffold(appBar: AppBar(title: Text(farmName)), floatingActionButton: FloatingActionButton.extended(onPressed: () => _addField(context, ref), icon: const Icon(Icons.add), label: const Text('Add field')), body: fields.when(loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('Could not load fields\n$e')), data: (items) => items.isEmpty ? const Center(child: Text('No fields yet. Add a field to start crop planning.')) : ListView.separated(padding: const EdgeInsets.all(20), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) { final f = items[i]; return Card(child: ListTile(leading: const Icon(Icons.crop_square_rounded), title: Text(f.name), subtitle: Text('${f.areaAcres.toStringAsFixed(1)} acres${f.soilType == null ? '' : ' • ${f.soilType}'}'), trailing: const Icon(Icons.chevron_right))); })));
  }
}
