import 'package:ev_charger/models/charger_color_status_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:get/get.dart';
import '../models/active_session_model.dart';
import '../models/chargers_view_model.dart';

class SessionController extends GetxController {
  var sessions = <ActiveSessionModel>[].obs;

  var chargers = <ChargersViewModel>[].obs;

  @override
  void onInit() {
    // Fetch sessions from the local database
    fetchSessions();
    super.onInit();
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    List<Map<String, dynamic>> groupData =
        await DatabaseHelper.instance.getSessions();
    return groupData;
  }

  void fetchSessions() async {
    try {
      print("fetch sessions ");
      final dbHelper = DatabaseHelper.instance;
      final sessionMaps = await dbHelper.getSessions();
      final fetchedSessions =
          sessionMaps.map((map) => ActiveSessionModel.fromJson(map)).toList();
      sessions.assignAll(fetchedSessions);
      print(fetchedSessions);
    } catch (e) {
      print('Error fetching sessions: $e');
    }
  }

  void addSession(ActiveSessionModel session) {
    sessions.add(session);
  }

  Future<void> removeSessionByChargerId(String chargerId) async {
    await DatabaseHelper.instance.deleteSession(int.parse(chargerId));
    /*await DatabaseHelper.instance
        .updateChargingStatus(int.parse(chargerId), "waiting", 1);*/
    sessions.removeWhere((session) => session.chargerId == chargerId);
  }

  void addAllChargers() async {
    chargers.clear();
    List<Map<String, dynamic>> chargerMaps =
        await DatabaseHelper.instance.getChargers();

    chargers.assignAll(chargerMaps
        .map((chargerMap) => ChargersViewModel.fromJson(chargerMap))
        .toList());
  }
}
