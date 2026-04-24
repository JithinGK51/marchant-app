import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user = SupabaseService.currentUser;
  bool _loading = false;

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await SupabaseService.client.auth.signInWithPassword(email: email, password: password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String email, String password, String name, String shopName) async {
    _loading = true;
    notifyListeners();
    try {
      // Step 1: Initialize signup via backend (sends OTP)
      await ApiService.initSignup(email, password, name, shopName);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOTP(String email, String password, String name, String shopName, String otp) async {
    _loading = true;
    notifyListeners();
    try {
      // Step 2: Verify OTP via backend (creates user in Supabase)
      await ApiService.verifySignup(email, password, name, shopName, otp);
      
      // Step 3: Login the newly created user
      await login(email, password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
  }
}
