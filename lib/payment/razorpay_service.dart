import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class RazorpayService {
  late Razorpay _razorpay;

  Function(String, String, String)? onSuccess;
  Function(String)? onFailure;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
  }

  void openCheckout({
    required String orderId,
    required int amount,
    required String name,
    required String phone,
    required String email,
    required Color primaryColor,
  }) {
    var options = {
      'key': dotenv.env['RAZORPAY_API_KEY'] ?? '',
      'order_id': orderId,
      'amount': amount * 100,
      'name': name,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': phone, 'email': email},
      'theme': {
        'color': '#${primaryColor.value.toRadixString(16).substring(2)}',
        'backdrop_color': '#000000',
      },
    };
    _razorpay.open(options);
  }

  void _handleSuccess(PaymentSuccessResponse r) {
    onSuccess?.call(r.paymentId!, r.orderId!, r.signature!);
  }

  void _handleError(PaymentFailureResponse r) {
    onFailure?.call(r.message ?? "Payment Failed");
  }

  void dispose() => _razorpay.clear();
}
