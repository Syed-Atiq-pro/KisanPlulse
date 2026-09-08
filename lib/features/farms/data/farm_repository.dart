import 'package:supabase_flutter/supabase_flutter.dart';
import 'farm_models.dart';

class FarmRepository {
  FarmRepository(this._client);
  final SupabaseClient _client;

  Future<List<Farm>> listFarms() async {
    final rows = await _client.from('farms').select('id,name,location,area_acres').order('created_at');
    return (rows as List).map((e) => Farm.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<Farm> createFarm({required String name, String? location, double areaAcres = 0}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('You must be signed in.');
    final row = await _client.from('farms').insert({
      'owner_id': userId,
      'name': name.trim(),
      'location': location?.trim(),
      'area_acres': areaAcres,
    }).select('id,name,location,area_acres').single();
    return Farm.fromMap(Map<String, dynamic>.from(row));
  }
}

class FieldRepository {
  FieldRepository(this._client);
  final SupabaseClient _client;

  Future<List<Field>> listFields(String farmId) async {
    final rows = await _client.from('fields').select('id,farm_id,name,area_acres,soil_type').eq('farm_id', farmId).order('created_at');
    return (rows as List).map((e) => Field.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<Field> createField({required String farmId, required String name, double areaAcres = 0, String? soilType}) async {
    final row = await _client.from('fields').insert({'farm_id': farmId, 'name': name.trim(), 'area_acres': areaAcres, 'soil_type': soilType?.trim()}).select('id,farm_id,name,area_acres,soil_type').single();
    return Field.fromMap(Map<String, dynamic>.from(row));
  }
}
