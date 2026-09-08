class Market {
  const Market({required this.id, required this.name, this.state, this.district, this.marketType = 'mandi', this.latitude, this.longitude});
  final String id;
  final String name;
  final String? state;
  final String? district;
  final String marketType;
  final double? latitude;
  final double? longitude;

  factory Market.fromMap(Map<String, dynamic> map) => Market(
    id: map['id'] as String,
    name: map['name'] as String,
    state: map['state'] as String?,
    district: map['district'] as String?,
    marketType: map['market_type'] as String? ?? 'mandi',
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
  );
}

class MarketPrice {
  const MarketPrice({required this.id, required this.marketId, required this.commodity, required this.priceDate, required this.modalPrice, this.variety, this.grade, this.minPrice, this.maxPrice, this.arrivalsTonnes, this.unit = 'quintal', this.source = 'data.gov.in'});
  final String id;
  final String marketId;
  final String commodity;
  final String? variety;
  final String? grade;
  final DateTime priceDate;
  final double? minPrice;
  final double? maxPrice;
  final double modalPrice;
  final double? arrivalsTonnes;
  final String unit;
  final String source;

  factory MarketPrice.fromMap(Map<String, dynamic> map) => MarketPrice(
    id: map['id'] as String,
    marketId: map['market_id'] as String,
    commodity: map['commodity'] as String,
    variety: map['variety'] as String?,
    grade: map['grade'] as String?,
    priceDate: DateTime.parse(map['price_date'] as String),
    minPrice: (map['min_price'] as num?)?.toDouble(),
    maxPrice: (map['max_price'] as num?)?.toDouble(),
    modalPrice: (map['modal_price'] as num).toDouble(),
    arrivalsTonnes: (map['arrivals_tonnes'] as num?)?.toDouble(),
    unit: map['unit'] as String? ?? 'quintal',
    source: map['source'] as String? ?? 'data.gov.in',
  );
}

class MarketPriceAlert {
  const MarketPriceAlert({required this.id, required this.commodity, required this.targetPrice, required this.direction, required this.active, this.marketId});
  final String id;
  final String commodity;
  final double targetPrice;
  final String direction;
  final bool active;
  final String? marketId;

  factory MarketPriceAlert.fromMap(Map<String, dynamic> map) => MarketPriceAlert(
    id: map['id'] as String,
    commodity: map['commodity'] as String,
    targetPrice: (map['target_price'] as num).toDouble(),
    direction: map['direction'] as String,
    active: map['active'] as bool? ?? true,
    marketId: map['market_id'] as String?,
  );
}
