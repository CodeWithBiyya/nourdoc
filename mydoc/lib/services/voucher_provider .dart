import 'package:flutter/material.dart';

class VoucherProvider extends ChangeNotifier {
  bool _isVoucherAppliedOnce = false;
  String _appliedVoucherCode = "";
  double _discount = 0.0;

  bool get isVoucherAppliedOnce => _isVoucherAppliedOnce;
  String get appliedVoucherCode => _appliedVoucherCode;
  double get discountAmount => _discount;

  void applyVoucher(String code) {
    _isVoucherAppliedOnce = true;
    _appliedVoucherCode = code;
    notifyListeners();
  }

  void setDiscountAmount(double discountAmount){
    _discount = discountAmount;
    notifyListeners();
  }

  void resetVoucher() {
    _isVoucherAppliedOnce = false;
    _appliedVoucherCode = "";
    _discount = 0.0;
    notifyListeners();
  }
}
