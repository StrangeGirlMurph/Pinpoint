import 'package:flutter/material.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/default_page.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return DefaultPage(
      name: "Support Me",
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 10,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 15,
          children: [
            const Icon(
              Icons.favorite,
              size: 60,
              color: Colors.red,
            ),
            Text(
              "Enjoying Pinpoint?",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const Text(
              "This app is free to use, privacy respecting, free from ads and open-source. If you find it useful and would like to support me and its continued development, please consider buying me a piece of cake on Ko-fi! Your support means a lot :)",
              textAlign: TextAlign.center,
            ),
            const Text(
              "Sadly big tech has made us so accustomed to software and services being free of charge and always paying with our data and privacy instead of just directly paying the developers and their expenses to keep the software maintained.",
              textAlign: TextAlign.center,
            ),
            const Text(
              "Here you got the chance to resist those practices by supporting a project that refuses to comply.",
              textAlign: TextAlign.center,
            ),
            const Text(
              "Made with love by the StrangeGirlMurph 🌿",
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse("https://ko-fi.com/murph")),
              icon: const Icon(Icons.cake, size: 28),
              label: const Text("Support me on Ko-fi"),
            ),
          ],
        ),
      ),
    );
  }
}
