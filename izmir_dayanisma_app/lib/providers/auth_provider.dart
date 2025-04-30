// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../services/local_db_service.dart';

class AuthProvider extends ChangeNotifier {
  final LocalDbService _dbService;

  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  int? _userAge;
  String? _userGender;
  String? _userDistrict;
  String _userRole = 'user';

  AuthProvider(this._dbService);

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  int? get userAge => _userAge;
  String? get userGender => _userGender;
  String? get userDistrict => _userDistrict;
  bool get isAdmin => _userRole == 'admin';

  Future<bool> login(String email, String password) async {
    final result = await _dbService.db.rawQuery(
      'SELECT name,email,role,age,gender,district '
      'FROM users WHERE email = ? AND password = ?',
      [email, password],
    );
    if (result.isNotEmpty) {
      final row = result.first;
      _isAuthenticated = true;
      _userName = row['name'] as String?;
      _userEmail = row['email'] as String?;
      _userRole = row['role'] as String? ?? 'user';
      _userAge = row['age'] as int?;
      _userGender = row['gender'] as String?;
      _userDistrict = row['district'] as String?;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    int age,
    String gender,
    String district,
  ) async {
    try {
      await _dbService.db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
        'role': 'user',
        'age': age,
        'gender': gender,
        'district': district,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _userAge = null;
    _userGender = null;
    _userDistrict = null;
    _userRole = 'user';
    notifyListeners();
  }
}
