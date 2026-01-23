import 'dart:io';

class DeliveryRegistrationDraft {
  final String email;
  final String sessionToken;

  final String? fullName;
  final String? phone;
  final String? address;
  final String? vehicleType; // bike | car | scooter
  final String? vehicleNumber;
  final double? latitude;
  final double? longitude;
  final String? idProofType;

  final File? profileImageFile;
  final File? idProofDocumentFile;
  final File? drivingLicenseFile;

  const DeliveryRegistrationDraft({
    required this.email,
    required this.sessionToken,
    this.fullName,
    this.phone,
    this.address,
    this.vehicleType,
    this.vehicleNumber,
    this.latitude,
    this.longitude,
    this.idProofType,
    this.profileImageFile,
    this.idProofDocumentFile,
    this.drivingLicenseFile,
  });

  DeliveryRegistrationDraft copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? vehicleType,
    String? vehicleNumber,
    double? latitude,
    double? longitude,
    String? idProofType,
    File? profileImageFile,
    File? idProofDocumentFile,
    File? drivingLicenseFile,
  }) {
    return DeliveryRegistrationDraft(
      email: email,
      sessionToken: sessionToken,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      idProofType: idProofType ?? this.idProofType,
      profileImageFile: profileImageFile ?? this.profileImageFile,
      idProofDocumentFile: idProofDocumentFile ?? this.idProofDocumentFile,
      drivingLicenseFile: drivingLicenseFile ?? this.drivingLicenseFile,
    );
  }
}


