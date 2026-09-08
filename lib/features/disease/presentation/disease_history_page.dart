import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/disease_history_repository.dart';

class DiseaseHistoryPage extends StatefulWidget {
  const DiseaseHistoryPage({super.key});

  @override
  State<DiseaseHistoryPage> createState() => _DiseaseHistoryPageState();
}

class _DiseaseHistoryPageState extends State<DiseaseHistoryPage> {
  final repository = DiseaseHistoryRepository();
  late Future<List<DiseaseHistoryItem>> future;

  @override
  void initState() {
    super.initState();
    future = repository.list();
  }

  void _reload() => setState(() => future = repository.list());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis history'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: FutureBuilder<List<DiseaseHistoryItem>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load history. ${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          final items = snapshot.data ?? const <DiseaseHistoryItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('No diagnoses yet. Your AI crop checks will appear here.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final confidence = (item.confidence * 100).toStringAsFixed(1);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(item.disease.toLowerCase() == 'healthy' ? Icons.check_rounded : Icons.eco_rounded),
                  ),
                  title: Text(item.disease, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${item.crop} • $confidence% confidence\n${DateFormat.yMMMd().add_jm().format(item.createdAt.toLocal())}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
