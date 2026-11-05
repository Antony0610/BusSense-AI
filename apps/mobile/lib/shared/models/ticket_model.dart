/// Digital Boarding Pass (Ticket) Model
class TicketModel {
  final String id;
  final String ticketNumber;
  final String passengerName;
  final String busNumber;
  final String routeNumber;
  final String originStop;
  final String destinationStop;
  final double fareAmount;
  final double finalFare;
  final String status; // "BOOKED", "VALID", "USED", "EXPIRED", "CANCELLED"
  final String qrCodeHash;
  final String qrCodeDataUri;
  final String validFrom;
  final String validUntil;
  final String createdAt;
  final String dataOrigin;

  const TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.passengerName,
    required this.busNumber,
    required this.routeNumber,
    required this.originStop,
    required this.destinationStop,
    required this.fareAmount,
    required this.finalFare,
    required this.status,
    required this.qrCodeHash,
    required this.qrCodeDataUri,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
    this.dataOrigin = 'LIVE DATA',
  });

  String get qrData => qrCodeHash;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String? ?? '',
      ticketNumber: json['ticket_number'] as String? ?? '',
      passengerName: json['passenger_name'] as String? ?? 'Passenger',
      busNumber: json['bus_number'] as String? ?? '205',
      routeNumber: json['route_number'] as String? ?? '12',
      originStop: json['origin_stop'] as String? ?? '',
      destinationStop: json['destination_stop'] as String? ?? '',
      fareAmount: (json['fare_amount'] as num?)?.toDouble() ?? 20.0,
      finalFare: (json['final_fare'] as num?)?.toDouble() ?? 20.0,
      status: json['status'] as String? ?? 'BOOKED',
      qrCodeHash: json['qr_code_hash'] as String? ?? json['qr_data'] as String? ?? '',
      qrCodeDataUri: json['qr_code_data_uri'] as String? ?? '',
      validFrom: json['valid_from'] as String? ?? '',
      validUntil: json['valid_until'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      dataOrigin: json['data_origin'] as String? ?? 'LIVE DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_number': ticketNumber,
        'passenger_name': passengerName,
        'bus_number': busNumber,
        'route_number': routeNumber,
        'origin_stop': originStop,
        'destination_stop': destinationStop,
        'fare_amount': fareAmount,
        'final_fare': finalFare,
        'status': status,
        'qr_code_hash': qrCodeHash,
        'qr_code_data_uri': qrCodeDataUri,
        'valid_from': validFrom,
        'valid_until': validUntil,
        'created_at': createdAt,
        'data_origin': dataOrigin,
      };
}
