import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/views/pages/active_session_content.dart';
import 'package:ev_charger/views/pages/settings_content.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../controllers/settings_controller.dart';
import 'cards_content.dart';
import 'chargers_content.dart';
import 'chargers_group_content.dart';
import 'dashboard_content.dart';
import 'dart:io';
import 'package:get/get.dart';

class MainFrameScreen extends StatefulWidget {
  const MainFrameScreen({super.key});

  @override
  State<MainFrameScreen> createState() => _MainFrameScreenState();
}

class _MainFrameScreenState extends State<MainFrameScreen> {
  int currentIndex = 0;

  final PaneDisplayMode _paneDisplayMode = PaneDisplayMode.compact;
  late final WebSocketChannel channel;
  @override
  void initState() {
    super.initState();
    Get.put(SettingsController());
    Get.put(SessionController());
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    Color systemColor =
        isDarkMode ? const Color(0xFF202020) : const Color(0xFFf3f3f3);

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
        // app bar
        Container(
          color: systemColor,
          child: WindowTitleBarBox(
            child: Row(
              children: [
                if (Platform.isWindows)
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 20, top: 8, bottom: 8),
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

        // app body
        Expanded(
          child: NavigationView(
            pane: NavigationPane(
                selected: currentIndex,
                onChanged: (index) {
                  currentIndex = index;
                  setState(() {});
                },
                displayMode: _paneDisplayMode,
                size: const NavigationPaneSize(
                  openMinWidth: 250,
                  openMaxWidth: 250,
                ),
                items: [
                  PaneItem(
                    icon: const Icon(
                      FluentIcons.home,
                    ),
                    title: Text(
                      "Dashboard",
                    ),
                    body: DashboardContent(
                      chargersGroupOnPressed: () {
                        currentIndex = 1;
                        setState(() {});
                      },
                      chargersOnPressed: () {
                        currentIndex = 2;
                        setState(() {});
                      },
                      cardsOnPressed: () {
                        currentIndex = 3;
                        setState(() {});
                      },
                      stationOnPressed: () {
                        currentIndex = 4;
                        setState(() {});
                      },
                    ),
                  ),
                  PaneItemSeparator(),
                  PaneItem(
                    icon: const Icon(
                      FluentIcons.cloud,
                    ),
                    title: Text(
                      "Chargers Group",
                    ),
                    body: ChargersGroupContent(),
                  ),
                  PaneItem(
                    icon: const Icon(
                      FluentIcons.plug,
                    ),
                    title: Text(
                      "Chargers",
                    ),
                    body: ChargersContent(),
                  ),
                  PaneItemSeparator(),
                  PaneItem(
                    icon: const Icon(
                      FluentIcons.credit_card_bill,
                    ),
                    title: Text(
                      "Cards",
                    ),
                    body: CardsContent(),
                  ),
                  PaneItemSeparator(),
                  // PaneItem(
                  //   icon: const Icon(
                  //     FluentIcons.diet_plan_notebook,
                  //   ),
                  //   title: Text(
                  //     "Station Log",
                  //   ),
                  //   body: StationLogContent(),
                  // ),
                  PaneItem(
                    icon: const Icon(
                      FluentIcons.activate_orders,
                    ),
                    title: const Text(
                      "Active Session",
                    ),
                    body: const ActiveSessionContent(),
                  ),

                ],
              footerItems: [
                PaneItem(
                  icon: const Icon(FluentIcons.settings),
                  title: const Text('Settings'),
                  body: const SettingsContent(),
                ),
              ]

            ),
          ),
        )
      ],
    );
  }
}
