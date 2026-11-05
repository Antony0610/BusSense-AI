enum ValidationStatus {
  valid,
  invalid,
  alreadyUsed,
  expired;

  static ValidationStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'VALID':
        return ValidationStatus.valid;
      case 'ALREADY_USED':
      case 'ALREADY USED':
        return ValidationStatus.alreadyUsed;
      case 'EXPIRED':
        return ValidationStatus.expired;
      case 'INVALID':
      default:
        return ValidationStatus.invalid;
    }
  }

  String get displayLabel {
    switch (this) {
      case ValidationStatus.valid:
        return 'VALID';
      case ValidationStatus.invalid:
        return 'INVALID';
      case ValidationStatus.alreadyUsed:
        return 'ALREADY USED';
      case ValidationStatus.expired:
        return 'EXPIRED';
    }
  }
}

class TicketValidationResultModel {
  final ValidationStatus status;
  final bool isValid;
  final String? ticketNumber;
  final String? passengerName;
  final String? originStop;
  final String? destinationStop;
  final String message;
  final String validatedAt;
  final String rawResult;

  const TicketValidationResultModel({
    required this.status,
    required this.isValid,
    this.ticketNumber,
    this.passengerName,
    this.originStop,
    this.destinationStop,
    required this.message,
    required this.validatedAt,
    required this.rawResult,
  });

  factory TicketValidationResultModel.fromJson(Map<String, dynamic> json) {
    final raw = json['result'] as String? ?? 'INVALID';
    final isValid = json['is_valid'] as bool? ?? (raw == 'VALID');
    return TicketValidationResultModel(
      status: ValidationStatus.fromString(raw),
      isValid: isValid,
      ticketNumber: json['ticket_number'] as String?,
      passengerName: json['passenger_name'] as String?,
      originStop: json['origin_stop'] as String?,
      destinationStop: json['destination_stop'] as String?,
      message: json['message'] as String? ?? 'Validation complete.',
      validatedAt: json['validated_at'] as String? ?? DateTime.now().toIso8601String(),
      rawResult: raw,
    );
  }

  static TicketValidationResultModel mockValid({String ticketNumber = '#TKT-1042', String passengerName = 'Rahul Nair'}) {
    return TicketValidationResultModel(
      status: ValidationStatus.valid,
      isValid: true,
      ticketNumber: ticketNumber,
      passengerName: passengerName,
      originStop: 'Aluva Metro',
      destinationStop: 'Vyttila Mobility Hub',
      message: 'Boarding approved for passenger $passengerName.',
      validatedAt: DateTime.now().toIso8601String(),
      rawResult: 'VALID',
    );
  }

  static TicketValidationResultModel mockAlreadyUsed() {
    return TicketValidationResultModel(
      status: ValidationStatus.alreadyUsed,
      isValid: false,
      ticketNumber: '#TKT-9912',
      passengerName: 'Ananya S.',
      originStop: 'Edappally',
      destinationStop: 'Kaloor',
      message: 'This digital ticket has already been used and validated by a conductor.',
      validatedAt: DateTime.now().toIso8601String(),
      rawResult: 'ALREADY_USED',
    );
  }

  static TicketValidationResultModel mockExpired() {
    return TicketValidationResultModel(
      status: ValidationStatus.expired,
      isValid: false,
      ticketNumber: '#TKT-8840',
      passengerName: 'George Kurian',
      originStop: 'Kalamassery',
      destinationStop: 'MG Road',
      message: 'This ticket has expired past its boarding validity window.',
      validatedAt: DateTime.now().toIso8601String(),
      rawResult: 'EXPIRED',
    );
  }

  static TicketValidationResultModel mockInvalid() {
    return TicketValidationResultModel(
      status: ValidationStatus.invalid,
      isValid: false,
      message: 'Unrecognized or invalid QR ticket. No matching boarding record found.',
      validatedAt: DateTime.now().toIso8601String(),
      rawResult: 'INVALID',
    );
  }
}
