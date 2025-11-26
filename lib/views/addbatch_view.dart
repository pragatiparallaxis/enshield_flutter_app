import 'package:flutter/material.dart';

class AddBatchView extends StatelessWidget {
  const AddBatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Batch"),
        backgroundColor: Color(0xFFFF9800),
      ),
      body: const Center(
        child: Text(
          "Create new batch screen here!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
