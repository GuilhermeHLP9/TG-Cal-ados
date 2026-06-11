import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/session_storage.dart';
import 'login_screen.dart';

void logout(BuildContext context) {
  unawaited(SessionStorage.clear());

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}
