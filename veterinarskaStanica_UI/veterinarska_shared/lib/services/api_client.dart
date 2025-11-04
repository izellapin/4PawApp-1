import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../models/pet.dart';
import '../models/appointment.dart';
import 'network_config.dart';

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
            print('Token refresh failed - user needs to login again');
            
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

  Future<AuthResponse> login(String email, String password) async {
    try {
      print('Attempting login for: $email');
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
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
      // Mobile users (pet owners) update their own pets via /pets/my/{id}
      final response = await dio.put('/pets/my/$id', data: data);
      
      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: $response.data');
      
      if (response.statusCode != 200) {
        final resp = response.data;
        if (resp is Map<String, dynamic>) {
          throw ApiError(message: resp['message'] ?? 'Update failed', statusCode: response.statusCode);
        } else if (resp is String) {
          throw ApiError(message: resp, statusCode: response.statusCode);
        } else {
          throw ApiError(message: 'Update failed', statusCode: response.statusCode);
        }
      }
      
      if (response.data == null) {
        throw ApiError(message: 'Prazan odgovor sa servera');
      }
      
      if (response.data is! Map<String, dynamic>) {
        throw ApiError(message: 'Neocekivani format odgovora: ${response.data.runtimeType}');
      }
      
      return Pet.fromJson(response.data);
    } on DioException catch (e) {
      print('Update pet error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error in updatePet: $e');
      throw ApiError(message: e.toString());
    }
  }

  Future<void> deletePet(int id) async {
    try {
      // Mobile users (pet owners) delete their own pets via /pets/my/{id}
      final response = await dio.delete('/pets/my/$id');
    } on DioException catch (e) {
      print('Delete pet error: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final response = await dio.get('/appointments');
      return (response.data as List).map((json) => Appointment.fromJson(json)).toList();
    } on DioException catch (e) {
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
    try {
      print('Marking appointment $appointmentId as paid');
      await dio.patch('/appointments/$appointmentId/mark-paid', data: {
        'paymentMethod': paymentMethod ?? 'Stripe',
        'paymentTransactionId': transactionId,
      });
      print('Appointment marked as paid successfully');
    } on DioException catch (e) {
      print('Mark as paid error: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');
      throw _handleError(e);
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


  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      print('Fetching services...');
      final response = await dio.get('/Service');
      print('Services response status: ${response.statusCode}');
      print('Services response data type: ${response.data.runtimeType}');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        print('Services response is not a List, it is: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      print('Get services error: ${e.message}');
      print('Get services error response: ${e.response?.data}');
      print('Get services error status: ${e.response?.statusCode}');
      throw _handleError(e);
    } catch (e) {
      print('Get services unexpected error: $e');
      rethrow;
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
