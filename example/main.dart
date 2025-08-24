import 'package:flutter/material.dart';
import 'package:toyyibpay/toyyibpay.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToyyibPay Example',
      home: const CheckoutDemo(),
    );
  }
}

class CheckoutDemo extends StatelessWidget {
  const CheckoutDemo({super.key});

  Future<void> _startPayment(BuildContext context) async {
    final result = await ToyyibpayCheckout.startPayment(
      context: context,
      apiKey: '<YOUR_SECRET_KEY>',
      categoryCode: '<YOUR_CATEGORY_CODE>',
      billName: 'Demo Bill',
      billDescription: 'Testing ToyyibPay checkout',
      amountCents: '1000', // RM10.00
      returnDeepLink: 'https://yourapp.example/return',
      payerName: 'Test User',
      payerEmail: 'test@example.com',
      payerPhone: '0123456789',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment status: ${result.status} (bill: ${result.billCode})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ToyyibPay Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startPayment(context),
          child: const Text('Pay RM10.00'),
        ),
      ),
    );
  }
}
