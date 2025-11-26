import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/routes.dart';

class SignUpViewModel extends GetxController {
  // 🔹 Text Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // 🔹 Reactive Variables
  var isPasswordHidden = true.obs;
  var isConfirmPasswordHidden = true.obs;

  // 🔹 Toggle Password Visibility
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  // 🔹 Signup Function
  void signUp() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    // 🧩 Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFF9800),
        colorText: Colors.black87,
      );
      return;
    }

    if (password != confirm) {
      Get.snackbar(
        "Error",
        "Passwords do not match",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFF9800),
        colorText: Colors.black87,
      );
      return;
    }

    // ✅ Success
    Get.snackbar(
      "Success",
      "Account created successfully!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.black87,
    );

    // 🔁 Navigate to SignIn page
    Get.offAllNamed(Routes.signin);
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
