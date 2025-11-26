import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // ✅ add this
import 'package:enshield_app/app_binding.dart';
import 'package:enshield_app/routes.dart';
import 'package:enshield_app/core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize GetStorage before runApp()
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Enshield Admin App',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      initialRoute: Routes.splash,
      getPages: AppPages.pages,
      theme: AppTheme.lightTheme,
    );
  }
}
