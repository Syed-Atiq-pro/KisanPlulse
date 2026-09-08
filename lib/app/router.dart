import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/signup_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/farms/presentation/farms_page.dart';
import '../features/farms/presentation/farm_details_page.dart';
import '../features/farms/presentation/crop_management_page.dart';
import '../features/weather/presentation/weather_page.dart';
import '../features/disease/presentation/disease_page.dart';
import '../features/disease/presentation/disease_history_page.dart';
import '../features/irrigation/presentation/irrigation_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    if (session == null && !isAuthRoute) return '/login';
    if (session != null && isAuthRoute) return '/dashboard';
    return null;
  },
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
    GoRoute(path: '/farms', builder: (context, state) => const FarmsPage()),
    GoRoute(path: '/farms/:id', builder: (context, state) => FarmDetailsPage(farmId: state.pathParameters['id']!, farmName: state.uri.queryParameters['name'] ?? 'Farm')),
    GoRoute(path: '/farms/:farmId/fields/:fieldId', builder: (context, state) => CropManagementPage(fieldId: state.pathParameters['fieldId']!, fieldName: state.uri.queryParameters['name'] ?? 'Field', areaAcres: double.tryParse(state.uri.queryParameters['area'] ?? '') ?? 0)),
    GoRoute(path: '/weather', builder: (context, state) => const WeatherPage()),
    GoRoute(path: '/disease', builder: (context, state) => const DiseasePage()),
    GoRoute(path: '/disease/history', builder: (context, state) => const DiseaseHistoryPage()),
    GoRoute(path: '/irrigation', builder: (context, state) => const IrrigationPage()),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) { _subscription = stream.asBroadcastStream().listen((_) => notifyListeners()); }
  late final StreamSubscription<dynamic> _subscription;
  @override void dispose() { _subscription.cancel(); super.dispose(); }
}
