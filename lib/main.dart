import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pinpoint/data/database.dart';
import 'package:pinpoint/data/images.dart';
import 'package:pinpoint/data/settings.dart';
import 'package:pinpoint/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final settings = Settings();
  await settings.init();
  final db = AppDatabase();

  final appDocDir = await getApplicationDocumentsDirectory();
  final imageStorage = ImageStorage(appDocDir, settings, db);

  final accentColor = Color(0xFF56B38A);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: db),
        Provider.value(value: imageStorage),
      ],
      child: Consumer<Settings>(
        builder: (context, settings, child) {
          final themeString = settings.get(Settings.theme) as String;
          ThemeMode themeMode;
          switch (themeString) {
            case 'light':
              themeMode = ThemeMode.light;
              break;
            case 'dark':
              themeMode = ThemeMode.dark;
              break;
            default:
              themeMode = ThemeMode.system;
          }

          return MaterialApp(
            title: 'Pinpoint',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('en', 'GB'),
            ],
            themeMode: themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: accentColor,
                brightness: Brightness.light,
                surfaceTint: Colors.transparent,
                surface: Colors.white,
                surfaceContainer: Colors.white,
                surfaceContainerHigh: Colors.white,
                surfaceContainerHighest: Colors.white,
                surfaceContainerLow: Colors.white,
                surfaceContainerLowest: Colors.white,
              ),
              useMaterial3: true,
              iconTheme: const IconThemeData(weight: 400, color: Colors.black),
              textTheme: ThemeData.light().textTheme.copyWith(
                    bodyMedium: const TextStyle(fontSize: 16, height: 1.5),
                    bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
                  ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: accentColor,
                brightness: Brightness.dark,
                surfaceTint: Colors.transparent,
                surface: Colors.black,
                surfaceContainer: Colors.black,
                surfaceContainerHigh: Colors.black,
                surfaceContainerHighest: Colors.black,
                surfaceContainerLow: Colors.black,
                surfaceContainerLowest: Colors.black,
              ),
              useMaterial3: true,
              iconTheme: const IconThemeData(weight: 400, color: Colors.white),
              textTheme: ThemeData.dark().textTheme.copyWith(
                    bodyMedium: const TextStyle(fontSize: 16, height: 1.5),
                    bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
                  ),
            ),
            initialRoute: '/map',
            routes: {
              for (final page in pages) page.route: (context) => page.page,
            },
          );
        },
      ),
    ),
  );
}
