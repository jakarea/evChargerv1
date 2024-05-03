import 'package:ev_charger/controllers/heartbeat_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../widgets/navigation_item.dart';
import 'package:get/get.dart';

class StationLogContent extends StatefulWidget {
  const StationLogContent({super.key});

  @override
  State<StationLogContent> createState() => _StationLogContentState();
}

class _StationLogContentState extends State<StationLogContent> {

  final HeartbeatController heartbeatController = Get.put(HeartbeatController());
  @override
  Widget build(BuildContext context) {
    return NavigationItem(
      title: "Heartbeat",
      content: Obx(() {
        // Use the controller to get the count and build list tiles
        return ListView.builder(
          itemCount: heartbeatController.heartbeats.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(heartbeatController.heartbeats[index]),
            );
          },
        );
      }),
    );
  }
}
