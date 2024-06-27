import 'package:shared_preferences/shared_preferences.dart';
import '../services/preferences_helper.dart';

class SharedPreferenceController {

  Future<void> cleanSharedPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  ///for charger state
  Future<void> saveChargerStatus(int chargerId, String status) async {
    await PreferencesHelper.saveChargerStatus(chargerId, status);
    loadAllChargerStatuses();
  }

  Future<String?> checkChargerStatus(int chargerId) async {
    String? status = await PreferencesHelper.loadChargerStatus(chargerId);
    return status;
  }

  Future<void> removeChargerStatus(int chargerId) async {
    await PreferencesHelper.removeChargerStatus(chargerId);
    loadAllChargerStatuses();
  }

  Future<Map<int, String>> loadAllChargerStatuses() async {
    Map<int, String> chargerStatuses =
    await PreferencesHelper.loadAllChargerStatuses();
    return chargerStatuses;
  }

  /// for authorize  state
  Future<Set<int>> loadAuthorizeChargerList() async {
    Set<int> authorizeChargerList = await PreferencesHelper.loadChargerList();
    return authorizeChargerList;
  }

  Future<void> addToAuthorizeList(int value) async {
    await PreferencesHelper.addChargerToList(value);
    loadAuthorizeChargerList();
  }

  Future<void> removeFromAuthorizeList(int value) async {
    await PreferencesHelper.removeChargerFromList(value);
    loadAuthorizeChargerList();
  }

  /// for  accepted state
  Future<Set<int>> loadAcceptedChargerList() async {
    Set<int> acceptedChargerList = await PreferencesHelper.loadAcceptedChargerList();
    return acceptedChargerList;
  }

  Future<void> addToAcceptedList(int value) async {
    await PreferencesHelper.addAcceptedCharger(value);
    loadAcceptedChargerList();
  }

  Future<void> removeFromAcceptedList(int value) async {
    await PreferencesHelper.removeAcceptedCharger(value);
    loadAcceptedChargerList();
  }

  Future<void> delayInSeconds(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
  }
}

