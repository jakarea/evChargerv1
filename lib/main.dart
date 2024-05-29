import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:ev_charger/services/background_service.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:ev_charger/views/pages/auth/Login_page.dart';
import 'package:ev_charger/views/pages/main_frame_screen.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';

import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {

  void logError(dynamic error, StackTrace stackTrace) {
    final logFile = File('error.log');
    logFile.writeAsStringSync(
      '${DateTime.now()}: $error\n$stackTrace\n\n',
      mode: FileMode.append,
    );
  }

  runZonedGuarded(() async {
    await SentryFlutter.init(
          (options) {
        options.dsn = 'https://99cf6c242f90c1503f2bf55d41231823@o4507332205019136.ingest.us.sentry.io/4507332207116288';
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
    );
    runApp(MyApp());
  }, (exception, stackTrace) async {
    logError(exception, stackTrace);
    await Sentry.captureException(exception, stackTrace: stackTrace);
  });

  // Ensures that Flutter widgets and bindings are initialized before the app runs.
  WidgetsFlutterBinding.ensureInitialized();
  //BackgroundService();
// Configures the app window properties like title and size.
 /* if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    doWhenWindowReady(() {
      var initialSize = const Size(1366, 720);
      appWindow.size = initialSize;
      appWindow.minSize = initialSize;
      appWindow.show();
    });

    try {
      // Initialize the application's database.
      // The DatabaseHelper is a singleton for database operations.
      await DatabaseHelper.instance.database;
    } catch (e) {
      // Handle or log the error as needed
      throw Exception(e);
    }
  }*/


  try {
    int? test;
    test! + 3;
  } catch (exception, stackTrace) {
    debugPrint("Catch Error");
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
    );
  }

  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'EV Charger',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
      ),
      home: const MainFrameScreen(),
    );
  }
}
