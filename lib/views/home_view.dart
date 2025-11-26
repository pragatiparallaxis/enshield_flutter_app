import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/home/home_viewmodel.dart';


class HomeView extends GetView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomeViewModel vm = Get.find<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(vm.title.value)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Home Screen'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.changeTitle('Hello, Pragati!'),
              child: const Text('Change Title'),
            ),
          ],
        ),
      ),
    );
  }
}
