import 'package:get/get.dart';

class HeartbeatController extends GetxController {
  var heartbeats = <String>[].obs;

  void addHeartbeat(String timestamp) {
    heartbeats.add(timestamp); // Add a new timestamp and notify listeners
  }
}
