import 'package:get/get.dart';

class HomeViewModel extends GetxController {
  final title = 'Welcome'.obs;

  void changeTitle(String value) => title.value = value;
}
