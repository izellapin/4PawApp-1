import 'package:json_annotation/json_annotation.dart';

part 'financial_data.g.dart';

@JsonSerializable()
class FinancialSummary {
  final double dailyRevenue;
  final double monthlyRevenue;
  final int dailyAppointments;
  final double averageAppointmentCost;
  final double monthlyGrowthPercentage;
  final double yearlyGrowthPercentage;
  final List<RevenueByService> revenueByService;
  final List<DailyRevenue> dailyRevenueData;
  final List<TopClient> topClients;

  FinancialSummary({
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.dailyAppointments,
    required this.averageAppointmentCost,
    required this.monthlyGrowthPercentage,
    required this.yearlyGrowthPercentage,
    required this.revenueByService,
    required this.dailyRevenueData,
    required this.topClients,
  });

  // Computed properties za kompatibilnost sa UI
  double get weeklyRevenue => monthlyRevenue * 0.25; // Aproksimacija
  double get yearlyRevenue => monthlyRevenue * 12; // Aproksimacija
  int get weeklyAppointments => (dailyAppointments * 7); // Aproksimacija
  int get monthlyAppointments => (dailyAppointments * 30); // Aproksimacija
  double get averageAppointmentValue => averageAppointmentCost;
  double get monthlyGrowth => monthlyGrowthPercentage;
  double get yearlyGrowth => yearlyGrowthPercentage;
  List<DailyRevenue> get dailyRevenueChart => dailyRevenueData;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    // Null-safety provjere za liste
    final revenueByService = json['revenueByService'] as List<dynamic>? ?? [];
    final dailyRevenueData = json['dailyRevenueData'] as List<dynamic>? ?? [];
    final topClients = json['topClients'] as List<dynamic>? ?? [];
    
    return FinancialSummary(
      dailyRevenue: (json['dailyRevenue'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      dailyAppointments: (json['dailyAppointments'] as num?)?.toInt() ?? 0,
      averageAppointmentCost: (json['averageAppointmentCost'] as num?)?.toDouble() ?? 0.0,
      monthlyGrowthPercentage: (json['monthlyGrowthPercentage'] as num?)?.toDouble() ?? 0.0,
      yearlyGrowthPercentage: (json['yearlyGrowthPercentage'] as num?)?.toDouble() ?? 0.0,
      revenueByService: revenueByService.map((e) => RevenueByService.fromJson(e as Map<String, dynamic>)).toList(),
      dailyRevenueData: dailyRevenueData.map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>)).toList(),
      topClients: topClients.map((e) => TopClient.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => _$FinancialSummaryToJson(this);
}

@JsonSerializable()
class RevenueByService {
  final String serviceName;
  final double revenue;
  final int count;

  RevenueByService({
    required this.serviceName,
    required this.revenue,
    required this.count,
  });

  // Computed properties za kompatibilnost sa UI
  int get appointmentCount => count;
  double get percentage => 0.0; // Ovo će biti izračunato u UI

  factory RevenueByService.fromJson(Map<String, dynamic> json) {
    return RevenueByService(
      serviceName: json['serviceName'] as String? ?? 'Nepoznata usluga',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$RevenueByServiceToJson(this);
}

@JsonSerializable()
class DailyRevenue {
  final DateTime date;
  final double revenue;

  DailyRevenue({
    required this.date,
    required this.revenue,
  });

  // Computed property za kompatibilnost sa UI
  int get appointments => (revenue / 150).round(); // Aproksimacija na osnovu prosečne cene

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => _$DailyRevenueToJson(this);
}

@JsonSerializable()
class TopClient {
  final String name;
  final double totalSpent;
  final int appointmentCount;

  TopClient({
    required this.name,
    required this.totalSpent,
    required this.appointmentCount,
  });

  // Computed properties za kompatibilnost sa UI
  String get clientName => name;
  String get email => '${name.toLowerCase().replaceAll(' ', '.')}@example.com';
  DateTime get lastVisit => DateTime.now().subtract(Duration(days: appointmentCount));

  factory TopClient.fromJson(Map<String, dynamic> json) {
    return TopClient(
      name: json['name'] as String? ?? 'Nepoznat klijent',
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      appointmentCount: (json['appointmentCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$TopClientToJson(this);
}

@JsonSerializable()
class VeterinarianStats {
  final int todayAppointments;
  final int monthlyAppointments;
  final double monthlyRevenue;
  final double averageAppointmentCost;
  final int totalPatients;
  final List<PatientInfo> recentPatients;
  final double averageRating; // Prosječan rating (1-5)
  final int reviewCount; // Broj review-ova

  VeterinarianStats({
    required this.todayAppointments,
    required this.monthlyAppointments,
    required this.monthlyRevenue,
    required this.averageAppointmentCost,
    required this.totalPatients,
    required this.recentPatients,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  // Computed properties za kompatibilnost sa UI
  int get myAppointmentsToday => todayAppointments;
  int get myAppointmentsWeek {
    if (_dailyAppointments == null || _dailyAppointments!.isEmpty) {
      return (monthlyAppointments * 0.25).round(); // Fallback na aproksimaciju
    }
    
    // Računaj stvarni broj termina za trenutnu sedmicu
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    int weeklyCount = 0;
    for (final appointment in _dailyAppointments!) {
      final appointmentDate = appointment.date;
      if (appointmentDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
          appointmentDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        // appointment.revenue je zapravo broj termina (videti DailyRevenue model)
        weeklyCount += appointment.appointments;
      }
    }
    
    return weeklyCount;
  }
  int get myTotalPatients => totalPatients;
  double get myAverageRating => averageRating; // Pravi rating iz baze
  List<DailyRevenue> get myDailyAppointments => _dailyAppointments ?? [];
  List<RevenueByService> get myTopServices => _topServices ?? [];
  List<PatientInfo> get myRecentPatients => recentPatients;

  // Privatna polja za dodatne podatke
  List<DailyRevenue>? _dailyAppointments;
  List<RevenueByService>? _topServices;

  // Metode za postavljanje dodatnih podataka
  void setDailyAppointments(List<DailyRevenue> appointments) {
    _dailyAppointments = appointments;
  }

  void setTopServices(List<RevenueByService> services) {
    _topServices = services;
  }

  factory VeterinarianStats.fromJson(Map<String, dynamic> json) {
    final stats = _$VeterinarianStatsFromJson(json);
    
    // Parsiraj dodatne podatke ako postoje
    if (json['dailyAppointments'] != null) {
      final dailyAppointments = (json['dailyAppointments'] as List)
          .map((e) => DailyRevenue.fromJson(e))
          .toList();
      stats.setDailyAppointments(dailyAppointments);
    }
    
    if (json['topServices'] != null) {
      final topServices = (json['topServices'] as List)
          .map((e) => RevenueByService.fromJson(e))
          .toList();
      stats.setTopServices(topServices);
    }
    
    return stats;
  }

  Map<String, dynamic> toJson() => _$VeterinarianStatsToJson(this);
}

@JsonSerializable()
class PatientInfo {
  final String name;
  final String species;
  final DateTime lastVisit;
  final String owner;

  PatientInfo({
    required this.name,
    required this.species,
    required this.lastVisit,
    required this.owner,
  });

  // Computed properties za kompatibilnost sa UI
  String get petName => name;
  String get ownerName => owner;
  String get lastService => 'Pregled'; // Mock vrednost

  factory PatientInfo.fromJson(Map<String, dynamic> json) =>
      _$PatientInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PatientInfoToJson(this);
}







