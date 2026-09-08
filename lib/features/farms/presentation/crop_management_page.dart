import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/crop_repository.dart';
import '../data/farm_models.dart';

final cropsProvider = FutureProvider.autoDispose.family<List<Crop>, String>((ref, fieldId) => CropRepository(Supabase.instance.client).listCrops(fieldId));

class CropManagementPage extends ConsumerWidget {
  const CropManagementPage({super.key, required this.fieldId, required this.fieldName, required this.areaAcres});
  final String fieldId;
  final String fieldName;
  final double areaAcres;

  static const stages = ['seedling','vegetative','flowering','fruiting','maturing','ready_to_harvest'];
  static const statuses = ['planned','growing','harvested','failed'];

  Future<void> _addCrop(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final variety = TextEditingController();
    final notes = TextEditingController();
    final yieldController = TextEditingController();
    String status = 'planned';
    String stage = 'seedling';
    DateTime? planting;
    DateTime? harvest;
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Plan a crop'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Crop name', hintText: 'e.g. Tomato')),
        TextField(controller: variety, decoration: const InputDecoration(labelText: 'Variety (optional)')),
        DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Status'), items: statuses.map((v) => DropdownMenuItem(value: v, child: Text(_pretty(v)))).toList(), onChanged: (v) => setDialogState(() => status = v!)),
        DropdownButtonFormField<String>(value: stage, decoration: const InputDecoration(labelText: 'Growth stage'), items: stages.map((v) => DropdownMenuItem(value: v, child: Text(_pretty(v)))).toList(), onChanged: (v) => setDialogState(() => stage = v!)),
        const SizedBox(height: 8),
        ListTile(contentPadding: EdgeInsets.zero, title: Text(planting == null ? 'Planting date' : 'Planted ${DateFormat.yMMMd().format(planting!)}'), trailing: const Icon(Icons.calendar_today_rounded), onTap: () async { final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: planting ?? DateTime.now()); if (date != null) setDialogState(() => planting = date); }),
        ListTile(contentPadding: EdgeInsets.zero, title: Text(harvest == null ? 'Expected harvest date' : 'Harvest ${DateFormat.yMMMd().format(harvest!)}'), trailing: const Icon(Icons.event_available_rounded), onTap: () async { final date = await showDatePicker(context: context, firstDate: planting ?? DateTime.now(), lastDate: DateTime(2100), initialDate: harvest ?? (planting ?? DateTime.now()).add(const Duration(days: 90))); if (date != null) setDialogState(() => harvest = date); }),
        TextField(controller: yieldController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expected yield (kg)')),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) return; final value = double.tryParse(yieldController.text); await CropRepository(Supabase.instance.client).createCrop(fieldId: fieldId, name: name.text, variety: variety.text, status: status, stage: stage, plantingDate: planting, expectedHarvestDate: harvest, notes: notes.text, expectedYieldKg: value); if (dialogContext.mounted) Navigator.pop(dialogContext, true); }, child: const Text('Add crop'))],
    )));
    name.dispose(); variety.dispose(); notes.dispose(); yieldController.dispose();
    if (result == true) ref.invalidate(cropsProvider(fieldId));
  }

  static String _pretty(String value) => value.split('_').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropsProvider(fieldId));
    return Scaffold(
      appBar: AppBar(title: Text(fieldName)),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addCrop(context, ref), icon: const Icon(Icons.add), label: const Text('Add crop')),
      body: RefreshIndicator(onRefresh: () async => ref.invalidate(cropsProvider(fieldId)), child: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [const CircleAvatar(child: Icon(Icons.crop_square_rounded)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(fieldName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)), const SizedBox(height: 4), Text('${areaAcres.toStringAsFixed(1)} acres • Crop lifecycle')]))]))),
        const SizedBox(height: 14),
        crops.when(loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())), error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('Could not load crops.\n$e')), data: (items) => items.isEmpty ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No crops planned for this field yet. Add a crop to start tracking its lifecycle.', textAlign: TextAlign.center))) : Column(children: items.map((crop) => _CropCard(crop: crop, fieldId: fieldId)).toList())),
      ])),
    );
  }
}

class _CropCard extends ConsumerWidget {
  const _CropCard({required this.crop, required this.fieldId});
  final Crop crop;
  final String fieldId;

  Future<void> _advance(BuildContext context, WidgetRef ref) async {
    const stages = CropManagementPage.stages;
    final index = stages.indexOf(crop.stage);
    final nextStage = index >= 0 && index < stages.length - 1 ? stages[index + 1] : crop.stage;
    final nextStatus = nextStage == 'ready_to_harvest' ? 'growing' : crop.status;
    if (nextStage == crop.stage) return;
    await CropRepository(Supabase.instance.client).updateStatus(crop.id, status: nextStatus, stage: nextStage);
    ref.invalidate(cropsProvider(fieldId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = crop.expectedHarvestDate == null ? null : crop.expectedHarvestDate!.difference(DateTime.now()).inDays;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(child: Icon(crop.status == 'harvested' ? Icons.check_rounded : Icons.eco_rounded)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(crop.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), if (crop.variety != null) Text(crop.variety!)])), Chip(label: Text(CropManagementPage._pretty(crop.status)))]),
      const SizedBox(height: 14),
      Text(CropManagementPage._pretty(crop.stage), style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), LinearProgressIndicator(value: (CropManagementPage.stages.indexOf(crop.stage) + 1) / CropManagementPage.stages.length),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [if (crop.plantingDate != null) Chip(avatar: const Icon(Icons.event_rounded, size: 16), label: Text('Planted ${DateFormat.MMMd().format(crop.plantingDate!)}')), if (days != null) Chip(avatar: const Icon(Icons.schedule_rounded, size: 16), label: Text(days < 0 ? '${-days}d overdue' : '$daysd to harvest')), if (crop.expectedYieldKg != null) Chip(avatar: const Icon(Icons.scale_rounded, size: 16), label: Text('${crop.expectedYieldKg!.toStringAsFixed(0)} kg expected'))]),
      if (crop.notes != null && crop.notes!.isNotEmpty) ...[const SizedBox(height: 8), Text(crop.notes!)],
      if (crop.stage != 'ready_to_harvest' && crop.status != 'harvested') ...[const SizedBox(height: 10), Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: () => _advance(context, ref), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Advance stage')))],
    ])));
  }
}
