import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../models/pet.dart';
import '../models/appointment.dart';
import 'network_config.dart';
import 'service_locator.dart';

class ApiClient {
  late final Dio dio;
  
  String get baseUrl => NetworkConfig.apiBaseUrl;

  ApiClient() {
    if (kDebugMode) {
      print('ApiClient constructor called');
      print('Using baseUrl: $baseUrl');
      print('Full baseUrl: ${baseUrl}');
      print('ApiClient created at: ${DateTime.now()}');
    }
    
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (_) => true,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) {}, // Disable API logs
    ));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          print('401 Unauthorized - attempting token refresh');
          final refreshed = await _refreshToken();
          if (refreshed) {
            print('Token refreshed, retrying request');
            final prefs = await SharedPreferences.getInstance();
            final newToken = prefs.getString('access_token');
            if (newToken != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final response = await dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } else {
            print('Token refresh failed - logging out and redirecting to login');
            // Logout korisnika - ovo će automatski triggerovati AuthWrapper da prikaže login ekran
            try {
              // Koristimo lazy pristup da izbjegnemo circular dependency
              if (serviceLocator.isInitialized) {
                final authService = serviceLocator.authService;
                await authService.logout();
                print('User logged out due to expired token');
              } else {
                print('ServiceLocator not initialized, clearing tokens only');
                await _clearTokens();
              }
            } catch (e) {
              print('Error during logout: $e');
              // Fallback: samo obriši tokene
              await _clearTokens();
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) {
        print('No refresh token found');
        await _clearTokens();
        return false;
      }

      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);
        await prefs.setString('access_token', authResponse.accessToken);
        await prefs.setString('refresh_token', authResponse.refreshToken);
        print('Token refreshed successfully');
        return true;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      await _clearTokens();
    }
    return false;
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    print('Tokens cleared');
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        await dio.post('/auth/logout');
      }
    } catch (e) {
      print('Error calling logout endpoint: $e');
      
    } finally {
      await _clearTokens();
      print('User logged out');
    }
  }

  Future<AuthResponse> login(String emailOrUsername, String password, {String? clientType}) async {
    try {
      print('Attempting login for: $emailOrUsername');
      final response = await dio.post('/auth/login', data: {
        'emailOrUsername': emailOrUsername,
        'password': password,
        if (clientType != null) 'clientType': clientType,
      });
      
      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');
      
      if (response.statusCode != 200) {
        throw ApiError(message: response.data?['message'] ?? 'Login failed');
      }
      
      if (response.data == null) {
        throw ApiError(message: 'Prazan odgovor sa servera');
      }
      
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('Login error: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register(String firstName, String lastName, String email, String username, String password, {String? phoneNumber, String? address, int role = 1}) async {
    try {
      print('Attempting registration for: $email');
      print('Role parameter: $role');
      final response = await dio.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'username': username,
        'password': password,
        'confirmPassword': password,
        'phoneNumber': phoneNumber,
        'address': address,
        'clientType': 'Mobile',
        'role': role,
      });
      
      print('Registration response status: ${response.statusCode}');
      print('Registration response data: ${response.data}');
      
      if (response.statusCode != 200) {
        throw ApiError(message: response.data?['message'] ?? 'Registration failed');
      }
      
      if (response.data == null) {
        throw ApiError(message: 'Prazan odgovor sa servera');
      }
      
      return response.data;
    } on DioException catch (e) {
      print('Registration error: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String verificationCode) async {
    try {
      print('Attempting email verification for: $email');
      final response = await dio.post('/auth/verify-email', data: {
        'email': email,
        'code': verificationCode,
      });
      
      print('Email verification response status: ${response.statusCode}');
      print('Email verification response data: ${response.data}');
      
      if (response.data == null) {
        throw ApiError(message: 'Prazan odgovor sa servera');
      }
      
      return response.data;
    } on DioException catch (e) {
      print('Email verification error: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      print('Attempting to resend verification code for: $email');
      final response = await dio.post('/auth/resend-email-verification', data: {
        'email': email,
      });
      
      print('Resend verification code response status: ${response.statusCode}');
      print('Resend verification code response data: ${response.data}');
      
      if (response.data == null) {
        throw ApiError(message: 'Prazan odgovor sa servera');
      }
      
      return response.data;
    } on DioException catch (e) {
      print('Resend verification code error: ${e.message}');
      print('Response data: ${e.response?.data}');
      throw _handleError(e);
    }
  }


  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateCurrentUser(Map<String, dynamic> data) async {
    try {
      print('Sending profile update to: ${dio.options.baseUrl}/auth/me');
      print('Update data: $data');
      
      if (data.containsKey('password')) {
        await dio.post('/auth/change-password', data: {
          'currentPassword': data['currentPassword'] ?? '',
          'newPassword': data['password'],
        });
        data.remove('password');
        data.remove('currentPassword');
      }
      
      if (data.isNotEmpty) {
        final response = await dio.put('/auth/me', data: data);
        print('Profile update response: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
    } on DioException catch (e) {
      print('Profile update error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error: $e');
      throw ApiError(message: 'Neočekivana greška: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Pet>> getPets() async {
    try {
      final response = await dio.get('/pets');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) => Pet.fromJson(json)).toList();
      } else {
        throw ApiError(message: 'Neočekivani format odgovora sa servera');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Pet>> getAllPets() async {
    try {
      final response = await dio.get('/pets/all');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((json) => Pet.fromJson(json)).toList();
      } else {
        throw ApiError(message: 'Neočekivani format odgovora sa servera');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Pet> getPet(int id) async {
    try {
      final response = await dio.get('/pets/$id');
      return Pet.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Pet> createPet(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/pets', data: data);
      return Pet.fromJson(response.data);
    } on DioException catch (e) {
      print('Pet creation error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<Pet> updatePet(int id, Map<String, dynamic> data) async {
    try {
      print('Updating pet $id with data: $data');
      
      // Prvo pokušaj sa /pets/my/{id} endpoint (za PetOwner korisnike)
      // Ako dobije 403, pokušaj sa /pets/{id} (za veterinare i admine)
      try {
        final response = await dio.put('/pets/my/$id', data: data);
        
        print('Response status: ${response.statusCode}');
        print('Response data type: ${response.data.runtimeType}');
        print('Response data: $response.data');
        
        // Ako je status code 403 ili 404, pokušaj sa /pets/{id} endpoint
        if (response.statusCode == 403 || response.statusCode == 404) {
          print('🔍 Got ${response.statusCode} from /pets/my/$id (non-exception), trying /pets/$id');
          print('🔍 First error response data: ${response.data}');
          print('🔍 First error response data type: ${response.data.runtimeType}');
          
          // Provjeri da li postoji authorization token
          final headers = dio.options.headers;
          print('🔍 Request headers keys: ${headers.keys.toList()}');
          print('🔍 Authorization header present: ${headers.containsKey('Authorization')}');
          if (headers.containsKey('Authorization')) {
            final authHeader = headers['Authorization'];
            print('🔍 Authorization header value: ${authHeader.toString().substring(0, authHeader.toString().length > 50 ? 50 : authHeader.toString().length)}...');
          }
          
          print('🔍 Sending PUT request to /pets/$id with data: $data');
          try {
            final secondResponse = await dio.put('/pets/$id', data: data);
            
            print('✅ Response status from /pets/$id: ${secondResponse.statusCode}');
            print('✅ Response data type: ${secondResponse.data.runtimeType}');
            print('✅ Response data: $secondResponse.data');
            
            if (secondResponse.statusCode == 200) {
              if (secondResponse.data == null) {
                throw ApiError(message: 'Prazan odgovor sa servera');
              }
              
              if (secondResponse.data is! Map<String, dynamic>) {
                throw ApiError(message: 'Neocekivani format odgovora: ${secondResponse.data.runtimeType}');
              }
              
              return Pet.fromJson(secondResponse.data);
            } else {
              // Ako status code nije 200, baci grešku
              final resp = secondResponse.data;
              String errorMessage = 'Update failed';
              if (resp is Map<String, dynamic>) {
                errorMessage = resp['message'] ?? resp['error'] ?? resp['title'] ?? 'Update failed';
              } else if (resp is String) {
                errorMessage = resp;
              }
              print('❌ Error message from response: $errorMessage');
              throw ApiError(message: errorMessage, statusCode: secondResponse.statusCode);
            }
          } on DioException catch (e2) {
            // Ako i /pets/$id baca DioException (npr. 403)
            print('❌ Got DioException from /pets/$id: ${e2.message}');
            print('❌ Response status: ${e2.response?.statusCode}');
            print('❌ Response data: ${e2.response?.data}');
            print('❌ Response data type: ${e2.response?.data?.runtimeType}');
            
            final resp = e2.response?.data;
            String errorMessage = 'Update failed - 403 Forbidden. Provjerite da li ste ulogovani kao Admin ili Veterinarian.';
            if (resp is Map<String, dynamic>) {
              errorMessage = resp['message'] ?? resp['error'] ?? resp['title'] ?? errorMessage;
            } else if (resp is String) {
              errorMessage = resp.isNotEmpty ? resp : errorMessage;
            }
            print('❌ Final error message: $errorMessage');
            throw ApiError(message: errorMessage, statusCode: e2.response?.statusCode ?? 403);
          }
        }
        
        if (response.statusCode == 200) {
          if (response.data == null) {
            throw ApiError(message: 'Prazan odgovor sa servera');
          }
          
          if (response.data is! Map<String, dynamic>) {
            throw ApiError(message: 'Neocekivani format odgovora: ${response.data.runtimeType}');
          }
          
          return Pet.fromJson(response.data);
        }
      } on DioException catch (e) {
        // Ako je 403 ili 404, pokušaj sa /pets/{id} endpoint
        if (e.response?.statusCode == 403 || e.response?.statusCode == 404) {
          print('🔍 Got ${e.response?.statusCode} from /pets/my/$id, trying /pets/$id');
          print('🔍 First error response data: ${e.response?.data}');
          print('🔍 First error response data type: ${e.response?.data.runtimeType}');
          print('🔍 First error response headers: ${e.response?.headers}');
          
          try {
            // Provjeri da li postoji authorization token
            final headers = dio.options.headers;
            print('🔍 Request headers keys: ${headers.keys.toList()}');
            print('🔍 Authorization header present: ${headers.containsKey('Authorization')}');
            if (headers.containsKey('Authorization')) {
              final authHeader = headers['Authorization'];
              print('🔍 Authorization header value: ${authHeader.toString().substring(0, authHeader.toString().length > 50 ? 50 : authHeader.toString().length)}...');
            }
            
            print('🔍 Sending PUT request to /pets/$id with data: $data');
            final response = await dio.put('/pets/$id', data: data);
            
            print('Response status: ${response.statusCode}');
            print('Response data type: ${response.data.runtimeType}');
            print('Response data: $response.data');
            
            if (response.statusCode == 200) {
              if (response.data == null) {
                throw ApiError(message: 'Prazan odgovor sa servera');
              }
              
              if (response.data is! Map<String, dynamic>) {
                throw ApiError(message: 'Neocekivani format odgovora: ${response.data.runtimeType}');
              }
              
              return Pet.fromJson(response.data);
            } else {
              // Ako status code nije 200, baci grešku
              final resp = response.data;
              String errorMessage = 'Update failed';
              if (resp is Map<String, dynamic>) {
                errorMessage = resp['message'] ?? resp['error'] ?? resp['title'] ?? 'Update failed';
              } else if (resp is String) {
                errorMessage = resp;
              }
              print('Error message from response: $errorMessage');
              throw ApiError(message: errorMessage, statusCode: response.statusCode);
            }
          } on DioException catch (e2) {
            // Ako i /pets/$id baca DioException (npr. 403)
            print('Got DioException from /pets/$id: ${e2.message}');
            print('Response status: ${e2.response?.statusCode}');
            print('Response data: ${e2.response?.data}');
            print('Response data type: ${e2.response?.data?.runtimeType}');
            print('Response headers: ${e2.response?.headers}');
            
            final resp = e2.response?.data;
            String errorMessage = 'Update failed - 403 Forbidden. Provjerite da li ste ulogovani kao Admin ili Veterinarian.';
            if (resp is Map<String, dynamic>) {
              errorMessage = resp['message'] ?? resp['error'] ?? resp['title'] ?? errorMessage;
            } else if (resp is String) {
              errorMessage = resp.isNotEmpty ? resp : errorMessage;
            }
            print('Final error message: $errorMessage');
            throw ApiError(message: errorMessage, statusCode: e2.response?.statusCode ?? 403);
          }
        } else {
          // Ako nije 403 ili 404, baci grešku
          print('Update pet error: ${e.message}');
          print('Response: ${e.response?.data}');
          print('Status code: ${e.response?.statusCode}');
          throw _handleError(e);
        }
      }
      
      throw ApiError(message: 'Update failed');
    } catch (e) {
      if (e is ApiError) {
        rethrow;
      }
      print('Unexpected error in updatePet: $e');
      throw ApiError(message: e.toString());
    }
  }

  Future<void> deletePet(int id) async {
    try {
      // Prvo pokušaj sa /pets/{id} (za admin/veterinar)
      try {
        final response = await dio.delete('/pets/$id');
        print('✅ Pet deleted successfully via /pets/$id');
        return;
      } on DioException catch (e) {
        // Ako je 403 ili 404, pokušaj sa /pets/my/{id} (za pet owners)
        if (e.response?.statusCode == 403 || e.response?.statusCode == 404) {
          print('⚠️ Got ${e.response?.statusCode} from /pets/$id, trying /pets/my/$id');
          final response = await dio.delete('/pets/my/$id');
          print('✅ Pet deleted successfully via /pets/my/$id');
          return;
        }
        // Ako nije 403/404, re-throw grešku
        rethrow;
      }
    } on DioException catch (e) {
      print('❌ Delete pet error: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await dio.get('/appointments');
      print('📅 [API CLIENT] getAppointments response status: ${response.statusCode}');
      print('📅 [API CLIENT] Response data type: ${response.data.runtimeType}');
      
      if (response.data is List && (response.data as List).isNotEmpty) {
        final firstItem = (response.data as List)[0];
        print('📅 [API CLIENT] First appointment JSON keys: ${firstItem is Map ? firstItem.keys.toList() : 'not a map'}');
        if (firstItem is Map) {
          print('📅 [API CLIENT] First appointment petId from JSON: ${firstItem['petId']} (type: ${firstItem['petId']?.runtimeType})');
          print('📅 [API CLIENT] First appointment PetId (PascalCase) from JSON: ${firstItem['PetId']} (type: ${firstItem['PetId']?.runtimeType})');
          print('📅 [API CLIENT] First appointment full JSON: $firstItem');
          
          // Try both camelCase and PascalCase
          final petIdValue = firstItem['petId'] ?? firstItem['PetId'];
          print('📅 [API CLIENT] petId value (trying both): $petIdValue');
        }
      }
      
      final appointments = (response.data as List).map((json) {
        print('📅 [API CLIENT] Parsing appointment JSON: $json');
        final appointment = Appointment.fromJson(json);
        print('📅 [API CLIENT] Parsed appointment ID: ${appointment.id}, petId: ${appointment.petId}');
        return appointment;
      }).toList();
      
      print('📅 [API CLIENT] Total appointments parsed: ${appointments.length}');
      return appointments;
    } on DioException catch (e) {
      print('❌ [API CLIENT] getAppointments error: ${e.message}');
      print('❌ [API CLIENT] Response: ${e.response?.data}');
      throw _handleError(e);
    }
  }

  Future<List<Appointment>> getMyAppointments() async {
    try {
      final response = await dio.get('/appointments');
      return (response.data as List).map((json) => Appointment.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/appointments', data: data);
      return Appointment.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> completeAppointment(int id, {double? actualCost, String? notes}) async {
    try {
      await dio.patch('/appointments/$id/complete', data: {
        'actualCost': actualCost ?? 0.0,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Pet>> getUserPets(int userId) async {
    try {
      final response = await dio.get('/pets/owner/$userId');
      final data = response.data as List;
      
      final limitedData = data.take(20).toList();
      
      return limitedData.map((json) => Pet.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Appointment>> getUserAppointments(int userId) async {
    try {
      final response = await dio.get('/appointments/user/$userId');
      final data = response.data as List;
      
      final limitedData = data.take(50).toList();
      
      return limitedData.map((json) => Appointment.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Appointment> bookAppointment(Map<String, dynamic> data) async {
    try {
      print('Booking appointment with data: $data');
      final response = await dio.post('/appointments', data: data);
      print('Appointment booked successfully: ${response.statusCode}');
      print('Response data: ${response.data}');
      return Appointment.fromJson(response.data);
    } on DioException catch (e) {
      print('Appointment booking error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    try {
      print('Cancelling appointment $appointmentId');
      await dio.patch('/appointments/$appointmentId/cancel');
      print('Appointment cancelled successfully');
    } on DioException catch (e) {
      print('Cancel appointment error: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<void> markAppointmentAsPaid(int appointmentId, {String? paymentMethod, String? transactionId}) async {
    print('💳 [API CLIENT] Marking appointment as paid...');
    print('💳 [API CLIENT] Appointment ID: $appointmentId');
    print('💳 [API CLIENT] Payment method: ${paymentMethod ?? 'Stripe'}');
    print('💳 [API CLIENT] Transaction ID: $transactionId');
    
    try {
      final requestData = {
        'paymentMethod': paymentMethod ?? 'Stripe',
        'paymentTransactionId': transactionId,
        // Amount se ne šalje jer backend automatski određuje iz Service ili EstimatedCost
      };
      print('💳 [API CLIENT] Request data: $requestData');
      print('💳 [API CLIENT] Sending PATCH request to /appointments/$appointmentId/mark-paid');
      
      final response = await dio.patch('/appointments/$appointmentId/mark-paid', data: requestData);
      
      print('✅ [API CLIENT] Appointment marked as paid successfully');
      print('💳 [API CLIENT] Response status: ${response.statusCode}');
      print('💳 [API CLIENT] Response data: ${response.data}');
    } on DioException catch (e) {
      print('❌ [API CLIENT] Mark as paid error occurred');
      print('❌ [API CLIENT] Error message: ${e.message}');
      print('❌ [API CLIENT] Error type: ${e.type}');
      print('❌ [API CLIENT] Response status: ${e.response?.statusCode}');
      print('❌ [API CLIENT] Response data: ${e.response?.data}');
      print('❌ [API CLIENT] Request path: ${e.requestOptions.path}');
      print('❌ [API CLIENT] Request data: ${e.requestOptions.data}');
      throw _handleError(e);
    } catch (e) {
      print('❌ [API CLIENT] Unexpected error marking appointment as paid: $e');
      print('❌ [API CLIENT] Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Reviews
  Future<void> createVeterinarianReview({
    required int veterinarianId,
    required int rating,
    String? title,
    String? comment,
    String? petName,
    String? petSpecies,
  }) async {
    try {
      await dio.post('/reviews/veterinarian/$veterinarianId', data: {
        'rating': rating,
        'title': title,
        'comment': comment,
        'petName': petName,
        'petSpecies': petSpecies,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAllReviews() async {
    try {
      final response = await dio.get('/reviews/all');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['\$values'] is List) {
        return List<Map<String, dynamic>>.from(data['\$values']);
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteReview(int id) async {
    try {
      await dio.delete('/reviews/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Pet> addPet(Map<String, dynamic> petData) async {
    try {
      print('Adding pet with data: $petData');
      final response = await dio.post('/pets/my', data: petData);
      print('Pet added successfully: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiError(message: response.data?['message'] ?? 'Add pet failed');
      }
      
      if (response.data == null) {
        throw ApiError(message: 'Prazan odgovor sa servera');
      }
      
      return Pet.fromJson(response.data);
    } on DioException catch (e) {
      print('Add pet error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }


  Future<List<Map<String, dynamic>>> getServices({String? species}) async {
    try {
      print('🔍 [API] Fetching services...');
      if (species != null) {
        print('🔍 [API] Species parameter: "$species"');
        print('🔍 [API] Encoded species: "${Uri.encodeComponent(species)}"');
      }
      final url = species != null 
          ? '/Service?species=${Uri.encodeComponent(species)}'
          : '/Service';
      print('🔍 [API] Full URL: $url');
      final response = await dio.get(url);
      print('✅ [API] Services response status: ${response.statusCode}');
      print('✅ [API] Services response data type: ${response.data.runtimeType}');
      if (response.data is List) {
        final services = List<Map<String, dynamic>>.from(response.data);
        print('✅ [API] Received ${services.length} services');
        if (services.isNotEmpty && species != null) {
          print('💰 [API] First service price for species "$species": ${services[0]['price']}');
        }
        return services;
      } else {
        print('❌ [API] Services response is not a List, it is: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      print('❌ [API] Get services error: ${e.message}');
      print('❌ [API] Get services error response: ${e.response?.data}');
      print('❌ [API] Get services error status: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e) {
      print('❌ [API] Get services unexpected error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getService(int id, {String? species}) async {
    try {
      final url = species != null 
          ? '/Service/$id?species=${Uri.encodeComponent(species)}'
          : '/Service/$id';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } on DioException catch (e) {
      print('Get service error: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getVeterinarians() async {
    try {
      print('Fetching veterinarians...');
      final response = await dio.get('/User/veterinarians');
      print('Veterinarians response status: ${response.statusCode}');
      print('Veterinarians response data type: ${response.data.runtimeType}');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        print('Veterinarians response is not a List, it is: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      print('Get veterinarians error: ${e.message}');
      print('Get veterinarians error response: ${e.response?.data}');
      print('Get veterinarians error status: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e) {
      print('Get veterinarians unexpected error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('Fetching all users...');
      final response = await dio.get('/User');
      print('Users response status: ${response.statusCode}');
      print('Users response data type: ${response.data.runtimeType}');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        print('Users response is not a List, it is: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      print('Get users error: ${e.message}');
      print('Get users error response: ${e.response?.data}');
      print('Get users error status: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e) {
      print('Get users unexpected error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPetOwners() async {
    try {
      print('Fetching pet owners...');
      final users = await getAllUsers();
      final petOwners = users.where((user) {
        final role = user['role'];
        if (role is int) {
          return role == 1; // PetOwner = 1
        } else if (role is String) {
          return role.toLowerCase() == 'petowner' || role.toLowerCase() == 'pet owner';
        }
        return false;
      }).toList();
      
      print('Found ${petOwners.length} pet owners');
      return petOwners;
    } catch (e) {
      print('Get pet owners error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      print('Updating user $userId with data: $data');
      final response = await dio.put('/User/$userId', data: data);
      print('Update user response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Update user error: ${e.message}');
      print('Update user error response: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('Update user unexpected error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentVeterinarian(int userId) async {
    try {
      print('Fetching current veterinarian for user $userId...');
      final response = await dio.get('/User/$userId/current-veterinarian');
      print('Current veterinarian response status: ${response.statusCode}');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print('Get current veterinarian error: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<List<String>> getAvailableTimeSlots(int veterinarianId, String date) async {
    try {
      print('Fetching available time slots for vet $veterinarianId on $date');
      final response = await dio.get('/appointments/available-slots', queryParameters: {
        'veterinarianId': veterinarianId,
        'date': date,
      });
      print('Available slots response status: ${response.statusCode}');
      return List<String>.from(response.data);
    } on DioException catch (e) {
      print('Get available slots error: ${e.message}');
      throw _handleError(e);
    }
  }

  ApiError _handleError(DioException e) {
    String message = 'Neočekivana greška';
    int? statusCode = e.response?.statusCode;

    if (e.response?.data != null) {
      if (e.response!.data is Map<String, dynamic>) {
        message = e.response!.data['message'] ?? message;
      } else if (e.response!.data is String) {
        message = e.response!.data;
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Vreme konekcije je isteklo';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Vreme odgovora je isteklo';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Greška konekcije sa serverom';
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      details: e.toString(),
    );
  }
}
