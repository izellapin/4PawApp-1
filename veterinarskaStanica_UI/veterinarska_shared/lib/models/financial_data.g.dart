// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinancialSummary _$FinancialSummaryFromJson(
  Map<String, dynamic> json,
) => FinancialSummary(
  dailyRevenue: (json['dailyRevenue'] as num).toDouble(),
  monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
  dailyAppointments: (json['dailyAppointments'] as num).toInt(),
  averageAppointmentCost: (json['averageAppointmentCost'] as num).toDouble(),
  monthlyGrowthPercentage: (json['monthlyGrowthPercentage'] as num).toDouble(),
  yearlyGrowthPercentage: (json['yearlyGrowthPercentage'] as num).toDouble(),
  revenueByService: (json['revenueByService'] as List<dynamic>)
      .map((e) => RevenueByService.fromJson(e as Map<String, dynamic>))
      .toList(),
  dailyRevenueData: (json['dailyRevenueData'] as List<dynamic>)
      .map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
      .toList(),
  topClients: (json['topClients'] as List<dynamic>)
      .map((e) => TopClient.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FinancialSummaryToJson(FinancialSummary instance) =>
    <String, dynamic>{
      'dailyRevenue': instance.dailyRevenue,
      'monthlyRevenue': instance.monthlyRevenue,
      'dailyAppointments': instance.dailyAppointments,
      'averageAppointmentCost': instance.averageAppointmentCost,
      'monthlyGrowthPercentage': instance.monthlyGrowthPercentage,
      'yearlyGrowthPercentage': instance.yearlyGrowthPercentage,
      'revenueByService': instance.revenueByService,
      'dailyRevenueData': instance.dailyRevenueData,
      'topClients': instance.topClients,
    };

RevenueByService _$RevenueByServiceFromJson(Map<String, dynamic> json) =>
    RevenueByService(
      serviceName: json['serviceName'] as String,
      revenue: (json['revenue'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$RevenueByServiceToJson(RevenueByService instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'revenue': instance.revenue,
      'count': instance.count,
    };

DailyRevenue _$DailyRevenueFromJson(Map<String, dynamic> json) => DailyRevenue(
  date: DateTime.parse(json['date'] as String),
  revenue: (json['revenue'] as num).toDouble(),
);

Map<String, dynamic> _$DailyRevenueToJson(DailyRevenue instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'revenue': instance.revenue,
    };

TopClient _$TopClientFromJson(Map<String, dynamic> json) => TopClient(
  name: json['name'] as String,
  totalSpent: (json['totalSpent'] as num).toDouble(),
  appointmentCount: (json['appointmentCount'] as num).toInt(),
);

Map<String, dynamic> _$TopClientToJson(TopClient instance) => <String, dynamic>{
  'name': instance.name,
  'totalSpent': instance.totalSpent,
  'appointmentCount': instance.appointmentCount,
};

VeterinarianStats _$VeterinarianStatsFromJson(Map<String, dynamic> json) =>
    VeterinarianStats(
      todayAppointments: (json['todayAppointments'] as num).toInt(),
      monthlyAppointments: (json['monthlyAppointments'] as num).toInt(),
      monthlyRevenue: (json['monthlyRevenue'] as num).toDouble(),
      averageAppointmentCost: (json['averageAppointmentCost'] as num)
          .toDouble(),
      totalPatients: (json['totalPatients'] as num).toInt(),
      recentPatients: (json['recentPatients'] as List<dynamic>)
          .map((e) => PatientInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VeterinarianStatsToJson(VeterinarianStats instance) =>
    <String, dynamic>{
      'todayAppointments': instance.todayAppointments,
      'monthlyAppointments': instance.monthlyAppointments,
      'monthlyRevenue': instance.monthlyRevenue,
      'averageAppointmentCost': instance.averageAppointmentCost,
      'totalPatients': instance.totalPatients,
      'recentPatients': instance.recentPatients,
      'averageRating': instance.averageRating,
      'reviewCount': instance.reviewCount,
    };

PatientInfo _$PatientInfoFromJson(Map<String, dynamic> json) => PatientInfo(
  name: json['name'] as String,
  species: json['species'] as String,
  lastVisit: DateTime.parse(json['lastVisit'] as String),
  owner: json['owner'] as String,
);

Map<String, dynamic> _$PatientInfoToJson(PatientInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'species': instance.species,
      'lastVisit': instance.lastVisit.toIso8601String(),
      'owner': instance.owner,
    };
