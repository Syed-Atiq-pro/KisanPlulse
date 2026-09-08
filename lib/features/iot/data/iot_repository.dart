import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'iot_models.dart';

class IotRepository {
  IotRepository(this.client);
  final SupabaseClient client;
  String get _uid => client.auth.currentUser!.id;
  Future<List<IotDevice>> devices() async {
    final rows = await client.from('iot_devices').select().eq('user_id', _uid).order('name');
    return (rows as List).map((e) => IotDevice.fromMap(e)).toList();
  }
  Stream<List<IotDevice>> watchDevices() async* {
    yield await devices();
    await for (final _ in client.from('iot_devices').stream(primaryKey: ['id'])) { yield await devices(); }
  }
  Future<List<IotReading>> readings(String deviceId) async {
    final rows = await client.from('iot_readings').select().eq('device_id', deviceId).order('recorded_at', ascending: false).limit(30);
    return (rows as List).map((e) => IotReading.fromMap(e)).toList();
  }
  Stream<List<IotReading>> watchReadings(String deviceId) async* {
    yield await readings(deviceId);
    await for (final _ in client.from('iot_readings').stream(primaryKey: ['id']).eq('device_id', deviceId)) { yield await readings(deviceId); }
  }
  Future<void> addDevice({required String name, required String key}) => client.from('iot_devices').insert({'user_id':_uid,'name':name,'device_key':key,'device_type':'esp32'});
  Future<void> deleteDevice(String id) => client.from('iot_devices').delete().eq('id', id).eq('user_id', _uid);
}