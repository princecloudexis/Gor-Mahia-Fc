
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final timerProvider = StateProvider.autoDispose<int>((ref) => 30);

final otpControllersProvider = Provider.autoDispose<List<TextEditingController>>((ref) {
  final controllers = List.generate(4, (_) => TextEditingController());
  ref.onDispose(() {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
  return controllers;
});