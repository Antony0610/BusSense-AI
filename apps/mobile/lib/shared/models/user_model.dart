/// User Role Enum aligning with backend RBAC
enum UserRole {
  passenger('PASSENGER'),
  driverConductor('DRIVER_CONDUCTOR'),
  authority('AUTHORITY');

  final String value;
  const UserRole(this.value);

  String toBackendString() => value;

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'DRIVER_CONDUCTOR':
      case 'CONDUCTOR':
        return UserRole.driverConductor;
      case 'AUTHORITY':
      case 'ADMIN':
        return UserRole.authority;
      case 'PASSENGER':
      default:
        return UserRole.passenger;
    }
  }
}

/// Authenticated User Profile
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isActive;
  final String phoneNumber;
  final String preferredLanguage;
  final String accountStatus;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
    this.phoneNumber = '+91 98470 12345',
    this.preferredLanguage = 'en',
    this.accountStatus = 'ACTIVE',
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    bool? isActive,
    String? phoneNumber,
    String? preferredLanguage,
    String? accountStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'BusSense Commuter',
      role: UserRole.fromString(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      phoneNumber: json['phone_number'] as String? ?? '+91 98470 12345',
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      accountStatus: json['account_status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'role': role.value,
        'is_active': isActive,
        'phone_number': phoneNumber,
        'preferred_language': preferredLanguage,
        'account_status': accountStatus,
      };
}
