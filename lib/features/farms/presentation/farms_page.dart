import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/farm_models.dart';
import '../data/farm_repository.dart';

final farmRepositoryProvider = Provider((ref) => FarmRepository(Supabase.instance.client));
final farmsProvider = FutureProvider.autoDispose<List<Farm>>((ref) => ref.read(farmRepositoryProvider).listFarms());

class FarmsPage extends ConsumerWidget {
  const FarmsPage({super.key});

  Future<void> _addFarm(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final area = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Add farm'),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Farm name'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
        TextFormField(controller: area, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Area (acres)'), validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a valid number' : null),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () async { if (!(formKey.currentState?.validate() ?? false)) return; await ref.read(farmRepositoryProvider).createFarm(name: name.text, areaAcres: double.parse(area.text)); if (context.mounted) Navigator.pop(context, true); }, child: const Text('Save'))],
    ));
    name.dispose(); area.dispose();
    if (result == true) ref.invalidate(farmsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farms = ref.watch(farmsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Farms')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addFarm(context, ref), icon: const Icon(Icons.add), label: const Text('Add farm')),
      body: farms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 12), Text('Could not load farms'), TextButton(onPressed: () => ref.invalidate(farmsProvider), child: const Text('Retry'))]))),
        data: (items) => items.isEmpty ? const Center(child: Text('No farms yet. Add your first farm.')) : RefreshIndicator(onRefresh: () async => ref.invalidate(farmsProvider), child: ListView.separated(padding: const EdgeInsets.all(20), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) { final farm = items[i]; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.agriculture)), title: Text(farm.name), subtitle: Text('${farm.areaAcres.toStringAsFixed(1)} acres${farm.location == null ? '' : ' • ${farm.location}'}'), trailing: const Icon(Icons.chevron_right))); })),
      ),
    );
  }
}
