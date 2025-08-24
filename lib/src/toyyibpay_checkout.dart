import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'checkout_webview.dart';
import 'toyyibpay_models.dart';

/// ToyyibPay checkout helper.
///
/// Supports sandbox (dev) and live (www) by swapping [baseUrl].
class ToyyibpayCheckout {
  /// Create a ToyyibPay bill, open checkout, then return the final status.
  ///
  /// [amountCents] must be provided in *sen/cents* (e.g. 1000 = RM10.00).
  static Future<ToyyibpayPaymentResult> startPayment({
    required BuildContext context,
    required String apiKey,
    required String categoryCode,
    required String billName,
    required String billDescription,
    required String amountCents,
    required String returnDeepLink,
    String payerName = 'Demo User',
    String payerEmail = 'customer@test.com',
    String payerPhone = '0123456789',
    String baseUrl = 'https://dev.toyyibpay.com',
    bool verifyWithApi = true,
    String? appBarTitle,
  }) async {
    // 1) Create bill
    final createUri = Uri.parse('$baseUrl/index.php/api/createBill');
    final createRes = await http.post(
      createUri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'userSecretKey': apiKey,
        'categoryCode': categoryCode,
        'billName': billName,
        'billDescription': billDescription,
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': amountCents, // e.g. 1000 = RM10.00
        'billReturnUrl': returnDeepLink,
        'billCallbackUrl':
            returnDeepLink, // demo only; prod => your server webhook
        'billTo': payerName,
        'billEmail': payerEmail,
        'billPhone': payerPhone,
      },
    );

    if (createRes.statusCode != 200) {
      throw ToyyibpayCheckoutException(
        'Bill creation failed: ${createRes.statusCode} ${createRes.body}',
      );
    }

    final dynamic decoded = jsonDecode(createRes.body);
    if (decoded is! List || decoded.isEmpty) {
      throw ToyyibpayCheckoutException('Invalid bill creation response');
    }
    final billCode = decoded[0]['BillCode'] as String?;
    if (billCode == null) {
      throw ToyyibpayCheckoutException('Bill code missing');
    }

    final checkoutUrl = '$baseUrl/$billCode';

    // 2) Open checkout and parse interim status from return URL
    String interimStatus = 'pending';

    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutWebView(
            checkoutUrl: checkoutUrl,
            returnDeepLink: returnDeepLink,
            onReturn: (uri) {
              final statusId = uri.queryParameters['status_id'];
              // 1=success, 2=pending, 3=failed
              if (statusId == '1') {
                interimStatus = 'success';
              } else if (statusId == '3') {
                interimStatus = 'failed';
              } else {
                interimStatus = 'pending';
              }
            },
            appBarTitle: appBarTitle ?? 'ToyyibPay Checkout',
          ),
        ),
      );
    }

    // 3) Optionally verify via API (recommended for reliability)
    String finalStatus = interimStatus;
    Map<String, dynamic>? getTxRaw;
    if (verifyWithApi) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/index.php/api/getBillTransactions'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'billCode': billCode},
        );
        if (res.statusCode == 200) {
          final txList = jsonDecode(res.body);
          if (txList is List && txList.isNotEmpty) {
            final first = (txList.first as Map).map(
              (k, v) => MapEntry('$k', v),
            );
            getTxRaw = {'first': first, 'list': txList};
            final s = (first['billpaymentStatus'] ?? '').toString();
            if (s == '1') {
              finalStatus = 'success';
            } else if (s == '3') {
              finalStatus = 'failed';
            } else {
              finalStatus = 'pending';
            }
          }
        }
      } catch (_) {
        // If verify fails, keep interimStatus
      }
    }

    return ToyyibpayPaymentResult(
      billCode: billCode,
      status: finalStatus,
      raw: {
        'createResponse': decoded,
        if (getTxRaw != null) 'getBillTransactions': getTxRaw,
      },
    );
  }
}
