class ToyyibpayPaymentResult {
  final String billCode;
  final String status; // 'success', 'failed', 'pending', etc.
  final Map<String, dynamic> raw;

  const ToyyibpayPaymentResult({
    required this.billCode,
    required this.status,
    required this.raw,
  });

  bool get isSuccess => status.toLowerCase() == 'success';
}

class ToyyibpayCheckoutException implements Exception {
  final String message;
  final Object? cause;
  ToyyibpayCheckoutException(this.message, [this.cause]);
  @override
  String toString() => 'ToyyibpayCheckoutException: $message';
}
