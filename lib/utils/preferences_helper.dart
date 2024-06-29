import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static SharedPreferences? prefs;
  static const String _chargerList = 'charger_list';

  static Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Save integer set
  static Future<void> saveChargerIntoList(Set<int> intSet) async {
    List<String> stringList = intSet.map((i) => i.toString()).toList();
    await prefs?.setStringList(_chargerList, stringList);
  }

  // Load integer set
  static Future<Set<int>> loadChargerList() async {
    List<String>? stringList = prefs?.getStringList(_chargerList);
    if (stringList == null) return <int>{};
    return stringList.map((i) => int.parse(i)).toSet();
  }

  // Add integer to the set
  static Future<void> addChargerToList(int value) async {
    Set<int> intSet = await loadChargerList();
    intSet.add(value);
    await saveChargerIntoList(intSet);
  }

  // Remove integer from the set
  static Future<void> removeChargerFromList(int value) async {
    Set<int> intSet = await loadChargerList();
    intSet.remove(value);
    await saveChargerIntoList(intSet);
  }

  /// For accepted chargers

  static const String _acceptedChargerList = 'accepted_charger_list';

  // Save integer set
  static Future<void> saveAcceptedChargerList(Set<int> intSet) async {
    List<String> stringList = intSet.map((i) => i.toString()).toList();
    await prefs?.setStringList(_acceptedChargerList, stringList);
  }

  // Load integer set
  static Future<Set<int>> loadAcceptedChargerList() async {
    List<String>? stringList = prefs?.getStringList(_acceptedChargerList);
    if (stringList == null) return <int>{};
    return stringList.map((i) => int.parse(i)).toSet();
  }

  // Add integer to the set
  static Future<void> addAcceptedCharger(int value) async {
    Set<int> intSet = await loadAcceptedChargerList();
    intSet.add(value);
    await saveAcceptedChargerList(intSet);
  }

  // Remove integer from the set
  static Future<void> removeAcceptedCharger(int value) async {
    Set<int> intSet = await loadAcceptedChargerList();
    intSet.remove(value);
    await saveAcceptedChargerList(intSet);
  }

  // Check if the set contains a specific integer
  static Future<bool> containsAcceptedCharger(int value) async {
    Set<int> intSet = await loadAcceptedChargerList();
    return intSet.contains(value);
  }

  ///for charger States
  static const String _chargerKeyPrefix = 'state_charger_';

  //  Save or update charger status
  static Future<void> saveChargerStatus(int chargerId, String status) async {
    await prefs?.setString('$_chargerKeyPrefix$chargerId', status);
  }

  // Load charger status
  static Future<String?> loadChargerStatus(int chargerId) async {
    return prefs?.getString('$_chargerKeyPrefix$chargerId');
  }

  // Remove charger status
  static Future<void> removeChargerStatus(int chargerId) async {
    await prefs?.remove('$_chargerKeyPrefix$chargerId');
  }

  // Load all charger statuses
  static Future<Map<int, String>> loadAllChargerStatuses() async {
    final allKeys = prefs?.getKeys();
    final chargerKeys =
        allKeys?.where((key) => key.startsWith(_chargerKeyPrefix)).toList();
    Map<int, String> chargerStatuses = {};
    if (chargerKeys!.isNotEmpty) {
      for (String key in chargerKeys) {
        final chargerId = int.parse(key.replaceFirst(_chargerKeyPrefix, ''));
        final status = prefs?.getString(key);
        if (status != null) {
          chargerStatuses[chargerId] = status;
        }
      }
    }
    return chargerStatuses;
  }
}
