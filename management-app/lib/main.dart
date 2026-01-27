import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/delivery_provider.dart';
import 'services/config_service.dart';
import 'utils/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch Supabase config from backend and initialize
  await _initializeSupabaseFromBackend();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        // Add more providers as needed
      ],
      child: const LaundryDeliveryApp(),
    ),
  );
}

/// Fetches Supabase configuration from backend and initializes Supabase if available
Future<void> _initializeSupabaseFromBackend() async {
  try {
    final configService = ConfigService();
    final config = await configService.fetchConfig();
    
    if (config == null) {
      SupabaseConfig.isEnabled = false;
      return;
    }

    final supabaseData = config['supabase'];
    if (supabaseData is Map<String, dynamic>) {
      final url = supabaseData['url']?.toString();
      final anonKey = supabaseData['anonKey']?.toString();

      if (url != null && url.isNotEmpty && anonKey != null && anonKey.isNotEmpty) {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
        SupabaseConfig.isEnabled = true;
        return;
      }
    }

    SupabaseConfig.isEnabled = false;
  } catch (e) {
    // If Supabase init fails, continue without realtime.
    print('Failed to initialize Supabase: $e');
    SupabaseConfig.isEnabled = false;
  }
}
