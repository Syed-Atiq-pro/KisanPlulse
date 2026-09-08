import 'package:supabase_flutter/supabase_flutter.dart';

class DiseaseHistoryItem {
  const DiseaseHistoryItem({
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.createdAt,
    this.modelName,
  });

  final String crop;
  final String disease;
  final double confidence;
  final DateTime createdAt;
  final String? modelName;
}

class DiseaseHistoryRepository {
  DiseaseHistoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<DiseaseHistoryItem>> list({int limit = 30}) async {
    final rows = await _client
        .from('disease_diagnoses')
        .select('crop,disease,confidence,created_at,model_name')
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((row) {
      return DiseaseHistoryItem(
        crop: row['crop'] as String? ?? 'Unknown',
        disease: row['disease'] as String? ?? 'Unknown',
        confidence: (row['confidence'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(row['created_at'] as String),
        modelName: row['model_name'] as String?,
      );
    }).toList();
  }
}
