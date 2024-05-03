import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'dart:io';

import '../main_frame_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    Color systemColor =
        isDarkMode ? const Color(0xFF202020) : const Color(0xFFf3f3f3);

    Color backgroundColor =
        isDarkMode ? const Color(0xFF282828) : const Color(0xFFf6f6f6);

    var buttonColors = WindowButtonColors(
      normal: systemColor,
      iconNormal: isDarkMode ? Colors.white : Colors.black,
      mouseOver: isDarkMode ? Colors.grey : const Color(0xFFD0D0D0),
      mouseDown: isDarkMode ? Colors.grey : const Color(0xFFD0D0D0),
      iconMouseDown: isDarkMode ? Colors.grey : const Color(0xFFD0D0D0),
      iconMouseOver: isDarkMode ? Colors.white : Colors.black,
    );

    var closeButtonColors = WindowButtonColors(
      normal: systemColor,
      iconNormal: isDarkMode ? Colors.white : Colors.black,
      mouseOver: Colors.red,
      mouseDown: isDarkMode ? Colors.grey : const Color(0xFFD0D0D0),
      iconMouseDown: isDarkMode ? Colors.grey : const Color(0xFFD0D0D0),
      iconMouseOver: isDarkMode ? Colors.white : Colors.black,
    );
    return Column(
      children: [
        Container(
          color: systemColor,
          child: WindowTitleBarBox(
            child: Row(
              children: [
                if (Platform.isWindows)
                  const Padding(
                    padding:
                        EdgeInsets.only(left: 16, right: 20, top: 8, bottom: 8),
                    child: Text("evCharger"),
                  ),
                Expanded(child: MoveWindow()),
                MinimizeWindowButton(
                  colors: buttonColors,
                ),
                MaximizeWindowButton(
                  colors: buttonColors,
                ),
                CloseWindowButton(
                  colors: closeButtonColors,
                )
              ],
            ),
          ),
        ),
        Expanded(
            child: Container(
          width: double.infinity,
          height: double.infinity,
          color: backgroundColor,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding:
                  EdgeInsets.only(left: 40, right: 40, top: 80, bottom: 80),
              width: 400,
              decoration: BoxDecoration(
                  color: systemColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 5,
                        spreadRadius: 5,
                        offset: Offset(0, 0),
                        color: Colors.grey.withOpacity(0.2))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text("Enter your credentials to access your account"),
                  SizedBox(
                    height: 12,
                  ),
                  TextFormBox(
                    placeholder: "Enter your email",
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  TextFormBox(
                    placeholder: "Enter your password",
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  Container(
                    width: double.infinity,
                    child: Button(child: Text("Log In"),
                        onPressed: () {
                      Navigator.pushReplacement(context, FluentPageRoute(builder: (context) => MainFrameScreen()));

                        }),
                  ),
                ],
              ),
            ),
          ),
        ))
      ],
    );
  }
}
