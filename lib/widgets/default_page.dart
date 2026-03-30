import 'package:flutter/material.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/drawer.dart';
import 'package:pinpoint/widgets/scaffold.dart';

class DefaultPage extends StatelessWidget {
  final String name;
  final Widget body;
  final Widget? floatingActionButton;

  const DefaultPage({
    required this.name,
    required this.body,
    this.floatingActionButton,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedScaffold(
      drawer: CDrawer(),
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: 0,
            left: 0,
            child: BasicAppbar(name),
          ),
        ],
      ),
    );
  }
}
