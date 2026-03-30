import 'package:flutter/material.dart';

const double appbarHeight = 72.0;

class BasicAppbar extends StatelessWidget {
  final String text;
  const BasicAppbar(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return CoreAppbar([
      Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ]);
  }
}

class CoreAppbar extends StatelessWidget {
  final List<Widget> children;

  const CoreAppbar(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    return BareAppbar(
      Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          SizedBox(width: 6),
          ...children
        ],
      ),
    );
  }
}

class BareAppbar extends StatelessWidget {
  final Widget child;

  const BareAppbar(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarWidth = screenWidth > 416 ? 400.0 : screenWidth - 16;

    return SafeArea(
      bottom: false,
      child: Container(
        height: appbarHeight - 16,
        width: appBarWidth,
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  )
                ]
              : const [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 4,
                  )
                ],
        ),
        child: child,
      ),
    );
  }
}
