import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/firebase_bootstrap.dart';
import 'dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeHomieFirebase();
  final dependencies = AppDependencies.create();
  await dependencies.initialize();
  runApp(HomieApp(dependencies: dependencies));
}
