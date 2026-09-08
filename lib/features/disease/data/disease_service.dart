import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'disease_models.dart';

class DiseaseService {
  DiseaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DiseasePrediction> analyze({required List<int> imageBytes}) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('Please sign in before using AI crop diagnosis.');
    }

    final encoded = base64Encode(imageBytes);
    final response = await _client.functions.invoke(
      'diagnose-plant',
      body: {'image_base64': encoded},
    );

    if (response.status < 200 || response.status >= 300) {
      throw Exception('Disease service returned ${response.status}.');
    }

    final data = Map<String, dynamic>.from(response.data as Map);
    return DiseasePrediction(
      crop: data['crop'] as String? ?? 'Unknown',
      disease: data['disease'] as String? ?? 'Unknown',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      advice: List<String>.from(data['advice'] ?? const []),
      warning: data['warning'] as String?,
    );
  }
}
