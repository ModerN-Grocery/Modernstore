

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Utils {
  static void showToast(String message) {
    if (message.trim().isEmpty) return;
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG, // ~3.5 seconds on Android
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      fontSize: 14.sp,
    );
  }

  void toastMessage(String message) {
    showToast(message);
  }
}

class AppToast {
  static void show(String message) {
    Utils.showToast(message);
  }
}