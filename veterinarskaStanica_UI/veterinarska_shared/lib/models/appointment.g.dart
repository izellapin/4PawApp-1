// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
  id: (json['id'] as num).toInt(),
  appointmentNumber: json['appointmentNumber'] as String,
  appointmentDate: DateTime.parse(json['appointmentDate'] as String),
  startTime: json['startTime'] as String,
  endTime: json['endTime'] as String,
  type: $enumDecode(_$AppointmentTypeEnumMap, json['type']),
  status: $enumDecode(_$AppointmentStatusEnumMap, json['status']),
  reason: json['reason'] as String?,
  notes: json['notes'] as String?,
  estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
  actualCost: (json['actualCost'] as num?)?.toDouble(),
  petId: (json['petId'] as num).toInt(),
  petName: json['petName'] as String?,
  veterinarianId: (json['veterinarianId'] as num).toInt(),
  veterinarianName: json['veterinarianName'] as String?,
  serviceId: (json['serviceId'] as num?)?.toInt(),
  serviceName: json['serviceName'] as String?,
  ownerName: json['ownerName'] as String?,
  isPaid: json['isPaid'] as bool? ?? false,
  paymentDate: json['paymentDate'] == null
      ? null
      : DateTime.parse(json['paymentDate'] as String),
  paymentMethod: json['paymentMethod'] as String?,
  paymentTransactionId: json['paymentTransactionId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appointmentNumber': instance.appointmentNumber,
      'appointmentDate': instance.appointmentDate.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'type': _$AppointmentTypeEnumMap[instance.type]!,
      'status': _$AppointmentStatusEnumMap[instance.status]!,
      'reason': instance.reason,
      'notes': instance.notes,
      'estimatedCost': instance.estimatedCost,
      'actualCost': instance.actualCost,
      'petId': instance.petId,
      'petName': instance.petName,
      'veterinarianId': instance.veterinarianId,
      'veterinarianName': instance.veterinarianName,
      'serviceId': instance.serviceId,
      'serviceName': instance.serviceName,
      'ownerName': instance.ownerName,
      'isPaid': instance.isPaid,
      'paymentDate': instance.paymentDate?.toIso8601String(),
      'paymentMethod': instance.paymentMethod,
      'paymentTransactionId': instance.paymentTransactionId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$AppointmentTypeEnumMap = {
  AppointmentType.checkup: 'checkup',
  AppointmentType.vaccination: 'vaccination',
  AppointmentType.surgery: 'surgery',
  AppointmentType.emergency: 'emergency',
  AppointmentType.grooming: 'grooming',
  AppointmentType.dental: 'dental',
  AppointmentType.consultation: 'consultation',
  AppointmentType.followUp: 'followUp',
};

const _$AppointmentStatusEnumMap = {
  AppointmentStatus.scheduled: 'scheduled',
  AppointmentStatus.confirmed: 'confirmed',
  AppointmentStatus.inProgress: 'inProgress',
  AppointmentStatus.completed: 'completed',
  AppointmentStatus.cancelled: 'cancelled',
  AppointmentStatus.noShow: 'noShow',
  AppointmentStatus.rescheduled: 'rescheduled',
};
