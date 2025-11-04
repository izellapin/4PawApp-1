import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/financial_data.dart';
import 'service_locator.dart';

class FinancialService {

  Future<FinancialSummary> getAdminFinancialSummary() async {
    try {
      print('Pozivam API: /financial/admin/financial-summary');
      print('Base URL: ${serviceLocator.apiClient.baseUrl}');
      final token = await serviceLocator.authService.getAccessToken();
      print('Token: ${token?.substring(0, 20)}...');
      print('Full token: $token');
      print('Token length: ${token?.length}');
      print('Token starts with: ${token?.substring(0, 10)}');
      
      final response = await serviceLocator.apiClient.dio.get(
        '/financial/admin/financial-summary',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.data}');
      print('Response headers: ${response.headers}');
      print('Response type: ${response.data.runtimeType}');
      print('Full response: $response');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Parsed JSON: $data');
        final summary = FinancialSummary.fromJson(data);
        print('Daily revenue data count: ${summary.dailyRevenueData.length}');
        if (summary.dailyRevenueData.isNotEmpty) {
          print('First daily revenue: ${summary.dailyRevenueData.first.date} - ${summary.dailyRevenueData.first.revenue}');
          print('Last daily revenue: ${summary.dailyRevenueData.last.date} - ${summary.dailyRevenueData.last.revenue}');
        }
        return summary;
      } else {
        print('API Error: ${response.statusCode} - ${response.data}');
        throw Exception('Neuspješno učitavanje finansijskog izvještaja: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error loading financial data: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Neuspješno učitavanje finansijskog izvještaja: $e');
    }
  }

  Future<List<RevenueByService>> getAdminRevenueByServices() async {
    try {
      print('Pozivam API: /financial/admin/revenue-by-services');
      final token = await serviceLocator.authService.getAccessToken();
      print('Token: ${token?.substring(0, 20)}...');
      
      final response = await serviceLocator.apiClient.dio.get(
        '/financial/admin/revenue-by-services',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        print('Parsed JSON: $data');
        final revenueByServices = data.map((item) => RevenueByService.fromJson(item)).toList();
        print('Revenue by services count: ${revenueByServices.length}');
        return revenueByServices;
      } else {
        print('API Error: ${response.statusCode} - ${response.data}');
        throw Exception('Neuspješno učitavanje prihoda po uslugama: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error loading revenue by services: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Neuspješno učitavanje prihoda po uslugama: $e');
    }
  }

  Future<VeterinarianStats> getVeterinarianStats() async {
    try {
      final token = await serviceLocator.authService.getAccessToken();
      print('Token for stats request: ${token?.substring(0, 20)}...');
      
      if (token == null || token.isEmpty) {
        throw Exception('Niste prijavljeni. Molimo prijavite se ponovo.');
      }
      
      // Učitaj osnovne statistike
      final statsResponse = await serviceLocator.apiClient.dio.get(
        '/financial/veterinarian/my-stats',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (statsResponse.statusCode != 200) {
        print('API Error: ${statsResponse.statusCode} - ${statsResponse.data}');
        String errorMessage = 'Neuspješno učitavanje veterinarskih statistika';
        if (statsResponse.statusCode == 500) {
          errorMessage = 'Greška na serveru. Molimo pokušajte ponovo kasnije.';
        } else if (statsResponse.statusCode == 401) {
          errorMessage = 'Niste autorizovani. Molimo prijavite se ponovo.';
        } else if (statsResponse.statusCode == 403) {
          errorMessage = 'Nemate dozvole za pristup ovim podacima.';
        }
        throw Exception('$errorMessage (${statsResponse.statusCode})');
      }

      final statsData = statsResponse.data;
      
      // Učitaj dnevne termine
      final dailyResponse = await serviceLocator.apiClient.dio.get(
        '/financial/veterinarian/daily-appointments',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Daily appointments response: ${dailyResponse.statusCode} - ${dailyResponse.data}');

      // Učitaj top usluge
      final servicesResponse = await serviceLocator.apiClient.dio.get(
        '/financial/veterinarian/top-services',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Top services response: ${servicesResponse.statusCode} - ${servicesResponse.data}');

      // Dodaj dodatne podatke u statsData
      if (dailyResponse.statusCode == 200) {
        statsData['dailyAppointments'] = dailyResponse.data;
        print('Daily appointments loaded: ${statsData['dailyAppointments']}');
      } else {
        print('Daily appointments failed: ${dailyResponse.statusCode}');
        statsData['dailyAppointments'] = [];
      }
      
      if (servicesResponse.statusCode == 200) {
        statsData['topServices'] = servicesResponse.data;
        print('Top services loaded: ${statsData['topServices']}');
      } else {
        print('Top services failed: ${servicesResponse.statusCode}');
        statsData['topServices'] = [];
      }

      return VeterinarianStats.fromJson(statsData);
    } catch (e) {
      print('Error loading veterinarian data: $e');
      throw Exception('Neuspješno učitavanje veterinarskih statistika: $e');
    }
  }

  Future<void> downloadFinancialReportPdf() async {
    try {
      final token = await serviceLocator.authService.getAccessToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('Niste prijavljeni. Molimo prijavite se ponovo.');
      }

      final response = await serviceLocator.apiClient.dio.get(
        '/financial/admin/financial-report-pdf',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        // Za Flutter desktop, korisnik će morati sam da sačuva fajl
        // ili možemo koristiti file_picker ili path_provider
        throw Exception('PDF je preuzet. Molimo implementirajte čuvanje fajla.');
      } else {
        throw Exception('Neuspješno preuzimanje PDF izvještaja: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      throw Exception('Neuspješno preuzimanje PDF izvještaja: $e');
    }
  }

  Future<Uint8List> getFinancialReportPdfBytes() async {
    try {
      final token = await serviceLocator.authService.getAccessToken();
      
      if (token == null || token.isEmpty) {
        throw Exception('Niste prijavljeni. Molimo prijavite se ponovo.');
      }

      print('Pozivam API: /financial/admin/financial-report-pdf');
      print('Base URL: ${serviceLocator.apiClient.baseUrl}');
      final response = await serviceLocator.apiClient.dio.get(
        '/financial/admin/financial-report-pdf',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf',
          },
          responseType: ResponseType.bytes,
        ),
      );

      print('PDF response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      } else {
        throw Exception('Neuspješno preuzimanje PDF izvještaja: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      throw Exception('Neuspješno preuzimanje PDF izvještaja: $e');
    }
  }
}










