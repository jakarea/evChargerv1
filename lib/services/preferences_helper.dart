// preferences_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _chargerList = 'charger_list';

  // Save integer set
  static Future<void> saveChargerIntoList(Set<int> intSet) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stringList = intSet.map((i) => i.toString()).toList();
    await prefs.setStringList(_chargerList, stringList);
  }

  // Load integer set
  static Future<Set<int>> loadChargerList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? stringList = prefs.getStringList(_chargerList);
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
    final prefs = await SharedPreferences.getInstance();
    List<String> stringList = intSet.map((i) => i.toString()).toList();
    await prefs.setStringList(_acceptedChargerList, stringList);
  }

  // Load integer set
  static Future<Set<int>> loadAcceptedChargerList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? stringList = prefs.getStringList(_acceptedChargerList);
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
}
