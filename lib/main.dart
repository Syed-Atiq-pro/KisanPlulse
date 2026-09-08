import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Provide these at build time with:
  // flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  if (Env.supabaseUrl.isNotEmpty && Env.supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  runApp(const ProviderScope(child: AgriSenseApp()));
}
