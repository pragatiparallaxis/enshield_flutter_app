import 'package:flutter/material.dart';

class CenteredProgress extends StatelessWidget {
  const CenteredProgress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 36,
      height: 36,
      child: CircularProgressIndicator(strokeWidth: 3),
    );
  }
}
