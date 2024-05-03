import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  RxBool boxSerial = true.obs;
  RxBool firmwareVersion = true.obs;
  RxBool intervalTime = true.obs;
  RxBool urlToConnect = true.obs;
  RxBool group = true.obs;
  RxBool maximumChargingPower = true.obs;

  RxBool minKwh = true.obs;
  RxBool maxKwh = true.obs;
  RxBool maxSessionTime = true.obs;
  RxBool usageHour = true.obs;
  RxBool minInterVal = true.obs;
  RxBool reference = true.obs;
  RxBool groupCard = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
    loadCardSettings();
  }

  void updateSettings(bool newBoxSerial, bool newFirmwareVersion, bool newIntervalTime, bool newUrlToConnect, bool newGroup, bool newMaximumChargingPower) {
    boxSerial.value = newBoxSerial;
    firmwareVersion.value = newFirmwareVersion;
    intervalTime.value = newIntervalTime;
    urlToConnect.value = newUrlToConnect;
    group.value = newGroup;
    maximumChargingPower.value = newMaximumChargingPower;
    saveSettings();  // Save settings whenever they are updated
  }

  void updateCardSettings(
      bool newMinKwh,
      bool newMaxKwh,
      bool newMaxSessionTime,
      bool newUsageHour,
      bool newMinInterval,
      bool newReference,
      bool newGroupCard,
      ){
    minKwh.value = newMinKwh;
    maxKwh.value = newMaxKwh;
    maxSessionTime.value = newMaxSessionTime;
    usageHour.value = newUsageHour;
    minInterVal.value = newMinInterval;
    reference.value = newReference;
    groupCard.value = newGroupCard;
    saveCardSettings();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('boxSerial', boxSerial.value);
    await prefs.setBool('firmwareVersion', firmwareVersion.value);
    await prefs.setBool('intervalTime', intervalTime.value);
    await prefs.setBool('urlToConnect', urlToConnect.value);
    await prefs.setBool('group', group.value);
    await prefs.setBool('maximumChargingPower', maximumChargingPower.value);
  }

  Future<void> saveCardSettings() async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('minKwh', minKwh.value);
    await prefs.setBool('maxKwh', maxKwh.value);
    await prefs.setBool('maxSessionTime', maxSessionTime.value);
    await prefs.setBool('usageHour', usageHour.value);
    await prefs.setBool('minInterval', minInterVal.value);  // Assuming this is the correct spelling; you had minInterVal in the example
    await prefs.setBool('reference', reference.value);
    await prefs.setBool('groupCard', groupCard.value);
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    boxSerial.value = prefs.getBool('boxSerial') ?? true;
    firmwareVersion.value = prefs.getBool('firmwareVersion') ?? true;
    intervalTime.value = prefs.getBool('intervalTime') ?? true;
    urlToConnect.value = prefs.getBool('urlToConnect') ?? true;
    group.value = prefs.getBool('group') ?? true;
    maximumChargingPower.value = prefs.getBool('maximumChargingPower') ?? true;
  }

  Future<void> loadCardSettings() async {
    final prefs = await SharedPreferences.getInstance();
    minKwh.value = prefs.getBool('minKwh') ?? true;  // Assuming default value is true, adjust as necessary
    maxKwh.value = prefs.getBool('maxKwh') ?? true;
    maxSessionTime.value = prefs.getBool('maxSessionTime') ?? true;
    usageHour.value = prefs.getBool('usageHour') ?? true;
    minInterVal.value = prefs.getBool('minInterval') ?? true;  // Ensure the key matches what you used in saveCardSettings
    reference.value = prefs.getBool('reference') ?? true;
    groupCard.value = prefs.getBool('groupCard') ?? true;
  }

}
