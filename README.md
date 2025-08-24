# ToyyibPay Checkout (Flutter)

A tiny, production-minded helper to accept payments via **ToyyibPay** in Flutter.  
It creates a bill, opens a WebView for checkout, listens for the return URL, and (optionally) verifies the final status via ToyyibPay’s API.

- ✅ Sandbox & Live support (switch via `baseUrl`)  
- ✅ Simple, single function: `ToyyibpayCheckout.startPayment(...)`  
- ✅ Optional **serverless** verification (client-side call to `getBillTransactions`)  
- ✅ Typed result object with raw payloads for debugging

> This package is not an official ToyyibPay SDK.

---

## Table of contents

- [Features](#features)
- [Quick start](#quick-start)
- [Usage](#usage)
- [Parameters](#parameters)
- [Result shape](#result-shape)
- [Sandbox vs Live](#sandbox-vs-live)
- [Best practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- Create bill → open checkout → return status (`success | failed | pending`)
- WebView flow with return-URL interception
- Optional post-checkout verification via `getBillTransactions`
- Helpful exceptions with HTTP details when bill creation fails

---

## Quick start

### 1) Install

In `pubspec.yaml`:

```yaml
dependencies:
  # Replace with your actual package name if different
  toyyibpay_checkout: ^0.1.0
```

Then:

```bash
flutter pub get
```

### 2) Minimal example

```dart
import 'package:flutter/material.dart';
import 'package:toyyibpay_checkout/toyyibpay_checkout.dart'; // adjust if your package name differs

class PayButton extends StatelessWidget {
  const PayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Pay RM10.00'),
      onPressed: () async {
        final result = await ToyyibpayCheckout.startPayment(
          context: context,
          apiKey: '<YOUR_TOYYIBPAY_SECRET_KEY>',
          categoryCode: '<YOUR_CATEGORY_CODE>',
          billName: 'Order #12345',
          billDescription: 'Acme Pro Plan (Monthly)',
          amountCents: '1000', // 1000 sen = RM10.00
          returnDeepLink: 'https://yourapp.example/return', // must match what you set in ToyyibPay
          payerName: 'Demo User',
          payerEmail: 'customer@test.com',
          payerPhone: '0123456789',
          baseUrl: 'https://dev.toyyibpay.com', // change to https://toyyibpay.com for live
          verifyWithApi: true,
          appBarTitle: 'ToyyibPay',
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment ${result.status} (bill: ${result.billCode})')),
        );
      },
    );
  }
}
```

> The built-in flow pushes a `CheckoutWebView` route and calls you back with the final status.

---

## Usage

### Full example screen

```dart
import 'package:flutter/material.dart';
import 'package:toyyibpay_checkout/toyyibpay_checkout.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = false;
  String? _lastStatus;

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final result = await ToyyibpayCheckout.startPayment(
        context: context,
        apiKey: const String.fromEnvironment('TOYYIBPAY_SECRET'), // or use a secure source
        categoryCode: '<YOUR_CATEGORY_CODE>',
        billName: 'Premium Upgrade',
        billDescription: '1 month subscription',
        amountCents: '1990', // RM19.90
        returnDeepLink: 'https://yourapp.example/return',
        baseUrl: 'https://dev.toyyibpay.com', // Live: https://toyyibpay.com
        verifyWithApi: true,
        appBarTitle: 'ToyyibPay',
      );

      setState(() => _lastStatus = result.status);
      debugPrint('Bill: ${result.billCode}');
      debugPrint('Raw: ${result.raw}');
    } on ToyyibpayCheckoutException catch (e) {
      setState(() => _lastStatus = 'failed');
      debugPrint('ToyyibPay error: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example Checkout')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(onPressed: _start, child: const Text('Pay Now')),
                  if (_lastStatus != null) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Last status: $_lastStatus'),
                  ),
                ],
              ),
      ),
    );
  }
}
```

---

## Parameters

`ToyyibpayCheckout.startPayment({ ... })`

| Param              | Type                | Required | Default                          | Notes |
|--------------------|---------------------|----------|----------------------------------|------|
| `context`          | `BuildContext`      | ✅       | —                                | Used to push the WebView route. |
| `apiKey`           | `String`            | ✅       | —                                | Your ToyyibPay **Secret Key** (`userSecretKey`). |
| `categoryCode`     | `String`            | ✅       | —                                | Your ToyyibPay Category Code. |
| `billName`         | `String`            | ✅       | —                                | Displayed on ToyyibPay bill. |
| `billDescription`  | `String`            | ✅       | —                                | Short description for the bill. |
| `amountCents`      | `String`            | ✅       | —                                | Amount in **sen** (e.g. `1000` = RM10.00). |
| `returnDeepLink`   | `String`            | ✅       | —                                | Redirect URL configured in your ToyyibPay bill. The WebView will hit this URL at the end and we parse query params (e.g. `status_id`). |
| `payerName`        | `String`            | ❌       | `"Demo User"`                    | Bill to: name. |
| `payerEmail`       | `String`            | ❌       | `"customer@test.com"`            | Bill to: email. |
| `payerPhone`       | `String`            | ❌       | `"0123456789"`                   | Bill to: phone. |
| `baseUrl`          | `String`            | ❌       | `"https://dev.toyyibpay.com"`    | **Sandbox**: `https://dev.toyyibpay.com` / **Live**: `https://toyyibpay.com` |
| `verifyWithApi`    | `bool`              | ❌       | `true`                           | If true, calls `getBillTransactions` after WebView closes to confirm final status. |
| `appBarTitle`      | `String?`           | ❌       | `"ToyyibPay"`                    | Title for the in-app checkout screen. |

---

## Result shape

`ToyyibpayPaymentResult`:

```dart
class ToyyibpayPaymentResult {
  final String billCode;  // e.g. "abc123"
  final String status;    // "success" | "failed" | "pending"
  final Map<String, dynamic> raw; // debugging payloads: create response + (optional) getBillTransactions
}
```

**Status mapping**

| ToyyibPay status_id / API | Package `status` |
|---------------------------|------------------|
| `1` (success)             | `"success"`      |
| `3` (failed)              | `"failed"`       |
| Other / not found         | `"pending"`      |

---

## Sandbox vs Live

- **Sandbox (default)**: `baseUrl = https://dev.toyyibpay.com`  
- **Live**: `baseUrl = https://toyyibpay.com`

When you switch to live:
1. Use your **live** Secret Key and Category Code.
2. Ensure `returnDeepLink` matches the value configured on the **live** bill.
3. Test small amounts first.

---

## Best practices

- **Keep `verifyWithApi: true`** (default). The return URL is convenient, but a follow-up call to `getBillTransactions` makes the status more reliable.
- Store secrets securely (e.g., remote config, env vars at build time). Avoid hardcoding keys in source.
- Provide clear UI states: loading, success, failure, and pending.
- Log/store the `billCode` for reconciliation.

---

## Troubleshooting

**Bill creation failed: 4xx/5xx**  
- Check `apiKey`, `categoryCode`, and required bill fields.  
- Ensure the amount is in **sen** (string).  
- Inspect the thrown `ToyyibpayCheckoutException` message for response details.

**Always getting `pending`**  
- Confirm ToyyibPay is returning the user to your `returnDeepLink`.  
- If the return URL fires but `status_id` isn’t `1` or `3`, the package stays in `pending`.  
- Leave `verifyWithApi: true` to confirm status server-side.  

**WebView doesn’t close**  
- The flow pops the WebView when it hits the `returnDeepLink` and parses it. Make sure `returnDeepLink` exactly matches what ToyyibPay redirects to.

---

## FAQ

**Do I need OS-level deep linking?**  
No. The package intercepts the **in-WebView** navigation to your `returnDeepLink` and parses query params (e.g., `status_id`). You don’t need Android/iOS deep-link configuration unless you want to leave the WebView and open your app externally.

**Can I use my own WebView?**  
The helper uses an internal `CheckoutWebView` tailored for this flow. If you need a custom UI, you can fork/extend it.

**Is client-side verification safe?**  
This package verifies via ToyyibPay’s public API and is fine for many use cases. For the highest integrity (e.g., to protect against client tampering), add a **server webhook** and verify on your server.

---

## Roadmap

- Expose additional bill fields
- Optional callback-based customization points for UI
- Stronger type modeling for responses

---

## Contributing

Issues and PRs are welcome! Please:
1. Open an issue describing the change or bug.
2. Include reproducible steps and environment details.
3. Follow Dart/Flutter formatting and analyzer rules.

---

## License

This package is released under the **MIT License**.

```
MIT License

Copyright (c) 2025 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### Notes for maintainers

- The helper relies on the ToyyibPay REST endpoints:
  - `POST /index.php/api/createBill`
  - `POST /index.php/api/getBillTransactions`
- The `CheckoutWebView` pushes a `MaterialPageRoute` and fires `onReturn(Uri)` when the return URL is reached.  
- `ToyyibpayCheckoutException` is thrown for non-200 responses or malformed payloads.
