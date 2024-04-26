import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class Quantupi {
  static const MethodChannel _channel = MethodChannel('quantupi');

  final String receiverUpiId;
  final String receiverName;
  final String transactionNote;
  final double amount;
  final String orderId;
  final String? transactionRefId;
  final String? currency;
  final String? url;
  final String? merchantId;

  Quantupi({
    required this.receiverUpiId,
    required this.receiverName,
    required this.transactionNote,
    required this.amount,
    required this.orderId,
    this.transactionRefId,
    this.currency = "INR",
    this.url,
    this.merchantId,
  })  : assert(receiverUpiId.contains(RegExp(r'\w+@\w+'))),
        assert(amount >= 0 && amount.isFinite),
        assert(currency == "INR"), // For now
        assert((merchantId != null && transactionRefId != null) ||
            merchantId == null);

  Future<String> startTransaction() async {
    try {
      if (Platform.isAndroid) {
        final String response =
            await _channel.invokeMethod('startTransaction', {
          'receiverUpiId': receiverUpiId,
          'receiverName': receiverName,
          'transactionRefId': transactionRefId,
          'transactionNote': transactionNote,
          'amount': amount.toString(),
          'currency': currency,
          'merchantId': merchantId,
          'orderId': orderId,
        });
        return response;
      } else {
        throw PlatformException(
          code: 'ERROR',
          message: 'Platform not supported!',
        );
      }
    } catch (error) {
      throw Exception(error);
    }
  }
}

enum QuantUPIPaymentApps {
  amazonpay,
  bhimupi,
  googlepay,
  mipay,
  mobikwik,
  myairtelupi,
  paytm,
  phonepe,
  sbiupi,
}

class QuantupiResponse {
  String? transactionId;
  String? responseCode;
  String? approvalRefNo;

  /// DO NOT use the string directly. Instead use [QuantupiResponseStatus]
  String? status;
  String? transactionRefId;

  QuantupiResponse(String responseString) {
    List<String> parts = responseString.split('&');

    for (int i = 0; i < parts.length; ++i) {
      String key = parts[i].split('=')[0];
      String value = parts[i].split('=')[1];
      if (key.toLowerCase() == "txnid") {
        transactionId = value;
      } else if (key.toLowerCase() == "responsecode") {
        responseCode = value;
      } else if (key.toLowerCase() == "approvalrefno") {
        approvalRefNo = value;
      } else if (key.toLowerCase() == "status") {
        if (value.toLowerCase() == "success") {
          status = "success";
        } else if (value.toLowerCase().contains("fail")) {
          status = "failure";
        } else if (value.toLowerCase().contains("submit")) {
          status = "submitted";
        } else {
          status = "other";
        }
      } else if (key.toLowerCase() == "txnref") {
        transactionRefId = value;
      }
    }
  }
}

// This class is to match the status of transaction.
// It is advised to use this class to compare the status rather than doing string comparision.
class QuantupiResponseStatus {
  /// SUCCESS occurs when transaction completes successfully.
  static const String success = 'success';

  /// SUBMITTED occurs when transaction remains in pending state.
  static const String submitted = 'submitted';

  /// Deprecated! Don't use it. Use FAILURE instead.
  static const String failed = 'failure';

  /// FAILURE occurs when transaction fails or user cancels it in the middle.
  static const String failure = 'failure';

  /// In case status is not any of the three accepted value (by chance).
  static const String other = 'other';
}

// Class that contains error responses that must be used to check for errors.
class QuantupiResponseError {
  /// When user selects app to make transaction but the app is not installed.
  static const String appnotinstalled = 'app_not_installed';

  /// When the parameters of UPI request is/are invalid or app cannot proceed with the payment.
  static const String invalidparameter = 'invalid_parameters';

  /// Failed to receive any response from the invoked activity.
  static const String nullresponse = 'null_response';

  /// User cancelled the transaction.
  static const String usercanceled = 'user_canceled';
}
