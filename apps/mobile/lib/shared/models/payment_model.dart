/// Payment Transaction Audit Model
class PaymentModel {
  final String id;
  final String ticketId;
  final double amount;
  final String currency;
  final String provider;
  final String status;
  final String? transactionReference;
  final String createdAt;
  final String dataOrigin;

  const PaymentModel({
    required this.id,
    required this.ticketId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    this.transactionReference,
    required this.createdAt,
    this.dataOrigin = 'SIMULATED DATA',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String? ?? '',
      ticketId: json['ticket_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 20.0,
      currency: json['currency'] as String? ?? 'INR',
      provider: json['provider'] as String? ?? 'SANDBOX',
      status: json['status'] as String? ?? 'SUCCESS',
      transactionReference: json['transaction_reference'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      dataOrigin: json['data_origin'] as String? ?? 'SIMULATED DATA',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_id': ticketId,
        'amount': amount,
        'currency': currency,
        'provider': provider,
        'status': status,
        'transaction_reference': transactionReference,
        'created_at': createdAt,
        'data_origin': dataOrigin,
      };
}
