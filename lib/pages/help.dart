import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pinpoint/widgets/appbar.dart';
import 'package:pinpoint/widgets/default_page.dart';
import 'package:pinpoint/widgets/headline.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + appbarHeight;

    return DefaultPage(
      name: "Help & Feedback",
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
            const Headline("Basic Overview"),
            const Text(
              "This app allows you to map things/places across the globe. It is fairly simple. The two concepts to know are: entries and lists. An entry represents a thing. It can contain the following properties: an image, a description, a date plus time and a location. A list is a collection of entries. A list has a name and a color. Every entry is part of one list. Lists can be created, deleted, edited in the 'Manage Lists' page. You can also give them an ordering there by dragging and dropping which the dropdown menus of the view pages use. The view pages ('Map View' and 'List View') allow you to create and view entries of a selected list. The list can be selected from the dropdown menu in the appbar. If you have more than one list the dropdown menu also contains the 'Everything' option which will show all entries from all lists.",
            ),
            const Headline("The List View"),
            const Text(
              "The list view shows all the entries of a list. You can edit entries by tapping them and add a new empty entry with the floating action button in the bottom right.",
            ),
            const Headline("The Map View"),
            const Text(
              "The map view shows all the entries of a list with a location. You can edit an entry by tapping its marker and move an entry by long pressing and then dragging it to a new location. The map view offers the following four ways of creating an entry:",
            ),
            const Text(
              "1. Long pressing the map at an empty stop to create a new entry at that location.\n"
              "2. Tapping the small floating action button with the plus icon to create an empty entry.\n"
              "3. Tapping the floating action button with the marker with plus icon to create an entry at your current location.\n"
              "4. Tapping the floating action button with the camera icon to create an entry by taking its picture at your current location.",
            ),
            const Headline("Map Interactions"),
            const Text(
              "The map of the map view can be navigated with the common gestures/mouse controls. You can pan, rotate, zoom. There are two buttons in the map view that also make this easier. A small one with an arrowhead to manage the rotation of the map and a bigger one at the bottom to follow you. The arrowhead of the small button always points north adapting to the rotation of the map. If the map is north-oriented the button functions as a toggle to enable and disable map rotation. If not a tap on the botton rotates the map to be north-oriented. The big location button also has multiple states. From the start it indicates whether or not a GPS location is available for the phone. Tapping it once makes the map follow your current position. Tapping it again also makes the map rotation follow your bearing. Tapping it again stops both and brings you back to the default. Manually moving the map also aborts the following around.",
            ),
            const Text(
              "In general the buttons explain what they do. You can access these tips by long pressing/hovering.",
            ),
            const Headline("Feedback & Support"),
            const Text(
              "If you encounter any bugs, have feature requests, any kind of feedback or just want to thank me, please contact me through one of the following channels (sorted by preference):",
            ),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(
                      "https://github.com/StrangeGirlMurph/Urban-Mapping/issues")),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text("GitHub Issues"),
                ),
                TextButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse("mailto:work@murphy.science")),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text("E-Mail (work@murphy.science)"),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(
                      "https://matrix.to/#/@strangegirlmurph:matrix.org")),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Matrix (@strangegirlmurph)"),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(
                      Uri.parse("https://mastodon.social/@StrangeGirlMurph")),
                  icon: const Icon(Symbols.communities),
                  label: const Text("Mastodon (@StrangeGirlMurph)"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
