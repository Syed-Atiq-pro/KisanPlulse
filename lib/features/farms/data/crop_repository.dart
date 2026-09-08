import 'package:supabase_flutter/supabase_flutter.dart';
import 'farm_models.dart';

class CropRepository {
  CropRepository(this._client);
  final SupabaseClient _client;

  Future<List<Crop>> listCrops(String fieldId) async {
    final rows = await _client.from('crops').select('id,field_id,name,variety,status,stage,planting_date,expected_harvest_date,notes,expected_yield_kg').eq('field_id', fieldId).order('created_at', ascending: false);
    return (rows as List).map((row) => Crop.fromMap(Map<String, dynamic>.from(row))).toList();
  }

  Future<Crop> createCrop({required String fieldId, required String name, String? variety, required String status, required String stage, DateTime? plantingDate, DateTime? expectedHarvestDate, String? notes, double? expectedYieldKg}) async {
    final row = await _client.from('crops').insert({
      'field_id': fieldId,
      'name': name.trim(),
      'variety': variety?.trim().isEmpty == true ? null : variety?.trim(),
      'status': status,
      'stage': stage,
      'planting_date': plantingDate?.toIso8601String().split('T').first,
      'expected_harvest_date': expectedHarvestDate?.toIso8601String().split('T').first,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'expected_yield_kg': expectedYieldKg,
    }).select('id,field_id,name,variety,status,stage,planting_date,expected_harvest_date,notes,expected_yield_kg').single();
    return Crop.fromMap(Map<String, dynamic>.from(row));
  }

  Future<Crop> updateStatus(String cropId, {required String status, required String stage}) async {
    final row = await _client.from('crops').update({'status': status, 'stage': stage, 'updated_at': DateTime.now().toIso8601String()}).eq('id', cropId).select('id,field_id,name,variety,status,stage,planting_date,expected_harvest_date,notes,expected_yield_kg').single();
    return Crop.fromMap(Map<String, dynamic>.from(row));
  }
}
