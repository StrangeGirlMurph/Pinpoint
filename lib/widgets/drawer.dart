import 'package:flutter/material.dart';
import 'package:pinpoint/pages.dart';

class CDrawer extends StatelessWidget {
  const CDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    int selectedIndex = pages.indexWhere((page) => page.route == currentRoute);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }
    return NavigationDrawer(
        selectedIndex: selectedIndex,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        tilePadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        onDestinationSelected: (value) {
          if (value != selectedIndex) {
            Navigator.of(context).push(PageRouteBuilder(
              settings: RouteSettings(name: pages[value].route),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  pages[value].page,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ));
          } else {
            Navigator.of(context).pop();
          }
        },
        children: pages
            .map((page) => NavigationDrawerDestination(
                  icon: page.icon,
                  selectedIcon: page.selectedIcon,
                  label: Text(page.label),
                ))
            .toList());
  }
}
