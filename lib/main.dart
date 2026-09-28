import 'package:flutter/material.dart';

import 'app/root_app.dart';
import 'core/providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Bootstrap asset/service loading in the background so first paint is fast.
  AppScope.bootstrap().catchError((_) {});
  runApp(const ShongketApp());
}
