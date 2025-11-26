import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:enshield_app/viewmodels/worker/worker_edit_viewmodel.dart';

class EditWorkerView extends StatelessWidget {
  final String workerId;

  EditWorkerView({super.key, required this.workerId});

  WorkerEditViewModel get controller => Get.put(WorkerEditViewModel(workerId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        title: const Text(
          "Edit Worker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Get.back();
            } else {
              Get.offAllNamed('/dashboard');
            }
          },
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1C27),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Worker Information",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Update the worker's details below",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: controller.nameController,
                  decoration: _fieldDecoration("Name *"),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Email field
                TextFormField(
                  controller: controller.emailController,
                  decoration: _fieldDecoration("Email"),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 15),

                // Phone field
                TextFormField(
                  controller: controller.phoneController,
                  decoration: _fieldDecoration("Phone"),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),

                // Active checkbox
                Obx(() => CheckboxListTile(
                      title: const Text(
                        "Active",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: controller.isActive.value,
                      onChanged: (value) {
                        controller.isActive.value = value ?? true;
                      },
                      activeColor: const Color(0xFFFF6F00),
                      checkColor: Colors.white,
                    )),

                // Outsourced checkbox
                Obx(() => CheckboxListTile(
                      title: const Text(
                        "Outsourced Worker",
                        style: TextStyle(color: Colors.white),
                      ),
                      value: controller.isOutsourced.value,
                      onChanged: (value) {
                        controller.isOutsourced.value = value ?? false;
                      },
                      activeColor: const Color(0xFFFF6F00),
                      checkColor: Colors.white,
                    )),

                const SizedBox(height: 30),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: controller.cancel,
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.updateWorker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F00),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: controller.isSubmitting.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Update Worker",
                                  style: TextStyle(color: Colors.white),
                                ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF0F111A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6F00)),
      ),
    );
  }
}

