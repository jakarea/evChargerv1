import 'dart:async';
import 'dart:convert';
import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/controllers/sharedPreference_controller.dart';
import 'package:ev_charger/models/active_session_model.dart';
import 'package:ev_charger/models/card_view_model.dart';
import 'package:ev_charger/models/chargers_view_model.dart';
import 'package:ev_charger/services/ocpp_service.dart';
import 'package:ev_charger/utils/log.dart';
import 'package:ev_charger/services/websocket_handler.dart';
import 'package:ev_charger/utils/helpers.dart';
import 'package:ev_charger/utils/internet_connection.dart';
import 'database_helper.dart';
import 'package:get/get.dart';
import 'package:ev_charger/services/smtp_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();

  Set<int> _authorizedChargerList = {};
  Map<int, String> _chargerStatuses = {};
  var timeZone = 'UTC+02:00';
  int counter = 1;
  int randomNumber = 2;
  int repeat = 0;
  int meterInterval = 600;
  int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  List<int> transactionId = List.filled(60, 0);
  List<int> nextSession = List.filled(60, 0);
  List<String> cardUId = List.filled(60, '');
  List<String> chargeBoxSerialNumber = List.filled(60, '');
  List<String> minIntervalBeforeReuse = List.filled(60, '');
  List<int> numberOfCharge = List.filled(60, 0);
  List<int> numberOfChargeDays = List.filled(60, 0);
  List<String> responseStatus = List.filled(60, '');
  List<int> cardId = List.filled(60, 0);

  List<int> meterValueCounter = List.filled(60, 0);
  List<int> randomTime = List.filled(60, 0);
  List<int> sessionEndTime = List.filled(60, 0);
  List<Map<dynamic, dynamic>> transactionArray = List.generate(900, (_) => {});
  List<bool> internetDisconnected = List.filled(60, false);
  List<int> intervalTime = List.filled(60, 0);
  List<double> randomKw = List.filled(60, 0);
  List<double> wPerSec = List.filled(60, 0);
  List<double> beginMeterValue = List.filled(60, 0);
  List<int> lastNotificationTime = List.filled(60, 0);
  List<int> lastNotificationTimeDiff = List.filled(60, 0);
  List<double> lastMeterValue = List.filled(60, 0);
  List<double> sumKwh = List.filled(60, 0);
  int force = 0;

  bool isConnected = false;
  bool accepted = true;
  bool blocked = false;

  Map<String, dynamic>? forceCardData;
  Map<String, dynamic>? forceCharger;

  static const Duration delayDuration = Duration(seconds: 3);

  final SharedPreferenceController sharedPreferenceController = SharedPreferenceController();
  final WebSocketHandler webSocketHandler = WebSocketHandler();
  final OCPPService ocppService = OCPPService();
  final CheckInternetConnection checkInternetConnection = CheckInternetConnection();
  final Helpers helpers = Helpers();

  factory BackgroundService() {
    return _instance;
  }

  BackgroundService._internal() {
    sharedPreferenceController.cleanSharedPref();
    checkInternetConnection.hasInternetConnection();
    startPeriodicTask();
    helpers.decideNextTimezoneChangerDate();
    helpers.delayInSeconds(2);
    loadSharedPreference();
  }

  Future<void> loadSharedPreference() async {
    _chargerStatuses =
        await sharedPreferenceController.loadAllChargerStatuses();
    Log.i("all charger states $_chargerStatuses");
    _authorizedChargerList =
        await sharedPreferenceController.loadAuthorizeChargerList();
  }

  void startPeriodicTask() async {
    /*await DatabaseHelper.instance
        .deleteNotificationLog(13);*/
    /*await DatabaseHelper.instance.updateTimeField(1, 1719464496);
    await DatabaseHelper.instance.updateTimeField(3, 1719464496);
    await DatabaseHelper.instance.updateTimeField(5, 1719464496);
    await DatabaseHelper.instance.updateTimeField(7, 1719464496);
    await DatabaseHelper.instance.updateTimeField(7, 1719464496);*/

    int time = 0;
    timeZone = await DatabaseHelper.instance.getUtcTime();
    ocppService.timeZone = timeZone;

    Timer.periodic(const Duration(seconds: 15), (Timer t) async {
      time++;
      DateTime utcNow = DateTime.now().toUtc();
      int utcNotInSec = utcNow.millisecondsSinceEpoch ~/ 1000;
      if (helpers.nextTimezoneChange != 0 && helpers.nextTimezoneChange <= utcNotInSec) {
        await DatabaseHelper.instance.insertOrReplaceTimeFormat(timeZone);
        helpers.decideNextTimezoneChangerDate();
      }

      if (time >= 18) {
        await checkInternetConnection.hasInternetConnection();
        time = 0;
        timeZone = await DatabaseHelper.instance.getUtcTime();
      }
      webSocketHandler.updateChargerTime();
      if (await checkInternetConnection.hasInternetConnection()) {
        await checkAndUpdateDatabase();
      }
    });
  }

  void startChargingImmediately(int chargerId, int cardId) async {
    if (await checkInternetConnection.hasInternetConnection() && accepted) {
      force = 1;
      forceCharger = await DatabaseHelper.instance.getChargerById(chargerId);
      forceCardData = await DatabaseHelper.instance.getCardById(cardId);
      ChargersViewModel charger = ChargersViewModel.fromJson(forceCharger!);
      /*chargerState[charger.id!] = 'heartbeat';*/
      sharedPreferenceController.saveChargerStatus(charger.id!, 'heartbeat');
      await DatabaseHelper.instance.updateTime(chargerId, 5);
    } else {
      await DatabaseHelper.instance.updateChargerId(cardId, '');
      await DatabaseHelper.instance
          .updateChargingStatus(chargerId, "start", -1);
    }

    // Log.i("startChargingImmediately 163\n");
  }

  void stopChargingImmediately(chargerId) async {
    // Log.i(chargerState[chargerId!]);
    DateTime utcNow = DateTime.now().toUtc();
    String sign = timeZone.substring(3, 4);
    int hours = int.parse(timeZone.substring(4, 6));
    int minutes = int.parse(timeZone.substring(7));
    int totalOffsetMinutes = (hours * 60 + minutes);
    DateTime now = utcNow.add(Duration(
        minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

    sessionEndTime[chargerId] = (now.millisecondsSinceEpoch ~/ 1000) - 4500;
    await DatabaseHelper.instance.updateTime(chargerId, 5);
  }

  Future<void> sendNewChargerBootNotification(ChargersViewModel charger) async {
    await webSocketHandler.connectToWebSocket(charger.urlToConnect!, charger.id!);
    // BootNotification for newly added charger
    await sendBootNotification(charger);
    sharedPreferenceController.saveChargerStatus(charger.id!, 'heartbeat');
  }

  Future<void> checkAndUpdateDatabase() async {
    Map<String, dynamic>? charger =
        await DatabaseHelper.instance.queryDueChargers();
    final SessionController sessionController = Get.find<SessionController>();

    Log.i("due chargers before $charger");

    if (force == 1) {
      charger = forceCharger;
    }

    if (charger != null) {
      ChargersViewModel chargerViewModel = ChargersViewModel.fromJson(charger);

      String? currentState = await sharedPreferenceController
          .checkChargerStatus(chargerViewModel.id!);
      intervalTime[chargerViewModel.id!] =
          int.parse(chargerViewModel.intervalTime!);

      switch (currentState) {
        case 'heartbeat':
          await DatabaseHelper.instance
              .updateChargingStatus(chargerViewModel.id!, "start", 0);

          Map<String, dynamic>? cardData = await DatabaseHelper.instance
              .getCardByGroupAndTime(chargerViewModel.groupId!);
          Log.v("card Data $cardData");

          if (force == 1) {
            cardData = forceCardData;
          }

          bool connected =
              await checkInternetConnection.hasInternetConnection();

          /**for acceptedModel*/
          Log.v("${chargerViewModel.id}  acceptedList ${webSocketHandler.getAcceptedChargerList}");
          bool accepted = false;
          if (webSocketHandler.getAcceptedChargerList.contains(chargerViewModel.id)) {
            accepted = true;
          }
          /**for authorizeModel*/
          bool authorize = false;
          if (_authorizedChargerList.contains(chargerViewModel.id)) {
            authorize = true;
          }

          Log.v(
              "${chargerViewModel.id} acceptedModel $accepted authorize $authorize");

          if (cardData != null && connected && accepted && !authorize) {
            Log.i("step 3 if block");
            DateTime utcNow = DateTime.now().toUtc();
            String sign = timeZone.substring(3, 4);
            int hours = int.parse(timeZone.substring(4, 6));
            int minutes = int.parse(timeZone.substring(7));
            int totalOffsetMinutes = (hours * 60 + minutes);
            DateTime now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            CardViewModel card = CardViewModel.fromJson(cardData);
            sharedPreferenceController.addToAuthorizeList(chargerViewModel.id!);
            loadSharedPreference();

            Log.i("before updating card ${card.id} ${chargerViewModel.id}");
            await DatabaseHelper.instance
                .updateChargerId(card.id!, chargerViewModel.id.toString());

            double minKwh = double.parse(card.minKwhPerSession);
            double maxKwh = double.parse(card.maxKwhPerSession);
            randomKw[chargerViewModel.id!] =
                minKwh + Random().nextDouble() * (maxKwh - minKwh);

            int minSessionTime = int.parse(card.minSessionTime!);
            int maxSessionTime = int.parse(card.maxSessionTime!);

            randomTime[chargerViewModel.id!] = minSessionTime +
                Random().nextInt(maxSessionTime - minSessionTime + 1);

            sessionEndTime[chargerViewModel.id!] =
                randomTime[chargerViewModel.id!] +
                    now.millisecondsSinceEpoch ~/ 1000;
            wPerSec[chargerViewModel.id!] =
                randomKw[chargerViewModel.id!] / 3.6;

            beginMeterValue[chargerViewModel.id!] =
                double.parse(chargerViewModel.meterValue!);

            sumKwh[chargerViewModel.id!] =
                beginMeterValue[chargerViewModel.id!];
            cardUId[chargerViewModel.id!] = card.uid;
            chargeBoxSerialNumber[chargerViewModel.id!] =
                chargerViewModel.chargeBoxSerialNumber!;
            cardId[chargerViewModel.id!] = card.id!;
            minIntervalBeforeReuse[chargerViewModel.id!] =
                card.minIntervalBeforeReuse!;
            numberOfCharge[chargerViewModel.id!] = int.parse(card.times);
            numberOfChargeDays[chargerViewModel.id!] =
                int.parse(card.daysUntil);

            if (force != 1) {
              Random random = Random();
              int min = 10;
              int preparingInterval =
                  min + random.nextInt(meterInterval - min + 1);
              await Future.delayed(Duration(seconds: preparingInterval));
            }
            force = 0;
            Log.i("Step 4 for : ${chargerViewModel.id}\n");

            /*authorizeModel[chargerViewModel.id!] =
                AuthorizeModel(chargerId: chargerViewModel.id!, status: 1);*/
            await ocppService.sendStatusNotification(
                chargerViewModel.id!,
                "StatusNotification",
                "Preparing",
                "",
                "",
                "",
                randomTime[chargerViewModel.id!],
                1);
            Log.i("Step 4 end for : ${chargerViewModel.id}\n");

            Log.i("Step 5 for : ${chargerViewModel.id}\n");
            int detectionDelay = Random().nextInt(5) + 2;
            await Future.delayed(Duration(seconds: detectionDelay));
            await ocppService.sendStatusNotification(
                chargerViewModel.id!,
                "StatusNotification",
                "Available",
                "Card detected",
                card.uid,
                "",
                randomTime[chargerViewModel.id!],
                1);

            Log.i("Step 6 for : ${chargerViewModel.id}\n");
            await ocppService.sendStatusNotification(
                chargerViewModel.id!,
                "AuthorizeNotification",
                "Authorize",
                "",
                card.uid,
                "",
                randomTime[chargerViewModel.id!],
                1);

            Log.i("Step 6 end for : ${chargerViewModel.id}\n");
            //You can now use 'card' safely within this block.

            detectionDelay = Random().nextInt(2);
            await helpers.delayInSeconds(detectionDelay + 1);

            // ignore: unrelated_type_equality_checks
            if (blocked) {
              Log.i(
                  "$blocked updating response status in if ${responseStatus[chargerViewModel.id!]}");
              // TODO: and send mail to admin
            } else {
              Log.i("Step 7 for : ${chargerViewModel.id}\n");
              /*chargerState[chargerViewModel.id!] = 'charging';*/
              sharedPreferenceController.saveChargerStatus(
                  chargerViewModel.id!, 'charging');

              await DatabaseHelper.instance
                  .updateChargingStatus(chargerViewModel.id!, "Charging", 0);
              await DatabaseHelper.instance
                  .updateChargerStatus(chargerViewModel.id!, "1");

              final SessionController sessionController =
                  Get.find<SessionController>();

              nextSession[chargerViewModel.id!] = helpers.getRandomSessionRestTime(
                  numberOfCharge[chargerViewModel.id!],
                  numberOfChargeDays[chargerViewModel.id!],
                  randomTime[chargerViewModel.id!]);
              await DatabaseHelper.instance.updateTimeField(
                  card.id!, //cardId[chargerViewModel.id!]
                  nextSession[chargerViewModel.id!]);
              await ocppService.sendStatusNotification(chargerViewModel.id!, "SuspendedEV",
                  "", "", "", "", randomTime[chargerViewModel.id!], 1);

              Log.i("Step 8  for : ${chargerViewModel.id}\n");
              detectionDelay = Random().nextInt(3);
              await helpers.delayInSeconds(detectionDelay);
              await ocppService.startTransaction(chargerViewModel.id!, card.uid,
                  beginMeterValue[chargerViewModel.id!]);

              DateTime utcNow = DateTime.now().toUtc();
              String sign = timeZone.substring(3, 4);
              int hours = int.parse(timeZone.substring(4, 6));
              int minutes = int.parse(timeZone.substring(7));
              int totalOffsetMinutes = (hours * 60 + minutes);
              DateTime now = utcNow.add(Duration(
                  minutes:
                      sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

              String timestamp =
                  DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
              DatabaseHelper.instance.insertOrUpdateActiveSession(
                  chargerId: chargerViewModel.id!,
                  cardId: card.id!,
                  transactionStartTime: utcNow.millisecondsSinceEpoch ~/ 1000,
                  kwh: randomKw[chargerViewModel.id!].toString(),
                  sessionTime: randomTime[chargerViewModel.id!].toString());

              sessionController.addSession(ActiveSessionModel(
                  cardId: card.id!.toInt(),
                  chargerId: chargerViewModel.id!.toString(),
                  chargerName: chargerViewModel.chargePointVendor!,
                  chargerModel: chargerViewModel.chargePointModel!,
                  serialBox: chargerViewModel.chargeBoxSerialNumber!,
                  cardNumber: card.cardNumber,
                  msp: card.msp,
                  uid: card.uid,
                  transactionId: webSocketHandler.getTransactionId[chargerViewModel.id!]!,
                  transactionSession:
                      (now.millisecondsSinceEpoch ~/ 1000).toInt(),
                  kwh: randomKw[chargerViewModel.id!].toString(),
                  sessionTime: randomTime[chargerViewModel.id!].toString()));

              Log.i("Step 9 for : ${chargerViewModel.id}\n");

              await ocppService.sendMeterValues(chargerViewModel.id!, {
                "timestamp": "${timestamp}",
                "sampledValue": [
                  {
                    "value":
                        "${(sumKwh[chargerViewModel.id!] / 1000).toStringAsFixed(3)}",
                    "context": "Transaction.Begin",
                    "unit": "kWh"
                  }
                ]
              });

              detectionDelay = Random().nextInt(2);
              await helpers.delayInSeconds(detectionDelay);

              Log.i("Step 10 for : ${chargerViewModel.id}\n");
              utcNow = DateTime.now().toUtc();
              sign = timeZone.substring(3, 4);
              hours = int.parse(timeZone.substring(4, 6));
              minutes = int.parse(timeZone.substring(7));
              totalOffsetMinutes = (hours * 60 + minutes);
              now = utcNow.add(Duration(
                  minutes:
                      sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

              timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
              await ocppService.sendMeterValues(chargerViewModel.id!, {
                "timestamp": "${timestamp}",
                "sampledValue": [
                  {
                    "value":
                        "${(sumKwh[chargerViewModel.id!] / 1000).toStringAsFixed(3)}",
                    "context": "Sample.Periodic",
                    "measurand": "Energy.Active.Import.Register",
                    "location": "Outlet",
                    "unit": "kWh"
                  }
                ]
              });

              Log.i("Step 11 for : ${chargerViewModel.id}\n");
              DatabaseHelper.instance.logNotification(
                  messageId: ocppService.messageId[chargerViewModel.id!],
                  chargerId: chargerViewModel.id!,
                  uid: cardUId[chargerViewModel.id!],
                  transactionId: webSocketHandler.getTransactionId[chargerViewModel.id!]!,
                  meterValue: sumKwh[chargerViewModel.id!],
                  beginMeterValue: beginMeterValue[chargerViewModel.id!],
                  startTime: ocppService.startTime[chargerViewModel.id!],
                  status: "charging",
                  numberOfCharge: numberOfCharge[chargerViewModel.id!],
                  numberOfChargeDays: numberOfChargeDays[chargerViewModel.id!]);

              await ocppService.sendStatusNotification(
                  chargerViewModel.id!,
                  "StatusNotification",
                  "Charging",
                  "",
                  "",
                  "",
                  randomTime[chargerViewModel.id!],
                  1);
              /*chargerState[chargerViewModel.id!] = 'charging';*/
              sharedPreferenceController.saveChargerStatus(
                  chargerViewModel.id!, 'charging');
              lastNotificationTime[chargerViewModel.id!] =
                  now.millisecondsSinceEpoch ~/ 1000;
              intervalTime[chargerViewModel.id!] = meterInterval;
            }
          } else {
            Log.i("Step 3  else block: ${chargerViewModel.id}\n");
            await ocppService.sendHeartbeat(chargerViewModel.id!);

            /*need to check*/
            // CardViewModel card = CardViewModel.fromJson(cardData!);
            await DatabaseHelper.instance
                .removeChargerFromCard(chargerViewModel.id!);
            await DatabaseHelper.instance
                .updateChargingStatus(chargerViewModel.id!, "start", -1);
          }

          //await DatabaseHelper.instance.updateTime(chargerViewModel.id!, int.parse(chargerViewModel.intervalTime!));

          break;

        case 'charging':
          intervalTime[chargerViewModel.id!] = meterInterval;
          DateTime utcNow = DateTime.now().toUtc();
          String sign = timeZone.substring(3, 4);
          int hours = int.parse(timeZone.substring(4, 6));
          int minutes = int.parse(timeZone.substring(7));
          int totalOffsetMinutes = (hours * 60 + minutes);
          DateTime now = utcNow.add(Duration(
              minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

          if (sessionEndTime[chargerViewModel.id!] >=
              (now.millisecondsSinceEpoch ~/ 1000)) {
            Log.i("Step 12 for : ${chargerViewModel.id}\n");

            nowTime = now.millisecondsSinceEpoch ~/ 1000;
            lastNotificationTimeDiff[chargerViewModel.id!] =
                nowTime - lastNotificationTime[chargerViewModel.id!];
            if (lastNotificationTimeDiff[chargerViewModel.id!] >=
                meterInterval * 2) {
              stopChargingImmediately(chargerViewModel.id!);
            }
            sumKwh[chargerViewModel.id!] = sumKwh[chargerViewModel.id!] +
                (lastNotificationTimeDiff[chargerViewModel.id!] *
                    wPerSec[chargerViewModel.id!]);

            utcNow = DateTime.now().toUtc();
            sign = timeZone.substring(3, 4);
            hours = int.parse(timeZone.substring(4, 6));
            minutes = int.parse(timeZone.substring(7));
            totalOffsetMinutes = (hours * 60 + minutes);
            now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
            await ocppService.sendMeterValues(chargerViewModel.id!, {
              "timestamp": "${timestamp}",
              "sampledValue": [
                {
                  "value":
                      "${(sumKwh[chargerViewModel.id!] / 1000).toStringAsFixed(3)}",
                  "context": "Sample.Periodic",
                  "measurand": "Energy.Active.Import.Register",
                  "location": "Outlet",
                  "unit": "kWh"
                }
              ]
            });
            lastNotificationTime[chargerViewModel.id!] =
                now.millisecondsSinceEpoch ~/ 1000;
            await DatabaseHelper.instance.updateBeginMeterValue(
                chargerViewModel.id!, sumKwh[chargerViewModel.id!]);

            DatabaseHelper.instance.logNotification(
                messageId: ocppService.messageId[chargerViewModel.id!],
                chargerId: chargerViewModel.id!,
                uid: cardUId[chargerViewModel.id!],
                transactionId: webSocketHandler.getTransactionId[chargerViewModel.id!]!,
                meterValue: sumKwh[chargerViewModel.id!],
                beginMeterValue: beginMeterValue[chargerViewModel.id!],
                startTime: ocppService.startTime[chargerViewModel.id!],
                status: "charging",
                numberOfCharge: numberOfCharge[chargerViewModel.id!],
                numberOfChargeDays: numberOfChargeDays[chargerViewModel.id!]);
            // check if it is near about to end session time then set a random interval to make make it natual, when suspenend it
            int interval = intervalTime[chargerViewModel.id!];

            if (sessionEndTime[chargerViewModel.id!] <=
                (now.millisecondsSinceEpoch ~/ 1000) + interval) {
              Random random = Random();
              int min = interval ~/ 5;
              int max = interval - min;
              intervalTime[chargerViewModel.id!] =
                  min + random.nextInt(max - min + 1);
            }
          } else {
            Log.i("Step 13 for : ${chargerViewModel.id}\n");
            DateTime utcNow = DateTime.now().toUtc();
            String sign = timeZone.substring(3, 4);
            int hours = int.parse(timeZone.substring(4, 6));
            int minutes = int.parse(timeZone.substring(7));
            int totalOffsetMinutes = (hours * 60 + minutes);
            DateTime now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            nowTime = now.millisecondsSinceEpoch ~/ 1000;
            lastNotificationTimeDiff[chargerViewModel.id!] =
                nowTime - lastNotificationTime[chargerViewModel.id!];

            sumKwh[chargerViewModel.id!] = sumKwh[chargerViewModel.id!] +
                (lastNotificationTimeDiff[chargerViewModel.id!] *
                    wPerSec[chargerViewModel.id!]);
            await ocppService.sendStatusNotification(chargerViewModel.id!, "SuspendedEV",
                "", "", "", "", randomTime[chargerViewModel.id!], 1);
            await DatabaseHelper.instance
                .deleteNotificationLog(chargerViewModel.id!);

            Log.i("Step 14 for : ${chargerViewModel.id}\n");
            String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);

            await ocppService.sendMeterValues(chargerViewModel.id!, {
              "timestamp": "${timestamp}",
              "sampledValue": [
                {
                  "value":
                      "${(sumKwh[chargerViewModel.id!] / 1000).toStringAsFixed(3)}",
                  "context": "Sample.Periodic",
                  "measurand": "Energy.Active.Import.Register",
                  "location": "Outlet",
                  "unit": "kWh"
                }
              ]
            });

            Log.i("Step 15 for : ${chargerViewModel.id}\n");
            await ocppService.sendStatusNotification(
                chargerViewModel.id!,
                "StatusNotification",
                "Finishing",
                "",
                "",
                "",
                randomTime[chargerViewModel.id!],
                1);

            Log.i("Step 16 for : ${chargerViewModel.id}\n");
            timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);

            await ocppService.sendMeterValues(chargerViewModel.id!, {
              "timestamp": "${timestamp}",
              "sampledValue": [
                {
                  "value":
                      "${(sumKwh[chargerViewModel.id!] / 1000).toStringAsFixed(3)}",
                  "context": "Transaction.End",
                  "measurand": "Energy.Active.Import.Register",
                  "location": "Outlet",
                  "unit": "kWh"
                }
              ]
            });

// TODO:

            await DatabaseHelper.instance
                .updateChargingStatus(chargerViewModel.id!, "N/A", 0);
            await DatabaseHelper.instance
                .updateChargerStatus(chargerViewModel.id!, "2");

            /*authorizeModel[chargerViewModel.id!] =
                AuthorizeModel(chargerId: chargerViewModel.id!, status: 0);*/
            sharedPreferenceController
                .removeFromAuthorizeList(chargerViewModel.id!);
            loadSharedPreference();

            Log.i("Step 17 for : ${chargerViewModel.id}\n");
            await ocppService.stopTransaction(
                chargerViewModel.id!,
                beginMeterValue[chargerViewModel.id!],
                sumKwh[chargerViewModel.id!],
                cardUId[chargerViewModel.id!]);
            await DatabaseHelper.instance
                .deleteActiveSessionByChargerId(chargerViewModel.id!);

            await DatabaseHelper.instance.updateBeginMeterValue(
                chargerViewModel.id!, sumKwh[chargerViewModel.id!]);
            sessionController
                .removeSessionByChargerId(chargerViewModel.id.toString());
            await DatabaseHelper.instance
                .updateChargerId(cardId[chargerViewModel.id!], "");
            await DatabaseHelper.instance
                .removeChargerId(chargerViewModel.id!, "");

            Log.i("Step 2 for : ${chargerViewModel.id}\n");
            await ocppService.sendStatusNotification(chargerViewModel.id!,
                "StatusNotification", "Available", "", "", "", 0, 0);
            // Delay for 1 second
            await Future.delayed(delayDuration);
            await ocppService.sendStatusNotification(chargerViewModel.id!,
                "StatusNotification", "Available", "", "", "", 0, 1);
            Log.i("Step 2 end for : ${chargerViewModel.id}\n");
            sharedPreferenceController.saveChargerStatus(
                chargerViewModel.id!, 'heartbeat');
            /*chargerState[chargerViewModel.id!] = 'heartbeat';*/
          }

          break;
        default:

          await webSocketHandler.connectToWebSocket(
                  chargerViewModel.urlToConnect!, chargerViewModel.id!);

          await DatabaseHelper.instance
              .updateChargerStatus(chargerViewModel.id!, "2");
          await sendBootNotification(chargerViewModel);
          Log.d("state $currentState default send boot");
      } // switch end

      int interval = intervalTime[chargerViewModel.id!] - 15;

      // If charger is available, do not wait for interval time, set a new interval time and show available immedately
      if (currentState == 'available') {
        interval = 3;
      }
      await DatabaseHelper.instance.updateTime(chargerViewModel.id!, interval);
    } // No charger found
  }

  Future<void> sendBootNotification(ChargersViewModel charger) async {
    webSocketHandler.acquireCharger(charger.id!, charger.urlToConnect!);
    Log.i("Step 1 for : ${charger.id}\n");
    int? chargerId = charger.id;

    var log = await DatabaseHelper.instance.getNotificationLog("$chargerId");
    String status;

    if (log == null) {
      var bootNotification = jsonEncode([
        2,
        "${ocppService.messageId[charger.id!]++}",
        "BootNotification",
        {
          "chargePointVendor": charger.chargePointVendor,
          "chargePointModel": charger.chargePointModel,
          "chargePointSerialNumber": charger.chargePointSerialNumber,
          "chargeBoxSerialNumber": charger.chargeBoxSerialNumber,
          "firmwareVersion": charger.firmwareVersion
        }
      ]);
      //bootNotification
      await DatabaseHelper.instance.deleteActiveSessionByChargerId(charger.id!);
      await DatabaseHelper.instance.updateChargerStatus(charger.id!, "2");
      await DatabaseHelper.instance
          .updateChargingStatus(charger.id!, "start", 0);
      await DatabaseHelper.instance.removeChargerId(charger.id!, "");

      await ocppService.sendMessage(bootNotification, charger.id);
      Log.i("Step 1 end for : ${charger.id}\n");

      await DatabaseHelper.instance
          .updateTime(charger.id!, int.parse(charger.intervalTime!));

      // Delay for 1 second
      await Future.delayed(delayDuration);
      await ocppService.sendStatusNotification(
          charger.id!, "StatusNotification", "Available", "", "", "", 0, 0);
      // Delay for 1 second
      await Future.delayed(delayDuration);

      await ocppService.sendStatusNotification(
          charger.id!, "StatusNotification", "Available", "", "", "", 0, 1);

      /*chargerState[charger.id!] = 'heartbeat';*/
      sharedPreferenceController.saveChargerStatus(charger.id!, 'heartbeat');
    } else {
      DateTime utcNow = DateTime.now().toUtc();
      String sign = timeZone.substring(3, 4);
      int hours = int.parse(timeZone.substring(4, 6));
      int minutes = int.parse(timeZone.substring(7));
      int totalOffsetMinutes = (hours * 60 + minutes);
      DateTime now = utcNow.add(Duration(
          minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

      ocppService.messageId[charger.id!] = log['messageId'];
      sharedPreferenceController.saveChargerStatus(charger.id!, 'charging');
      sessionEndTime[charger.id!] = (now.millisecondsSinceEpoch ~/ 1000) - 3600;
      sumKwh[charger.id!] = log['meter_value'];
      webSocketHandler.updateTransactionId(charger.id!, log['transactionId']);
      beginMeterValue[charger.id!] = log['begin_meter_value'];
      cardUId[charger.id!] = log['uid'];
      numberOfCharge[charger.id!] = log['numberOfCharge'];
      numberOfChargeDays[charger.id!] = log['numberOfChargeDays'];

      stopChargingImmediately(chargerId);
    }
  }


  Future<void> blockedChargerHandle(int chargerId) async {
    Map<String, dynamic>? cardData =
        await DatabaseHelper.instance.getCardByChargerId(chargerId);
    CardViewModel card = CardViewModel.fromJson(cardData!);
    // TODO: and send mail to admin
    var uid = cardUId[chargerId];
    var chargeBoxNumber = chargeBoxSerialNumber[chargerId];
    var cardNumber = card.cardNumber;
    var msp = card.msp;

    /**updating charger status*/
    await DatabaseHelper.instance.updateChargingStatus(chargerId, "Start", -1);
    await DatabaseHelper.instance.updateChargerStatus(chargerId, "0");

    SmtpService.sendEmail(
        subject: 'Card Blocked',
        text: "$uid has blocked!",
        headerText: "BoxSerialNumber: $chargeBoxNumber",
        contentText: "MSP: $msp <br> Card Number: $cardNumber");

    nextSession[chargerId] = helpers.getRandomSessionRestTime(
        numberOfCharge[chargerId],
        numberOfChargeDays[chargerId],
        randomTime[chargerId]);

    await DatabaseHelper.instance
        .updateTimeField(cardId[chargerId], nextSession[chargerId]);
    await DatabaseHelper.instance.updateChargerId(card.id!, '');

    await ocppService.sendStatusNotification(
        chargerId, "StatusNotification", "Available", "", "", "", 0, 1);

    await ocppService.sendHeartbeat(chargerId);
    sharedPreferenceController.saveChargerStatus(chargerId, 'heartbeat');
    /*chargerState[chargerId] = 'heartbeat';*/
  }
}