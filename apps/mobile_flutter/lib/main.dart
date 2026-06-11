import 'package:flutter/material.dart';

import 'app/app_widget.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initializeFirebase();
  runApp(const SolexApp());
}
