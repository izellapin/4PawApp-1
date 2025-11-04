import 'package:json_annotation/json_annotation.dart';

part 'pet.g.dart';

enum PetGender {
  male,
  female,
}

enum PetStatus {
  active,
  inactive,
  deceased,
}

@JsonSerializable()
class Pet {
  final int id;
  final String name;
  final String species;
  final String? breed;
  final PetGender gender;
  final DateTime? dateOfBirth;
  final double? weight;
  final String? color;
  final String? microchipNumber;
  final PetStatus status;
  final String? notes;
  final int ownerId;
  final String? ownerName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    required this.gender,
    this.dateOfBirth,
    this.weight,
    this.color,
    this.microchipNumber,
    required this.status,
    this.notes,
    required this.ownerId,
    this.ownerName,
    required this.createdAt,
    this.updatedAt,
  });

  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    final age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      return age - 1;
    }
    return age;
  }

  String get displayInfo => '$name ($species)';

  String get genderText {
    switch (gender) {
      case PetGender.male:
        return 'Muški';
      case PetGender.female:
        return 'Ženski';
    }
  }

  String get ageText {
    final age = ageInYears;
    if (age == null) return 'Nepoznato';
    if (age == 0) return 'Mlađi od godinu dana';
    if (age == 1) return '1 godina';
    if (age < 5) return '$age godine';
    return '$age godina';
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    try {
      // Handle gender enum conversion
      PetGender gender = PetGender.male;
      final genderValue = json['gender'];
      if (genderValue is int) {
        gender = genderValue == 1 ? PetGender.male : PetGender.female;
      } else if (genderValue is String) {
        gender = genderValue.toLowerCase() == 'male' ? PetGender.male : PetGender.female;
      }

      // Handle status enum conversion
      PetStatus status = PetStatus.active;
      final statusValue = json['status'];
      if (statusValue is int) {
        switch (statusValue) {
          case 1:
            status = PetStatus.active;
            break;
          case 2:
            status = PetStatus.inactive;
            break;
          case 3:
            status = PetStatus.deceased;
            break;
        }
      } else if (statusValue is String) {
        switch (statusValue.toLowerCase()) {
          case 'active':
            status = PetStatus.active;
            break;
          case 'inactive':
            status = PetStatus.inactive;
            break;
          case 'deceased':
            status = PetStatus.deceased;
            break;
        }
      }

      return Pet(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        species: json['species'] as String? ?? '',
        breed: json['breed'] as String?,
        gender: gender,
        dateOfBirth: json['dateOfBirth'] != null 
            ? DateTime.tryParse(json['dateOfBirth'].toString()) 
            : null,
        weight: json['weight'] != null 
            ? (json['weight'] as num).toDouble() 
            : null,
        color: json['color'] as String?,
        microchipNumber: json['microchipNumber'] as String?,
        status: status,
        notes: json['notes'] as String?,
        ownerId: json['petOwnerId'] as int? ?? json['ownerId'] as int? ?? 0,
        ownerName: json['petOwner']?['firstName'] != null && json['petOwner']?['lastName'] != null
            ? '${json['petOwner']['firstName']} ${json['petOwner']['lastName']}'
            : json['ownerName'] as String?,
        createdAt: DateTime.parse(json['dateCreated']?.toString() ?? json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
        updatedAt: json['dateModified'] != null 
            ? DateTime.tryParse(json['dateModified'].toString()) 
            : json['updatedAt'] != null 
                ? DateTime.tryParse(json['updatedAt'].toString()) 
                : null,
      );
    } catch (e) {
      print('Error parsing Pet: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$PetToJson(this);
}
