import 'package:flutter/material.dart';

class Headline extends StatelessWidget {
  final String text;
  const Headline(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
