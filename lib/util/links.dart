import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pinpoint/util/snackbar.dart';

void openURL(BuildContext context, String url) async {
  Uri parsedUrl = Uri.parse(url);
  if (await canLaunchUrl(parsedUrl)) {
    launchUrl(parsedUrl);
  } else {
    if (context.mounted) showSnackBar(context, 'Could not launch the URL!');
  }
}
