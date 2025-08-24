import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'checkout_webview.dart';
import 'toyyibpay_models.dart';

class ToyyibpayCheckout {
  /// Create a ToyyibPay bill and open checkout.
  static Future<ToyyibpayPaymentResult> startPayment({
    required BuildContext context,
    required String apiKey,
    required String categoryCode,
    required String billName,
    required String billDescription,
    required String amount,
    required String returnDeepLink,
    String currency = 'MYR',
    String userEmail = 'customer@test.com',
    String userPhone = '0123456789',
  }) async {
    // 1. Create bill
    final res = await http.post(
      Uri.parse('https://dev.toyyibpay.com/index.php/api/createBill'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'userSecretKey': apiKey,
        'categoryCode': categoryCode,
        'billName': billName,
        'billDescription': billDescription,
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': amount, // in cents, e.g., 1000 = RM10.00
        'billReturnUrl': returnDeepLink,
        'billCallbackUrl': returnDeepLink,
        'billTo': 'Demo User',
        'billEmail': userEmail,
        'billPhone': userPhone,
      },
    );

    if (res.statusCode != 200) {
      throw ToyyibpayCheckoutException(
          'Bill creation failed: ${res.statusCode} ${res.body}');
    }

    final body = jsonDecode(res.body);
    if (body is! List || body.isEmpty) {
      throw ToyyibpayCheckoutException('Invalid bill creation response');
    }
    final billCode = body[0]['BillCode'] as String?;

    if (billCode == null) {
      throw ToyyibpayCheckoutException('Bill code missing');
    }

    final checkoutUrl = 'https://dev.toyyibpay.com/${billCode}';

    // 2. Open checkout in WebView
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutWebView(
          checkoutUrl: checkoutUrl,
          returnDeepLink: returnDeepLink,
          onReturn: () {},
        ),
      ),
    );

    // 3. (ToyyibPay doesn’t provide direct status API for bills via GET in sandbox,
    // so we assume success/failure handled by your backend via callback.)
    // For demo, we just return billCode + raw body.
    return ToyyibpayPaymentResult(
      billCode: billCode,
      status: 'pending', // real status should be checked via server callback
      raw: {'createResponse': body},
    );
  }
}
