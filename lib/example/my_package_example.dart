import 'package:flutter/material.dart';
import 'package:toyyibpay/toyyibpay.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToyyibPay Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('ToyyibPay Example')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final result = await ToyyibpayCheckout.startPayment(
                context: context,
                apiKey: '<YOUR_SECRET_KEY>',
                categoryCode: '<YOUR_CATEGORY_CODE>',
                billName: 'Demo Bill',
                billDescription: 'Testing payment',
                amountCents: '1000', // RM10.00
                returnDeepLink: 'https://yourapp.example/return',
              );
              debugPrint('Payment status: ${result.status}');
            },
            child: const Text('Start Payment'),
          ),
        ),
      ),
    );
  }
}
