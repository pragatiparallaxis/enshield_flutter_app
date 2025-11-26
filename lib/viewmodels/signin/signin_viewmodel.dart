import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:enshield_app/routes.dart';
import 'package:enshield_app/services/auth_service.dart';
import 'package:enshield_app/services/api_service.dart'; // 👈 for setting global token

class SignInViewModel extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = GetStorage(); // ✅ create local storage instance

  var isPasswordHidden = true.obs;
  var rememberMe = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load saved email if remember me was checked
    if (storage.read('remember_me') == true) {
      rememberMe.value = true;
      emailController.text = storage.read('saved_email') ?? '';
    }
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(0xFFFF9800),
        colorText: Colors.black,
      );
      return;
    }

    isLoading.value = true;

    try {
      final response = await AuthService.login(email, password);

      if (response["success"] == true) {
        final user = response["data"]["user"];
        final token = response["data"]["token"];

        // Handle Remember Me
        if (rememberMe.value) {
          storage.write('remember_me', true);
          storage.write('saved_email', emailController.text);
        } else {
          storage.remove('remember_me');
          storage.remove('saved_email');
        }

        // ✅ 1. Store token and user data in local storage
        storage.write('auth_token', token);
        storage.write('user_id', user["id"]);
        storage.write('user_email', user["email"]);
        storage.write('user_role', user["role"]);
        storage.write('user_firstName', user["firstName"]);
        storage.write('user_lastName', user["lastName"]);

        // ✅ 2. Set it globally for all API calls
        ApiService.setToken(token);

        // ✅ 3. Show success message
        Get.snackbar(
          "Success",
          "Welcome ${user["firstName"]} ${user["lastName"]}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.black,
        );

        print("✅ TOKEN STORED: $token");
        print("👤 ROLE: ${user["role"]}");

        // ✅ 4. Navigate based on role immediately without delay
        // The storage writes are synchronous, so data is ready
        final userRole = user["role"]?.toString().toUpperCase() ?? 'APP_USER';
        if (userRole == 'APP_USER') {
          // Workers see their assignments screen
          Get.offAllNamed(Routes.workerAssignments);
        } else {
          // Admins see dashboard
          Get.offAllNamed(Routes.dashboard);
        }
      } else {
        Get.snackbar(
          "Login Failed",
          response["message"] ?? "Invalid credentials",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.black,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void forgotPassword() {
    Get.snackbar(
      "Forgot Password",
      "Reset link sent to your email.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Color(0xFFFF9800),
      colorText: Colors.black,
    );
  }

  void goToSignUp() {
    Get.toNamed(Routes.signup);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
