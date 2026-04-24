import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static User? get currentUser => client.auth.currentUser;
  
  static String? get userId => client.auth.currentUser?.id;
}
