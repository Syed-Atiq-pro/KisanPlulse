class Farm {
  const Farm({required this.id, required this.name, this.location, this.areaAcres = 0});
  final String id;
  final String name;
  final String? location;
  final double areaAcres;

  factory Farm.fromMap(Map<String, dynamic> map) => Farm(
        id: map['id'] as String,
        name: map['name'] as String,
        location: map['location'] as String?,
        areaAcres: (map['area_acres'] as num?)?.toDouble() ?? 0,
      );
}

class Field {
  const Field({required this.id, required this.farmId, required this.name, this.areaAcres = 0, this.soilType});
  final String id;
  final String farmId;
  final String name;
  final double areaAcres;
  final String? soilType;

  factory Field.fromMap(Map<String, dynamic> map) => Field(
        id: map['id'] as String,
        farmId: map['farm_id'] as String,
        name: map['name'] as String,
        areaAcres: (map['area_acres'] as num?)?.toDouble() ?? 0,
        soilType: map['soil_type'] as String?,
      );
}

class Crop {
  const Crop({required this.id, required this.fieldId, required this.name, this.variety, this.status = 'planned', this.stage = 'seedling', this.plantingDate, this.expectedHarvestDate, this.notes, this.expectedYieldKg});
  final String id;
  final String fieldId;
  final String name;
  final String? variety;
  final String status;
  final String stage;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;
  final String? notes;
  final double? expectedYieldKg;

  factory Crop.fromMap(Map<String, dynamic> map) => Crop(
        id: map['id'] as String,
        fieldId: map['field_id'] as String,
        name: map['name'] as String,
        variety: map['variety'] as String?,
        status: map['status'] as String? ?? 'planned',
        stage: map['stage'] as String? ?? 'seedling',
        plantingDate: map['planting_date'] == null ? null : DateTime.tryParse(map['planting_date'] as String),
        expectedHarvestDate: map['expected_harvest_date'] == null ? null : DateTime.tryParse(map['expected_harvest_date'] as String),
        notes: map['notes'] as String?,
        expectedYieldKg: (map['expected_yield_kg'] as num?)?.toDouble(),
      );
}
