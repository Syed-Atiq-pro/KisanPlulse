import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/crop_repository.dart';
import '../data/farm_models.dart';

final cropsProvider = FutureProvider.autoDispose.family<List<Crop>, String>(
  (ref, fieldId) => CropRepository(Supabase.instance.client).listCrops(fieldId),
);

class CropManagementPage extends ConsumerWidget {
  const CropManagementPage({super.key, required this.fieldId, required this.fieldName, required this.areaAcres});

  final String fieldId;
  final String fieldName;
  final double areaAcres;

  static const stages = ['seedling', 'vegetative', 'flowering', 'fruiting', 'maturing', 'ready_to_harvest'];
  static const statuses = ['planned', 'growing', 'harvested', 'failed'];

  Future<void> _addCrop(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final variety = TextEditingController();
    final notes = TextEditingController();
    final yieldController = TextEditingController();
    String status = 'planned';
    String stage = 'seedling';
    DateTime? planting;
    DateTime? harvest;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Plan a crop'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Crop name', hintText: 'e.g. Tomato')),
                  TextField(controller: variety, decoration: const InputDecoration(labelText: 'Variety (optional)')),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statuses.map((v) => DropdownMenuItem(value: v, child: Text(_pretty(v)))).toList(),
                    onChanged: (v) => setDialogState(() => status = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: stage,
                    decoration: const InputDecoration(labelText: 'Growth stage'),
                    items: stages.map((v) => DropdownMenuItem(value: v, child: Text(_pretty(v)))).toList(),
                    onChanged: (v) => setDialogState(() => stage = v!),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(planting == null ? 'Planting date' : 'Planted ${DateFormat.yMMMd().format(planting!)}'),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: planting ?? DateTime.now());
                      if (date != null) setDialogState(() => planting = date);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(harvest == null ? 'Expected harvest date' : 'Harvest ${DateFormat.yMMMd().format(harvest!)}'),
                    trailing: const Icon(Icons.event_available_rounded),
                    onTap: () async {
                      final start = planting ?? DateTime.now();
                      final date = await showDatePicker(context: context, firstDate: start, lastDate: DateTime(2100), initialDate: harvest ?? start.add(const Duration(days: 90)));
                      if (date != null) setDialogState(() => harvest = date);
                    },
                  ),
                  TextField(controller: yieldController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expected yield (kg)')),
                  TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  await CropRepository(Supabase.instance.client).createCrop(
                    fieldId: fieldId,
                    name: name.text,
                    variety: variety.text,
                    status: status,
                    stage: stage,
                    plantingDate: planting,
                    expectedHarvestDate: harvest,
                    notes: notes.text,
                    expectedYieldKg: double.tryParse(yieldController.text),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                },
                child: const Text('Add crop'),
              ),
            ],
          ),
        ),
      );
      if (result == true) ref.invalidate(cropsProvider(fieldId));
    } finally {
      name.dispose();
      variety.dispose();
      notes.dispose();
      yieldController.dispose();
    }
  }

  static String _pretty(String value) => value.split('_').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropsProvider(fieldId));
    return Scaffold(
      appBar: AppBar(title: Text(fieldName)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addCrop(context, ref), icon: const Icon(Icons.add), label: const Text('Add crop')),
      body: crops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load crops: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No crops planned yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final crop = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${_pretty(crop.stage)} • ${crop.expectedYieldKg?.toStringAsFixed(0) ?? '—'} kg expected'),
                      trailing: Chip(label: Text(_pretty(crop.status))),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
