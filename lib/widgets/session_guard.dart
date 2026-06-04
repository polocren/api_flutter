import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/api_exception.dart';

mixin SessionGuard<T extends StatefulWidget> on State<T> {
  void handleError(Object error, void Function(String message) setMessage) {
    if (error is ApiException && error.isUnauthorized) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    setMessage(error.toString());
  }
}
