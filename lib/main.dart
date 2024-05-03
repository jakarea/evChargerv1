import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:ev_charger/services/background_service.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:ev_charger/views/pages/auth/Login_page.dart';
import 'package:ev_charger/views/pages/main_frame_screen.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';

Future<void> main() async {
  // Ensures that Flutter widgets and bindings are initialized before the app runs.
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundService();
// Configures the app window properties like title and size.
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
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
  }

  runApp(const MyApp());
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
