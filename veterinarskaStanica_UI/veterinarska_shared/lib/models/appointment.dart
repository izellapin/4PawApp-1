import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
  rescheduled,
}

enum AppointmentType {
  checkup,
  vaccination,
  surgery,
  emergency,
  grooming,
  dental,
  consultation,
  followUp,
}

@JsonSerializable()
class Appointment {
  final int id;
  final String appointmentNumber;
  final DateTime appointmentDate;
  final String startTime;
  final String endTime;
  final AppointmentType type;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final double? estimatedCost;
  final double? actualCost;
  final int petId;
  final String? petName;
  final int veterinarianId;
  final String? veterinarianName;
  final int? serviceId;
  final String? serviceName;
  final String? ownerName;
  final bool isPaid;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? paymentTransactionId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.appointmentNumber,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
    this.reason,
    this.notes,
    this.estimatedCost,
    this.actualCost,
    required this.petId,
    this.petName,
    required this.veterinarianId,
    this.veterinarianName,
    this.serviceId,
    this.serviceName,
    this.ownerName,
    this.isPaid = false,
    this.paymentDate,
    this.paymentMethod,
    this.paymentTransactionId,
    required this.createdAt,
    this.updatedAt,
  });

  String get timeRange => '$startTime - $endTime';
  
  String get formattedDate {
    return '${appointmentDate.day}.${appointmentDate.month}.${appointmentDate.year}';
  }

  String get statusText {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Zakazan';
      case AppointmentStatus.confirmed:
        return 'Potvrđen';
      case AppointmentStatus.inProgress:
        return 'U toku';
      case AppointmentStatus.completed:
        return 'Završen';
      case AppointmentStatus.cancelled:
        return 'Otkazan';
      case AppointmentStatus.noShow:
        return 'Nije se pojavio';
      case AppointmentStatus.rescheduled:
        return 'Prebačen';
    }
  }

  String get typeText {
    switch (type) {
      case AppointmentType.checkup:
        return 'Pregled';
      case AppointmentType.vaccination:
        return 'Vakcinacija';
      case AppointmentType.surgery:
        return 'Operacija';
      case AppointmentType.emergency:
        return 'Hitni slučaj';
      case AppointmentType.grooming:
        return 'Čišćenje';
      case AppointmentType.dental:
        return 'Stomatologija';
      case AppointmentType.consultation:
        return 'Konsultacija';
      case AppointmentType.followUp:
        return 'Kontrola';
    }
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    try {
      // Parse AppointmentType - handle both int and string values
      AppointmentType type;
      final typeValue = json['type'];
      if (typeValue is int) {
        // Backend sends 1-indexed enum values
        switch (typeValue) {
          case 1:
            type = AppointmentType.checkup;
            break;
          case 2:
            type = AppointmentType.vaccination;
            break;
          case 3:
            type = AppointmentType.surgery;
            break;
          case 4:
            type = AppointmentType.emergency;
            break;
          case 5:
            type = AppointmentType.grooming;
            break;
          case 6:
            type = AppointmentType.dental;
            break;
          case 7:
            type = AppointmentType.consultation;
            break;
          case 8:
            type = AppointmentType.followUp;
            break;
          default:
            type = AppointmentType.checkup;
        }
      } else if (typeValue is String) {
        // Handle string enum values
        switch (typeValue.toLowerCase()) {
          case 'checkup':
            type = AppointmentType.checkup;
            break;
          case 'vaccination':
            type = AppointmentType.vaccination;
            break;
          case 'surgery':
            type = AppointmentType.surgery;
            break;
          case 'emergency':
            type = AppointmentType.emergency;
            break;
          case 'grooming':
            type = AppointmentType.grooming;
            break;
          case 'dental':
            type = AppointmentType.dental;
            break;
          case 'consultation':
            type = AppointmentType.consultation;
            break;
          case 'followup':
          case 'follow_up':
            type = AppointmentType.followUp;
            break;
          default:
            type = AppointmentType.checkup;
        }
      } else {
        type = AppointmentType.checkup;
      }

      // Parse AppointmentStatus - handle both int and string values
      AppointmentStatus status;
      final statusValue = json['status'];
      if (statusValue is int) {
        // Backend sends 1-indexed enum values
        switch (statusValue) {
          case 1:
            status = AppointmentStatus.scheduled;
            break;
          case 2:
            status = AppointmentStatus.confirmed;
            break;
          case 3:
            status = AppointmentStatus.inProgress;
            break;
          case 4:
            status = AppointmentStatus.completed;
            break;
          case 5:
            status = AppointmentStatus.cancelled;
            break;
          case 6:
            status = AppointmentStatus.noShow;
            break;
          case 7:
            status = AppointmentStatus.rescheduled;
            break;
          default:
            status = AppointmentStatus.scheduled;
        }
      } else if (statusValue is String) {
        // Handle string enum values
        switch (statusValue.toLowerCase()) {
          case 'scheduled':
            status = AppointmentStatus.scheduled;
            break;
          case 'confirmed':
            status = AppointmentStatus.confirmed;
            break;
          case 'inprogress':
          case 'in_progress':
            status = AppointmentStatus.inProgress;
            break;
          case 'completed':
            status = AppointmentStatus.completed;
            break;
          case 'cancelled':
            status = AppointmentStatus.cancelled;
            break;
          case 'noshow':
          case 'no_show':
            status = AppointmentStatus.noShow;
            break;
          case 'rescheduled':
            status = AppointmentStatus.rescheduled;
            break;
          default:
            status = AppointmentStatus.scheduled;
        }
      } else {
        status = AppointmentStatus.scheduled;
      }

      return Appointment(
        id: json['id'] as int,
        appointmentNumber: json['appointmentNumber'] as String? ?? json['number'] as String? ?? '',
        appointmentDate: DateTime.parse(json['appointmentDate'] as String? ?? json['date'] as String? ?? DateTime.now().toIso8601String()),
        startTime: json['startTime'] as String? ?? json['start_time'] as String? ?? '09:00',
        endTime: json['endTime'] as String? ?? json['end_time'] as String? ?? '10:00',
        type: type,
        status: status,
        reason: json['reason'] as String?,
        notes: json['notes'] as String?,
        estimatedCost: json['estimatedCost'] != null ? (json['estimatedCost'] as num).toDouble() : null,
        actualCost: json['actualCost'] != null ? (json['actualCost'] as num).toDouble() : null,
        petId: json['petId'] as int? ?? 0,
        petName: json['petName'] as String? ?? json['pet']?['name'] as String?,
        veterinarianId: json['veterinarianId'] as int? ?? 0,
        veterinarianName: json['veterinarianName'] as String? ?? 
            (json['veterinarian']?['firstName'] != null 
                ? '${json['veterinarian']['firstName']} ${json['veterinarian']['lastName']}'
                : null),
        serviceId: json['serviceId'] as int?,
        serviceName: json['serviceName'] as String? ?? json['service']?['name'] as String?,
        ownerName: json['ownerName'] as String? ?? 
            (json['owner']?['firstName'] != null
                ? '${json['owner']['firstName']} ${json['owner']['lastName']}'
                : null),
        isPaid: json['isPaid'] as bool? ?? false,
        paymentDate: json['paymentDate'] != null ? DateTime.tryParse(json['paymentDate'] as String) : null,
        paymentMethod: json['paymentMethod'] as String?,
        paymentTransactionId: json['paymentTransactionId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String? ?? json['dateCreated'] as String? ?? DateTime.now().toIso8601String()),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.tryParse(json['updatedAt'] as String) 
            : json['dateModified'] != null 
                ? DateTime.tryParse(json['dateModified'] as String)
                : null,
      );
    } catch (e) {
      print('Error parsing Appointment: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
