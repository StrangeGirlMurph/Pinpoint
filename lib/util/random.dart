import 'dart:math';
import 'package:flutter/material.dart';

MaterialColor getRandomMaterialColor() {
  final random = Random();
  return Colors.primaries[random.nextInt(Colors.primaries.length)];
}
