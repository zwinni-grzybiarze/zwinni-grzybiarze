import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:onlyshrooms/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(const HashUrlStrategy());
  runApp(
    const ProviderScope(
      child: OnlyShroomsApp(),
    ),
  );
}
