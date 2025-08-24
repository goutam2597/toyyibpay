## 2.1.0 - 2025-08-24

- Improved package metadata to follow pub.dev conventions:
    - Added detailed description (50–180 chars).
    - Updated SDK and Flutter constraints.
    - Added `repository` links.
    - Removed unreachable homepage.
- Added working `example/` app for pub.dev Example tab.
- Improved documentation (`README.md`) with usage guide, parameters, troubleshooting, and best practices.


## 2.0.0 - 2025-08-24

- Improved package metadata to follow pub.dev conventions:
    - Added detailed description (50–180 chars).
    - Updated SDK and Flutter constraints.
    - Added `repository` and `issue_tracker` links.
    - Removed unreachable homepage.
- Added working `example/` app for pub.dev Example tab.
- Improved documentation (`README.md`) with usage guide, parameters, troubleshooting, and best practices.

## 1.0.0 - 2025-08-20

- Initial release of **toyyibpay** Flutter package.
- Supports creating ToyyibPay bills via REST API.
- Integrated checkout via in-app WebView (`CheckoutWebView`).
- Parses return URL to determine payment status (`success`, `failed`, `pending`).
- Optional verification via `getBillTransactions` API.
- Includes error handling through `ToyyibpayCheckoutException`.
