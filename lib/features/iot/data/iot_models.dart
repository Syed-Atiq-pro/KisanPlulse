class IotDevice {
  const IotDevice({required this.id, required this.name, required this.deviceType, required this.deviceKey, this.fieldId, required this.isOnline, this.lastSeen});
  final String id, name, deviceType, deviceKey;
  final String? fieldId;
  final bool isOnline;
  final DateTime? lastSeen;
  factory IotDevice.fromMap(Map<String,dynamic> m) => IotDevice(id:m['id'] as String,name:m['name'] as String,deviceType:m['device_type'] as String? ?? 'esp32',deviceKey:m['device_key'] as String,fieldId:m['field_id'] as String?,isOnline:m['is_online'] as bool? ?? false,lastSeen:m['last_seen']==null?null:DateTime.parse(m['last_seen'] as String));
}
class IotReading {
  const IotReading({this.soilMoisture,this.temperature,this.humidity,this.waterLevel,this.pumpOn,required this.recordedAt});
  final double? soilMoisture, temperature, humidity, waterLevel;
  final bool? pumpOn;
  final DateTime recordedAt;
  factory IotReading.fromMap(Map<String,dynamic> m) => IotReading(soilMoisture:(m['soil_moisture'] as num?)?.toDouble(),temperature:(m['temperature'] as num?)?.toDouble(),humidity:(m['humidity'] as num?)?.toDouble(),waterLevel:(m['water_level'] as num?)?.toDouble(),pumpOn:m['pump_on'] as bool?,recordedAt:DateTime.parse(m['recorded_at'] as String));
}