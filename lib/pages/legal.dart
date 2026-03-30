import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/default_page.dart';
import 'package:pinpoint/widgets/headline.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return DefaultPage(
      name: "Legal & Attribution",
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 10,
          bottom: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Headline("Data Policy"),
            const Text(
              "This app respects your privacy. All your data, including markers, images, and lists, is stored strictly locally on your device.",
            ),
            const Text(
              "No personal data is collected, no telemetry is used, and nothing is sent to the developer or any third parties. The internet connection required by this app is used exclusively for fetching map tiles from the OpenStreetMap Foundations servers.",
            ),
            Headline("Attributions"),
            Text.rich(
              TextSpan(
                text: "Launcher icon created by RIkas Dzihab from Flaticon",
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(Uri.parse(
                        "https://www.flaticon.com/free-icon/earth_10420181"));
                  },
              ),
            ),
            Headline("Open Source Licenses"),
            const Text(
              "This app is built using Flutter and various open-source libraries. You can view all their licenses below.",
            ),
            TextButton.icon(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: "Pinpoint",
                  applicationVersion: "1.0.0",
                );
              },
              icon: const Icon(Icons.description),
              label: const Text("View Licenses"),
            ),
          ],
        ),
      ),
    );
  }
}
