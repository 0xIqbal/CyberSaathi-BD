import 'package:flutter/material.dart';

class HealthInputField extends StatelessWidget {
  const HealthInputField({
    required this.controller,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.send,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'আপনার স্বাস্থ্য সম্পর্কিত প্রশ্ন লিখুন',
        prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
        suffixIcon: IconButton(
          tooltip: 'প্রশ্ন পাঠান',
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(Icons.send_rounded),
        ),
      ),
    );
  }
}
