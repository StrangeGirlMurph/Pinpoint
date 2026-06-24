import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinpoint/pages.dart';
import 'package:url_launcher/url_launcher.dart';

class CDrawer extends StatelessWidget {
  const CDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    int selectedIndex = pages.indexWhere((page) => page.route == currentRoute);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }
    return FutureBuilder<bool>(
      future: context.read<Future<bool>>(),
      builder: (context, snapshot) {
        final updateAvailable = snapshot.data == true;
        return NavigationDrawer(
          selectedIndex: selectedIndex,
          indicatorShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          onDestinationSelected: (value) {
            if (updateAvailable && value == pages.length) {
              launchUrl(
                  Uri.parse(
                      'https://github.com/StrangeGirlMurph/Pinpoint/releases/latest'),
                  mode: LaunchMode.externalApplication);
            } else {
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
            }
          },
          children: [
            ...pages.map((page) => NavigationDrawerDestination(
                  icon: page.icon,
                  selectedIcon: page.selectedIcon,
                  label: Text(page.label),
                )),
            if (updateAvailable)
              const NavigationDrawerDestination(
                icon: Icon(Icons.file_download_outlined),
                label: Text('Get Update'),
              )
          ],
        );
      },
    );
  }
}
