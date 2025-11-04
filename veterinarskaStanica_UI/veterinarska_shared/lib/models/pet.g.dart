// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pet _$PetFromJson(Map<String, dynamic> json) => Pet(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  species: json['species'] as String,
  breed: json['breed'] as String?,
  gender: $enumDecode(_$PetGenderEnumMap, json['gender']),
  dateOfBirth: json['dateOfBirth'] == null
      ? null
      : DateTime.parse(json['dateOfBirth'] as String),
  weight: (json['weight'] as num?)?.toDouble(),
  color: json['color'] as String?,
  microchipNumber: json['microchipNumber'] as String?,
  status: $enumDecode(_$PetStatusEnumMap, json['status']),
  notes: json['notes'] as String?,
  ownerId: (json['ownerId'] as num).toInt(),
  ownerName: json['ownerName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PetToJson(Pet instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'species': instance.species,
  'breed': instance.breed,
  'gender': _$PetGenderEnumMap[instance.gender]!,
  'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
  'weight': instance.weight,
  'color': instance.color,
  'microchipNumber': instance.microchipNumber,
  'status': _$PetStatusEnumMap[instance.status]!,
  'notes': instance.notes,
  'ownerId': instance.ownerId,
  'ownerName': instance.ownerName,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$PetGenderEnumMap = {PetGender.male: 'male', PetGender.female: 'female'};

const _$PetStatusEnumMap = {
  PetStatus.active: 'active',
  PetStatus.inactive: 'inactive',
  PetStatus.deceased: 'deceased',
};
