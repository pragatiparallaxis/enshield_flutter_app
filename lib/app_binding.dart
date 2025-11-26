import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/home/home_viewmodel.dart';


class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Global controllers can be initialized here
    Get.put(HomeViewModel());
  }
}
