import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final soil = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Add field'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Field name')), TextField(controller: area, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Area (acres)')), TextField(controller: soil, decoration: const InputDecoration(labelText: 'Soil type (optional)'))]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async { final acres = double.tryParse(area.text); if (name.text.trim().isEmpty || acres == null || acres <= 0) return; await FieldRepository(Supabase.instance.client).createField(farmId: farmId, name: name.text, areaAcres: acres, soilType: soil.text); if (dialogContext.mounted) Navigator.pop(dialogContext, true); }, child: const Text('Save'))],
    ));
    name.dispose(); area.dispose(); soil.dispose();
    if (result == true) ref.invalidate(fieldsProvider(farmId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fields = ref.watch(fieldsProvider(farmId));
    return Scaffold(
      appBar: AppBar(title: Text(farmName)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addField(context, ref), icon: const Icon(Icons.add), label: const Text('Add field')),
      body: RefreshIndicator(onRefresh: () async => ref.invalidate(fieldsProvider(farmId)), child: fields.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 12), const Text('Could not load fields'), TextButton(onPressed: () => ref.invalidate(fieldsProvider(farmId)), child: const Text('Retry'))]))),
        data: (items) => items.isEmpty ? const Center(child: Text('No fields yet. Add a field to start crop planning.')) : ListView.separated(padding: const EdgeInsets.all(20), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) { final f = items[i]; return Card(child: ListTile(onTap: () => context.push('/farms/$farmId/fields/${f.id}?name=${Uri.encodeComponent(f.name)}&area=${f.areaAcres}'), leading: const Icon(Icons.crop_square_rounded), title: Text(f.name), subtitle: Text('${f.areaAcres.toStringAsFixed(1)} acres${f.soilType == null ? '' : ' • ${f.soilType}'}'), trailing: const Icon(Icons.chevron_right))); }),
      )),
    );
  }
}
