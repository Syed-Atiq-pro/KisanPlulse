import 'package:supabase_flutter/supabase_flutter.dart';
import 'market_models.dart';

class MarketRepository {
  MarketRepository(this.client);
  final SupabaseClient client;

  Future<List<Market>> listMarkets({String? state, String? district}) async {
    var query = client.from('markets').select('id,name,state,district,market_type,latitude,longitude');
    if (state != null && state.isNotEmpty) query = query.eq('state', state);
    if (district != null && district.isNotEmpty) query = query.eq('district', district);
    final rows = await query.order('name');
    return (rows as List).map((r) => Market.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  Future<List<MarketPrice>> latestPrices({String? commodity, String? marketId, int days = 14}) async {
    var query = client.from('market_prices').select('id,market_id,commodity,variety,grade,price_date,min_price,max_price,modal_price,arrivals_tonnes,unit,source');
    if (commodity != null && commodity.isNotEmpty) query = query.ilike('commodity', commodity);
    if (marketId != null && marketId.isNotEmpty) query = query.eq('market_id', marketId);
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().split('T').first;
    final rows = await query.gte('price_date', cutoff).order('price_date', ascending: false).limit(200);
    return (rows as List).map((r) => MarketPrice.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  Future<List<MarketPriceAlert>> listAlerts() async {
    final rows = await client.from('market_price_alerts').select('id,commodity,target_price,direction,active,market_id').eq('user_id', client.auth.currentUser!.id).order('created_at', ascending: false);
    return (rows as List).map((r) => MarketPriceAlert.fromMap(Map<String, dynamic>.from(r))).toList();
  }

  Future<MarketPriceAlert> createAlert({required String commodity, required double targetPrice, required String direction, String? marketId}) async {
    final row = await client.from('market_price_alerts').insert({'user_id': client.auth.currentUser!.id, 'commodity': commodity.trim(), 'target_price': targetPrice, 'direction': direction, 'market_id': marketId}).select('id,commodity,target_price,direction,active,market_id').single();
    return MarketPriceAlert.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteAlert(String id) async => client.from('market_price_alerts').delete().eq('id', id).eq('user_id', client.auth.currentUser!.id);
}
