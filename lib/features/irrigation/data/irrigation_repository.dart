import 'package:supabase_flutter/supabase_flutter.dart';
import 'irrigation_models.dart';

class IrrigationRepository {
  IrrigationRepository(this.client);
  final SupabaseClient client;

  Future<List<IrrigationRecord>> listRecent(String fieldId) async {
    final rows = await client.from('irrigation_records').select('id,field_id,crop_id,irrigation_date,water_mm,duration_minutes,method').eq('field_id', fieldId).order('irrigation_date', ascending: false).limit(20);
    return (rows as List).map((r) => IrrigationRecord(id: r['id'], fieldId: r['field_id'], cropId: r['crop_id'], date: DateTime.parse(r['irrigation_date']), waterMm: (r['water_mm'] as num).toDouble(), durationMinutes: r['duration_minutes'], method: r['method'])).toList();
  }

  Future<void> addRecord({required String fieldId, String? cropId, required double waterMm, int? durationMinutes, String method = 'manual'}) async {
    await client.from('irrigation_records').insert({'field_id': fieldId, 'crop_id': cropId, 'water_mm': waterMm, 'duration_minutes': durationMinutes, 'method': method});
  }
}
