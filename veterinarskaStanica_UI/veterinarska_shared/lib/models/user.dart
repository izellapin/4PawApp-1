import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole {
  petOwner,
  veterinarian,
  veterinaryTechnician,
  receptionist,
  admin,
}

@JsonSerializable()
class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? address;
  final UserRole role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Veterinarian specific fields
  final String? licenseNumber;
  final String? specialization;
  final int? yearsOfExperience;
  final String? biography;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.address,
    required this.role,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    this.updatedAt,
    this.licenseNumber,
    this.specialization,
    this.yearsOfExperience,
    this.biography,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}







