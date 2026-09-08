import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/disease_models.dart';
import '../data/disease_service.dart';

class DiseasePage extends StatefulWidget {
  const DiseasePage({super.key});
  @override State<DiseasePage> createState() => _DiseasePageState();
}

class _DiseasePageState extends State<DiseasePage> {
  final picker = ImagePicker();
  final service = DiseaseService();
  Uint8List? bytes;
  DiseasePrediction? prediction;
  bool loading = false;

  Future<void> _pick(ImageSource source) async {
    final selected = await picker.pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 88);
    if (selected == null) return;
    setState(() { loading = true; prediction = null; });
    try {
      final data = await selected.readAsBytes();
      final result = await service.analyze(imageBytes: data);
      if (mounted) setState(() { bytes = data; prediction = result; loading = false; });
    } catch (e) {
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e'))); }
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Crop Health')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        if (bytes != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(bytes!, height: 260, width: double.infinity, fit: BoxFit.cover)) else const SizedBox(height: 220, child: Center(child: Icon(Icons.eco_rounded, size: 80))),
        const SizedBox(height: 18), const Text('Take a clear leaf photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), const Text('Use good daylight and keep one leaf clearly visible.'), const SizedBox(height: 18),
        Row(children: [Expanded(child: FilledButton.icon(onPressed: loading ? null : () => _pick(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Camera'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: loading ? null : () => _pick(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery')))]),
      ]))),
      if (loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Analyzing leaf...')]))),
      if (prediction != null) _resultCard(prediction!),
    ]),
  );

  Widget _resultCard(DiseasePrediction result) {
    final percent = (result.confidence * 100).clamp(0, 100).toStringAsFixed(1);
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Analysis result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 18),
      Text(result.crop, style: Theme.of(context).textTheme.titleMedium), Text(result.disease, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
      LinearProgressIndicator(value: result.confidence.clamp(0, 1)), const SizedBox(height: 6), Text('Confidence: $percent%'),
      if (result.isLowConfidence) ...[const SizedBox(height: 14), const Text('Low confidence: retake the photo or consult an agricultural expert.', style: TextStyle(fontWeight: FontWeight.w700))],
      if (result.advice.isNotEmpty) ...[const SizedBox(height: 18), const Text('Recommended next steps', style: TextStyle(fontWeight: FontWeight.w800)), ...result.advice.map((item) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline), title: Text(item)))],
      if (result.warning != null) ...[const Divider(), Text(result.warning!, style: const TextStyle(fontStyle: FontStyle.italic))],
    ])));
  }
}
