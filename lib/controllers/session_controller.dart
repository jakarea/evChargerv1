import 'package:ev_charger/models/charger_color_status_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:get/get.dart';

import '../models/active_session_model.dart';
import '../models/chargers_view_model.dart';

class SessionController extends GetxController {
  var sessions = <ActiveSessionModel>[].obs;


  var chargers = <ChargersViewModel>[].obs;

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    List<Map<String, dynamic>> groupData =
        await DatabaseHelper.instance.getSessions();
    print("sessions ${groupData}");

    return groupData;
  }

  void addSession(ActiveSessionModel session) {
    print("add session data ${session.sessionTime}");
    sessions.add(session);
  }

  Future<void> removeSessionByChargerId(String chargerId) async {
    await DatabaseHelper.instance
        .deleteSession(int.parse(chargerId));
    sessions.removeWhere((session) => session.chargerId == chargerId);
  }

  void addAllChargers() async{

    chargers.clear();
    List<Map<String, dynamic>> chargerMaps =
    await DatabaseHelper.instance.getChargers();

    chargers.assignAll(chargerMaps
        .map((chargerMap) => ChargersViewModel.fromJson(chargerMap))
        .toList());
  }


}
