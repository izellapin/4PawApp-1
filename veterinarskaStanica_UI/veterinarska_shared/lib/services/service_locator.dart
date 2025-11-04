import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  ApiClient? _apiClient;
  AuthService? _authService;
  bool _isInitialized = false;

  ApiClient get apiClient {
    if (!_isInitialized || _apiClient == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _apiClient!;
  }

  AuthService get authService {
    if (!_isInitialized || _authService == null) {
      throw StateError('ServiceLocator not initialized. Call initialize() first.');
    }
    return _authService!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (kDebugMode) {
      print('ServiceLocator: Initializing services...');
    }
    
    _apiClient = ApiClient();
    _authService = AuthService(_apiClient!);
    _isInitialized = true;
    
    if (kDebugMode) {
      print('ServiceLocator: Services initialized successfully');
    }
  }

  /// Reset and reinitialize all services (useful when network config changes)
  Future<void> reset() async {
    if (kDebugMode) {
      print('ServiceLocator: Resetting services...');
    }
    
    _apiClient = null;
    _authService = null;
    _isInitialized = false;
    
    await initialize();
    
    if (kDebugMode) {
      print('ServiceLocator: Services reset complete');
      print('New ApiClient created with baseUrl: ${_apiClient?.baseUrl}');
      print('ServiceLocator reset at: ${DateTime.now()}');
    }
  }
}

final serviceLocator = ServiceLocator();



