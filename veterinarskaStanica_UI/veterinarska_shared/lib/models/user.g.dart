// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  phoneNumber: json['phoneNumber'] as String?,
  address: json['address'] as String?,
  role: $enumDecode(_$UserRoleEnumMap, json['role']),
  isActive: json['isActive'] as bool,
  isEmailVerified: json['isEmailVerified'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  licenseNumber: json['licenseNumber'] as String?,
  specialization: json['specialization'] as String?,
  yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt(),
  biography: json['biography'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'address': instance.address,
  'role': _$UserRoleEnumMap[instance.role]!,
  'isActive': instance.isActive,
  'isEmailVerified': instance.isEmailVerified,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'licenseNumber': instance.licenseNumber,
  'specialization': instance.specialization,
  'yearsOfExperience': instance.yearsOfExperience,
  'biography': instance.biography,
};

const _$UserRoleEnumMap = {
  UserRole.petOwner: 'petOwner',
  UserRole.veterinarian: 'veterinarian',
  UserRole.veterinaryTechnician: 'veterinaryTechnician',
  UserRole.receptionist: 'receptionist',
  UserRole.admin: 'admin',
};
