import 'package:get/get.dart';
import 'dart:async';
import 'package:enshield_app/routes.dart';

class SplashViewModel extends GetxController {
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    Timer(const Duration(seconds: 3), () {
      Get.offAllNamed(Routes.signin);
    });
  }
}
