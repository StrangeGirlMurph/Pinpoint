import 'package:flutter/material.dart';
import 'package:pinpoint/pages/help.dart';
import 'package:pinpoint/pages/legal.dart';
import 'package:pinpoint/pages/list_view.dart';
import 'package:pinpoint/pages/manage_lists.dart';
import 'package:pinpoint/pages/map_view.dart';
import 'package:pinpoint/pages/settings.dart';
import 'package:pinpoint/pages/support.dart';

class Page {
  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final Widget page;

  const Page(this.label, this.route, this.icon, this.selectedIcon, this.page);
}

const List<Page> pages = [
  Page("Map View", "/map", Icon(Icons.map_outlined), Icon(Icons.map),
      MapViewPage()),
  Page("List View", "/list", Icon(Icons.view_list_outlined),
      Icon(Icons.view_list), ListViewPage()),
  Page("Manage Lists", "/lists", Icon(Icons.format_list_bulleted),
      Icon(Icons.format_list_bulleted_add), ManageListsPage()),
  Page("Settings", "/settings", Icon(Icons.settings_outlined),
      Icon(Icons.settings), SettingsPage()),
  Page("Support Me", "/support", Icon(Icons.volunteer_activism_outlined),
      Icon(Icons.volunteer_activism), SupportPage()),
  Page("Help & Feedback", "/help", Icon(Icons.help_outline_outlined),
      Icon(Icons.help), HelpPage()),
  Page("Legal & Attribution", "/legal", Icon(Icons.policy_outlined),
      Icon(Icons.policy), LegalPage()),
];
