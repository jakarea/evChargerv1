import 'dart:async';
import 'dart:convert';
import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/models/active_session_model.dart';
import 'package:ev_charger/models/card_view_model.dart';
import 'package:ev_charger/models/chargers_view_model.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:get/get.dart';
import 'package:ev_charger/services/smtp_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:io';
import 'package:logger/logger.dart';

// import 'package:connectivity/connectivity.dart';
import 'package:http/http.dart' as http;

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart'; // Use `package:web_socket_channel/io.dart` for non-web platforms

// ws://ws.evc-net.com/EVB-P23001851/
// ws://ocpp.e-flux.nl/1.6/e-flux/ITA_220202/
// ws://connect.longship.io/93f511b5af8c363135deb16f4feed1e5/TEST2

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  late List<WebSocketChannel?> _sockets;

  List<String> chargerState = List.filled(100, '');
  List<String> chargerLastState = List.filled(100, '');
  var timeZone = 'UTC+02:00';
  int counter = 1;
  int randomNumber = 2;
  int repeat = 0;
  int meterInterval = 60;
  int nowTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  List<int> transactionId = List.filled(900, 0);
  List<int> nextSession = List.filled(900, 0);
  List<String> cardUId = List.filled(900, '');
  List<String> chargeBoxSerialNumber = List.filled(900, '');
  List<String> minIntervalBeforeReuse = List.filled(900, '');
  List<int> numberOfCharge = List.filled(900, 0);
  List<int> numberOfChargeDays = List.filled(900, 0);
  List<String> responseStatus = List.filled(900, '');
  List<int> cardId = List.filled(900, 0);
  List<int> messageId = List.filled(900, 1);
  List<int> meterValueCounter = List.filled(900, 0);
  List<int> randomTime = List.filled(900, 0);
  List<int> sessionEndTime = List.filled(900, 0);
  List<Map<dynamic, dynamic>> transactionArray = List.generate(900, (_) => {});
  List<bool> internetDisconnected = List.filled(900, false);
  List<int> intervalTime = List.filled(900, 0);
  List<double> randomKw = List.filled(900, 0);
  List<double> wPerSec = List.filled(900, 0);
  List<double> beginMeterValue = List.filled(900, 0);
  List<int> lastNotificationTime = List.filled(900, 0);
  List<int> lastNotificationTimeDiff = List.filled(900, 0);
  List<int> timerToPing = List.filled(100, 0);
  List<double> lastMeterValue = List.filled(900, 0);
  List<double> sumKwh = List.filled(900, 0);
  int force = 0;
  Map<int, ChargerData> chargerData = {};

  String nextTimezone = 'UTC+01:00';
  int nextTimezoneChange = 0;
  bool _socketConnected = false;
  bool isConnected = false;
  bool blocked = false;

  Map<String, dynamic>? forceCardData;
  Map<String, dynamic>? forceCharger;
  List<String> startTime = List.filled(900,
      DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(DateTime.now()).toString());
  static const Duration delayDuration = Duration(seconds: 3);
  final Logger logger = Logger();

  factory BackgroundService() {
    return _instance;
  }

  BackgroundService._internal() {
    checkInternetConnection();
    startPeriodicTask();
    decideNextTimezoneChangerDate();
    _sockets = List.filled(100, null);
    // _channels = List.filled(100, null);
  }

  Future<void> delayInSeconds(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
  }

  void decideNextTimezoneChangerDate() {
    int currentMonth = DateTime.now().month;
    currentMonth = 1;
    if (currentMonth > 3 && currentMonth <= 10) {
      setLastSundayOfMarch();
    } else if (currentMonth > 10 || currentMonth <= 3) {
      setLastSundayOfOctober();
    }
  }

  void setLastSundayOfOctober() {
    DateTime now = DateTime.now().toUtc();
    int nextOctoberYear = now.month <= 10 ? now.year : now.year + 1;
    int date = 31;
    DateTime lastDayOfOctober = DateTime(nextOctoberYear, 10, date);
    int lastDayOfWeek = lastDayOfOctober.weekday;
    for (int i = lastDayOfWeek; i >= 0; i--) {
      DateTime lastDayOfOctober = DateTime(nextOctoberYear, 10, date - i);
      int dayNo = lastDayOfOctober.weekday;
      if (dayNo == 7) {
        DateTime lastSaturdayOfOctober =
            DateTime.utc(nextOctoberYear, 10, date - i, 0, 59, 59);
        nextTimezoneChange =
            (lastSaturdayOfOctober.millisecondsSinceEpoch ~/ 1000) - 1;
      }
    }
    nextTimezone = 'UTC+01:00';
  }

  void setLastSundayOfMarch() {
    DateTime now = DateTime.now().toUtc();
    int nextMarchYear = now.month <= 3 ? now.year : now.year + 1;
    int date = 31;
    DateTime lastDayOfMarch = DateTime(nextMarchYear, 3, date);
    int lastDayOfWeek = lastDayOfMarch.weekday;
    for (int i = lastDayOfWeek; i >= 0; i--) {
      DateTime lastDayOfOctober = DateTime(nextMarchYear, 3, date - i);
      int dayNo = lastDayOfOctober.weekday;
      if (dayNo == 7) {
        DateTime lastSaturdayOfOctober =
            DateTime.utc(nextMarchYear, 3, date - i, 1, 59, 59);
        nextTimezoneChange =
            lastSaturdayOfOctober.millisecondsSinceEpoch ~/ 1000;
      }
    }
    nextTimezone = 'UTC+02:00';
  }

  void stopChargingImmediately(chargerId) async {
    // logger.i(chargerState[chargerId!]);
    DateTime utcNow = DateTime.now().toUtc();
    String sign = timeZone.substring(3, 4);
    int hours = int.parse(timeZone.substring(4, 6));
    int minutes = int.parse(timeZone.substring(7));
    int totalOffsetMinutes = (hours * 60 + minutes);
    DateTime now = utcNow.add(Duration(
        minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

    sessionEndTime[chargerId] = (now.millisecondsSinceEpoch ~/ 1000) - 4500;
    await DatabaseHelper.instance.updateTime(chargerId, 15);
  }

  Future<bool> checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        isConnected = true;
        return true;
      } else {
        isConnected = false;
        return false;
      }
    } catch (e) {
      isConnected = false;
      return false;
    }
  }

  void startChargingImmediately(int chargerId, int cardId) async {
    isConnected = await checkInternetConnection();
    logger.e("is connected internet $isConnected");
    if (isConnected) {
      force = 1;
      forceCharger = await DatabaseHelper.instance.getChargerById(chargerId);
      forceCardData = await DatabaseHelper.instance.getCardById(cardId);
      ChargersViewModel charger = ChargersViewModel.fromJson(forceCharger!);
      chargerState[charger.id!] = 'heartbeat';
      await DatabaseHelper.instance.updateTime(chargerId, 15);
    } else {
      await DatabaseHelper.instance.updateChargerId(cardId, '');
      await DatabaseHelper.instance
          .updateChargingStatus(chargerId, "start", -1);
    }

    // logger.i("startChargingImmediately 163\n");
  }

  int getRandomSessionRestTime(int numberOfSession, int days, int lastSession) {
    if (lastSession < 12000) {
      lastSession = 12000;
    }

    int totalTime = 86400 * days;
    int averageUse = totalTime ~/ numberOfSession;
    Random random = Random();
    int halfOfAverageUse = averageUse ~/ 2;
    int thirdOfAverageUse = averageUse ~/ 3;
    int randomNumber =
        random.nextInt(thirdOfAverageUse) + random.nextInt(halfOfAverageUse);
    int nextSession = randomNumber.abs() + lastSession * 3;
    DateTime now = DateTime.now().toUtc();
    return nextSession.toInt() + now.millisecondsSinceEpoch ~/ 1000;
  }

// Function to add a new charger with initial time = 0 and URL
  void acquireCharger(int chargerId, String url) {
    chargerData[chargerId] = ChargerData(time: 0, url: url);
  }

  void updateChargerTime() {
    chargerData.forEach((chargerId, data) async {
      logger.t("chargerTimerData@@@@@@@@ chargerID=$chargerId  ${data.time}");
      if (data.time == 4) {
        resetChargerTime(chargerId);
        // Call another function here
        if (await checkInternetConnection()) {
          connectToWebSocket(data.url, chargerId);
          //logger.t("Charger $chargerId reconnection to ${data.url}.");
        }
      } else {
        data.time++;
      }
    });
  }

  // Function to reset charger time to 0
  void resetChargerTime(int chargerId) {
    chargerData[chargerId]!.time = 0;
  }

  void startPeriodicTask() async {
    /*await DatabaseHelper.instance
        .deleteNotificationLog(4);*/

    int time = 0;
    timeZone = await DatabaseHelper.instance.getUtcTime();
    //isConnected = true;
    Timer.periodic(const Duration(seconds: 15), (Timer t) async {
      time++;
      DateTime utcNow = DateTime.now().toUtc();
      int utcNotInSec = utcNow.millisecondsSinceEpoch ~/ 1000;
      if (nextTimezoneChange != 0 && nextTimezoneChange <= utcNotInSec) {
        await DatabaseHelper.instance.insertOrReplaceTimeFormat(timeZone);
        decideNextTimezoneChangerDate();
      }

      if (time >= 12) {
        await checkInternetConnection();
        time = 0;
        timeZone = await DatabaseHelper.instance.getUtcTime();
      }
      logger.i("startPeriodicTask() checking internet $isConnected");
      updateChargerTime();
      if (isConnected) {
        await checkAndUpdateDatabase();
      }
    });
  }

  bool isCurrentTimeInRange(String timeRange) {
    // Split the timeRange string to get start and end times
    List<String> times = timeRange.split(' - ');
    String startTimeStr = times[0];
    String endTimeStr = times[1];

    // Convert the string times to TimeOfDay
    List<String> startParts = startTimeStr.split('.');
    TimeOfDay startTimes = TimeOfDay(
        hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));

    List<String> endParts = endTimeStr.split('.');
    TimeOfDay endTime =
        TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

    // Get the current time as a TimeOfDay
    final now = TimeOfDay.now();

    // Function to convert TimeOfDay to minutes for easier comparison
    double toMinutes(TimeOfDay tod) => tod.hour * 60.0 + tod.minute;

    // Compare the current time with the parsed TimeOfDay objects
    double nowInMinutes = toMinutes(now);
    double startInMinutes = toMinutes(startTimes);
    double endInMinutes = toMinutes(endTime);

    return nowInMinutes >= startInMinutes && nowInMinutes <= endInMinutes;
  }

  Future<void> sendNewChargerBootNotification(ChargersViewModel charger) async {
    final SessionController sessionController = Get.find<SessionController>();

    await connectToWebSocket(charger.urlToConnect!, charger.id!).then((_) {
      // logger.i(charger.urlToConnect);
      // logger.i('WebSocket connection hello established: 168');
      // logger.i(charger.id);
    }).catchError((error) {
      // logger.i('Error establishing WebSocket connection 282: $error');
    });
    //  logger.i('Step 1 BootNotification for newly added charger');
    // BootNotification for newly added charger
    await sendBootNotification(charger);
    chargerState[charger.id!] = 'heartbeat';
  }

  Future<void> checkAndUpdateDatabase() async {
    Map<String, dynamic>? charger =
        await DatabaseHelper.instance.queryDueChargers();
    final SessionController sessionController = Get.find<SessionController>();

    if (force == 1) {
      charger = forceCharger;
    }
    if (charger != null) {
      ChargersViewModel chargerViewModel = ChargersViewModel.fromJson(charger);

      String currentState = chargerState[chargerViewModel.id!];
      intervalTime[chargerViewModel.id!] =
          int.parse(chargerViewModel.intervalTime!);
      CardViewModel? card;

      switch (currentState) {
        case 'heartbeat':
          await DatabaseHelper.instance
              .updateChargingStatus(chargerViewModel.id!, "start", 0);

          Map<String, dynamic>? cardData = await DatabaseHelper.instance
              .getCardByGroupAndTime(chargerViewModel.groupId!);

          if (force == 1) {
            cardData = forceCardData;
          }

          logger.e("case heartbeat $isConnected $cardData");

          if (cardData != null && isConnected) {
            DateTime utcNow = DateTime.now().toUtc();
            String sign = timeZone.substring(3, 4);
            int hours = int.parse(timeZone.substring(4, 6));
            int minutes = int.parse(timeZone.substring(7));
            int totalOffsetMinutes = (hours * 60 + minutes);
            DateTime now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            CardViewModel card = CardViewModel.fromJson(cardData);

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
              // Generate a random number within the range
              int preparingInterval =
                  min + random.nextInt(meterInterval - min + 1);
              await Future.delayed(Duration(seconds: preparingInterval));
            }
            force = 0;
            logger.i("Step 4 for : ${chargerViewModel.id}\n");
            await sendStatusNotification(
                chargerViewModel.id!,
                "StatusNotification",
                "Preparing",
                "",
                "",
                "",
                randomTime[chargerViewModel.id!],
                1);
            logger.i("Step 4 end for : ${chargerViewModel.id}\n");

            logger.i("Step 5 for : ${chargerViewModel.id}\n");
            int detectionDelay = Random().nextInt(12) + 2;
            await Future.delayed(Duration(seconds: detectionDelay));
            await sendStatusNotification(
                chargerViewModel.id!,
                "StatusNotification",
                "Available",
                "Card detected",
                card.uid,
                "",
                randomTime[chargerViewModel.id!],
                1);

            logger.i("Step 6 for : ${chargerViewModel.id}\n");
            await sendStatusNotification(
                chargerViewModel.id!,
                "AuthorizeNotification",
                "Authorize",
                "",
                card.uid,
                "",
                randomTime[chargerViewModel.id!],
                1);
            logger.i("Step 6 end for : ${chargerViewModel.id}\n");
            //You can now use 'card' safely within this block.

            detectionDelay = Random().nextInt(2);
            await delayInSeconds(detectionDelay+1);

            logger.i("$blocked before if response status ${chargerViewModel.id} ${chargerViewModel.chargeBoxSerialNumber}  ${responseStatus[chargerViewModel.id!]}");
            logger.i("all response data ${responseStatus}");
            // ignore: unrelated_type_equality_checks
            if (blocked) {
              logger.i(
                  "$blocked updating response status in if ${responseStatus[chargerViewModel.id!]}");
              // TODO: and send mail to admin
              /*var uid = cardUId[chargerViewModel.id!];
              var chargeBoxNumber = chargeBoxSerialNumber[chargerViewModel.id!];
              var cardNumber = card.cardNumber;
              var msp = card.msp;*/

              /**updating charger status*/
              /*await DatabaseHelper.instance
                  .updateChargingStatus(chargerViewModel.id!, "Start", -1);
              await DatabaseHelper.instance
                  .updateChargerStatus(chargerViewModel.id!, "0");

              SmtpService.sendEmail(
                  subject: 'Card Blocked',
                  text: "$uid has blocked!",
                  headerText: "BoxSerialNumber: $chargeBoxNumber",
                  contentText: "MSP: $msp <br> Card Number: $cardNumber");

              nextSession[chargerViewModel.id!] =
                  await getRandomSessionRestTime(
                      numberOfCharge[chargerViewModel.id!],
                      numberOfChargeDays[chargerViewModel.id!],
                      randomTime[chargerViewModel.id!]);

              await DatabaseHelper.instance.updateTimeField(
                  cardId[chargerViewModel.id!],
                  nextSession[chargerViewModel.id!]);
              await DatabaseHelper.instance.updateChargerId(card.id!, '');

              await sendStatusNotification(chargerViewModel.id!,
                  "StatusNotification", "Available", "", "", "", 0, 1);

              await sendHeartbeat(chargerViewModel.id!);
              chargerState[chargerViewModel.id!] = 'heartbeat';*/
            } else {
              logger.i(
                  "$blocked updating response status in else ${responseStatus[chargerViewModel.id!]}");
              logger.i("Step 7 for : ${chargerViewModel.id}\n");

              await DatabaseHelper.instance
                  .updateChargingStatus(chargerViewModel.id!, "Charging", 0);
              await DatabaseHelper.instance
                  .updateChargerStatus(chargerViewModel.id!, "1");

              final SessionController sessionController =
                  Get.find<SessionController>();

              nextSession[chargerViewModel.id!] = getRandomSessionRestTime(
                  numberOfCharge[chargerViewModel.id!],
                  numberOfChargeDays[chargerViewModel.id!],
                  randomTime[chargerViewModel.id!]);
              await DatabaseHelper.instance.updateTimeField(
                  cardId[chargerViewModel.id!],
                  nextSession[chargerViewModel.id!]);
              await sendStatusNotification(chargerViewModel.id!, "SuspendedEV",
                  "", "", "", "", randomTime[chargerViewModel.id!], 1);

              logger.i("Step 8  for : ${chargerViewModel.id}\n");
              detectionDelay = Random().nextInt(3);
              await delayInSeconds(detectionDelay);
              await startTransaction(chargerViewModel.id!, card.uid,
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
                  transactionSession:
                      (now.millisecondsSinceEpoch ~/ 1000).toInt(),
                  kwh: randomKw[chargerViewModel.id!].toString(),
                  sessionTime: randomTime[chargerViewModel.id!].toString()));

              logger.i("Step 9 for : ${chargerViewModel.id}\n");

              await sendMeterValues(chargerViewModel.id!, {
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
              await delayInSeconds(detectionDelay);

              logger.i("Step 10 for : ${chargerViewModel.id}\n");
              utcNow = DateTime.now().toUtc();
              sign = timeZone.substring(3, 4);
              hours = int.parse(timeZone.substring(4, 6));
              minutes = int.parse(timeZone.substring(7));
              totalOffsetMinutes = (hours * 60 + minutes);
              now = utcNow.add(Duration(
                  minutes:
                      sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

              timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
              await sendMeterValues(chargerViewModel.id!, {
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

              logger.i("Step 11 for : ${chargerViewModel.id}\n");
              DatabaseHelper.instance.logNotification(
                  messageId: messageId[chargerViewModel.id!],
                  chargerId: chargerViewModel.id!,
                  uid: cardUId[chargerViewModel.id!],
                  transactionId: transactionId[chargerViewModel.id!],
                  meterValue: sumKwh[chargerViewModel.id!],
                  beginMeterValue: beginMeterValue[chargerViewModel.id!],
                  startTime: startTime[chargerViewModel.id!],
                  status: "charging",
                  numberOfCharge: numberOfCharge[chargerViewModel.id!],
                  numberOfChargeDays: numberOfChargeDays[chargerViewModel.id!]);

              await sendStatusNotification(
                  chargerViewModel.id!,
                  "StatusNotification",
                  "Charging",
                  "",
                  "",
                  "",
                  randomTime[chargerViewModel.id!],
                  1);
              chargerState[chargerViewModel.id!] = 'charging';
              lastNotificationTime[chargerViewModel.id!] =
                  now.millisecondsSinceEpoch ~/ 1000;
              intervalTime[chargerViewModel.id!] = meterInterval;
            }
          } else {
            logger.i("Step 3 for : ${chargerViewModel.id}\n");
            await sendHeartbeat(chargerViewModel.id!);

            CardViewModel card = CardViewModel.fromJson(cardData!);
            await DatabaseHelper.instance.updateChargerId(card.id!, "");
            await DatabaseHelper.instance
                .updateChargingStatus(chargerViewModel.id!, "start", -1);
          }
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
            logger.i("Step 12 for : ${chargerViewModel.id}\n");

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
            await sendMeterValues(chargerViewModel.id!, {
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
                messageId: messageId[chargerViewModel.id!],
                chargerId: chargerViewModel.id!,
                uid: cardUId[chargerViewModel.id!],
                transactionId: transactionId[chargerViewModel.id!],
                meterValue: sumKwh[chargerViewModel.id!],
                beginMeterValue: beginMeterValue[chargerViewModel.id!],
                startTime: startTime[chargerViewModel.id!],
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
            logger.i("Step 13 for : ${chargerViewModel.id}\n");
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
            await sendStatusNotification(chargerViewModel.id!, "SuspendedEV",
                "", "", "", "", randomTime[chargerViewModel.id!], 1);
            await DatabaseHelper.instance
                .deleteNotificationLog(chargerViewModel.id!);

            logger.i("Step 14 for : ${chargerViewModel.id}\n");
            String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);

            await sendMeterValues(chargerViewModel.id!, {
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

            logger.i("Step 15 for : ${chargerViewModel.id}\n");
            await sendStatusNotification(
                chargerViewModel.id!,
                "StatusNotification",
                "Finishing",
                "",
                "",
                "",
                randomTime[chargerViewModel.id!],
                1);

            logger.i("Step 16 for : ${chargerViewModel.id}\n");
            timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);

            await sendMeterValues(chargerViewModel.id!, {
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

            logger.i("Step 17 for : ${chargerViewModel.id}\n");
            await stopTransaction(
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

            logger.i("Step 2 for : ${chargerViewModel.id}\n");
            await sendStatusNotification(chargerViewModel.id!,
                "StatusNotification", "Available", "", "", "", 0, 0);
            // Delay for 1 second
            await Future.delayed(delayDuration);
            await sendStatusNotification(chargerViewModel.id!,
                "StatusNotification", "Available", "", "", "", 0, 1);
            logger.i("Step 2 end for : ${chargerViewModel.id}\n");
            chargerState[chargerViewModel.id!] = 'heartbeat';
          }

          break;
        default:
          await connectToWebSocket(
                  chargerViewModel.urlToConnect!, chargerViewModel.id!)
              .then((_) {})
              .catchError((error) {});

          await DatabaseHelper.instance
              .updateChargerStatus(chargerViewModel.id!, "2");
          await sendBootNotification(chargerViewModel);
      } // switch end

      int interval = intervalTime[chargerViewModel.id!];

      // If charger is available, do not wait for interval time, set a new interval time and show available immedately
      if (chargerState[chargerViewModel.id!] == 'available') {
        interval = 3;
      }
      await DatabaseHelper.instance.updateTime(chargerViewModel.id!, interval);
    } // No charger found
  }

  Future<void> connectToWebSocket(String url, int chargerId) async {
    if (url.isNotEmpty && url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    try {
      WebSocketChannel channel = await IOWebSocketChannel.connect(
        url,
        protocols: ['ocpp1.6', 'ocpp1.5'],
      );

      final SessionController sessionController = Get.find<SessionController>();

      // Listen to incoming messages
      channel.stream.listen((data) async {
        // Decode the incoming JSON data
        dynamic decodedData = jsonDecode(data);
        logger.i("Received: ${decodedData}\n");
        if (decodedData[0] != 3) {
          await DatabaseHelper.instance.updateChargerStatus(chargerId, "0");
        }

        // Check if the decoded data is a List and has at least 3 elements
        if (decodedData is List && decodedData.length >= 3) {
          // Check if the third element is a Map and contains 'transactionId'
          if (decodedData[2] is Map &&
              decodedData[2].containsKey('transactionId')) {
            // Extract the transactionId
            transactionId[chargerId] = decodedData[2]['transactionId'];
          }

          String status = '';
          logger.t("decoded info ${decodedData[2]}");

          if (decodedData[2] is Map &&
              decodedData[2].containsKey('idTagInfo') &&
              decodedData[2]['idTagInfo'] is Map &&
              decodedData[2]['idTagInfo'].containsKey('status')) {
            // Extract the status from idTagInfo
            status = decodedData[2]['idTagInfo']['status'];
            responseStatus[chargerId] = status;
            logger.t("decoded status ${responseStatus[chargerId]}");
            print(responseStatus[chargerId]);
            if (responseStatus[chargerId] == 'Blocked' ||
                responseStatus[chargerId] == 'Invalid') {
              blocked = true;
              var detectionDelay = Random().nextInt(2);
              await delayInSeconds(detectionDelay+1);

              blockedChargerHandle(chargerId);
              print("true");
              print(responseStatus[chargerId]);
            }else{
              blocked = false;
              print("false");
              print(responseStatus[chargerId]);
            }

          }

          /**checking index 2 and its status for stopChargingImmediately*/
          if ((decodedData[2] as Map).isEmpty) {
            //stopChargingImmediately(chargerId);
          }
        }
      }, onDone: () {
        // logger.e(
        //     '$chargerId WebSocket connection closed unexpectedly ${DateTime.now()}\n');
        _socketConnected = false;
        //_retryConnection(url, chargerId);
      }, onError: (error) {
        // logger.e('$chargerId Error in WebSocket connection: $error\n');
        _socketConnected = false;
        //_retryConnection(url, chargerId);
      });
      _sockets[chargerId] = channel;
      _socketConnected = true;
    } catch (e) {
      logger.i(e);
    }
  }

  /*retrying websocket connection*/
  void _retryConnection(String url, int chargerId) {
    if (!_socketConnected) {
      connectToWebSocket(url, chargerId);
    }
  }

  Future<void> sendMessage(String message, int? chargerId) async {
    if (_sockets[chargerId!] != null) {
      logger.i("Sent: ${message}\n");

      _sockets[chargerId]?.sink.add(message);
    } else {
      await DatabaseHelper.instance.updateChargerStatus(chargerId, "0");
    }
  }

  Future<void> sendBootNotification(ChargersViewModel charger) async {
    acquireCharger(charger.id!, charger.urlToConnect!);
    logger.i("Step 1 for : ${charger.id}\n");
    int? chargerId = charger.id;

    var log = await DatabaseHelper.instance.getNotificationLog("$chargerId");
    String status;

    if (log == null) {
      var bootNotification = jsonEncode([
        2,
        "${messageId[charger.id!]++}",
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

      await sendMessage(bootNotification, charger.id);
      logger.i("Step 1 end for : ${charger.id}\n");

      await DatabaseHelper.instance
          .updateTime(charger.id!, int.parse(charger.intervalTime!));

      // Delay for 1 second
      await Future.delayed(delayDuration);
      await sendStatusNotification(
          charger.id!, "StatusNotification", "Available", "", "", "", 0, 0);
      // Delay for 1 second
      await Future.delayed(delayDuration);

      await sendStatusNotification(
          charger.id!, "StatusNotification", "Available", "", "", "", 0, 1);

      chargerState[charger.id!] = 'heartbeat';
    } else {
      DateTime utcNow = DateTime.now().toUtc();
      String sign = timeZone.substring(3, 4);
      int hours = int.parse(timeZone.substring(4, 6));
      int minutes = int.parse(timeZone.substring(7));
      int totalOffsetMinutes = (hours * 60 + minutes);
      DateTime now = utcNow.add(Duration(
          minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

      messageId[charger.id!] = log['messageId'];
      chargerState[charger.id!] = 'charging';
      sessionEndTime[charger.id!] = (now.millisecondsSinceEpoch ~/ 1000) - 3600;
      sumKwh[charger.id!] = log['meter_value'];
      transactionId[charger.id!] = log['transactionId'];
      beginMeterValue[charger.id!] = log['begin_meter_value'];
      cardUId[charger.id!] = log['uid'];
      numberOfCharge[charger.id!] = log['numberOfCharge'];
      numberOfChargeDays[charger.id!] = log['numberOfChargeDays'];

      stopChargingImmediately(chargerId);
    }
  }

  Future<void> sendHeartbeat(int chargerId) async {
    var heartbeat =
        jsonEncode([2, "${messageId[chargerId]++}", "Heartbeat", {}]);
    await sendMessage(heartbeat, chargerId);
  }

  Future<void> sendStatusNotification(
      int chargerId,
      String status,
      String info,
      String? cardData,
      String? cardUId,
      String? reference,
      int repeatUntil,
      int connectorId) async {
    var statusNotification = info == "Authorize"
        ? jsonEncode([
            2,
            "${messageId[chargerId]++}",
            "Authorize",
            {"idTag": cardUId}
          ])
        : cardData == "Card detected"
            ? jsonEncode([
                2,
                "${messageId[chargerId]++}",
                "StatusNotification",
                {
                  "connectorId": 0,
                  "errorCode": "NoError",
                  "info": "Info: Charge card $cardUId detected",
                  "status": info
                }
              ])
            : status == "SuspendedEV"
                ? jsonEncode([
                    2,
                    "${messageId[chargerId]++}",
                    "StatusNotification",
                    {
                      "connectorId": 1,
                      "errorCode": "NoError",
                      "status": "SuspendedEV"
                    }
                  ])
                : jsonEncode([
                    2,
                    "${messageId[chargerId]++}",
                    "StatusNotification",
                    {
                      "connectorId": connectorId,
                      "errorCode": "NoError",
                      "status": info
                    }
                  ]);

    await sendMessage(statusNotification, chargerId);
  }

  Future<void> startTransaction(
      int chargerId, String cardNumber, double meterValue) async {
    DateTime utcNow = DateTime.now().toUtc();
    String sign = timeZone.substring(3, 4); // Extracting the sign (+ or -)
    int hours = int.parse(timeZone.substring(4, 6)); // Extracting the hours
    int minutes = int.parse(timeZone.substring(7)); // Extracting the minutes
    int totalOffsetMinutes = (hours * 60 + minutes);
    DateTime now = utcNow.add(Duration(
        minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

    String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
    startTime[chargerId] = timestamp;
    var startTransaction = jsonEncode([
      2,
      "${messageId[chargerId]++}",
      "StartTransaction",
      {
        "timestamp": timestamp,
        "connectorId": 1,
        "meterStart": meterValue.round(),
        "idTag": cardNumber
      }
    ]);

    await sendMessage(startTransaction, chargerId);
  }

  Future<void> sendMeterValues(
      int chargerId, Map<String, dynamic> payload) async {
    var startTransaction = jsonEncode([
      2,
      "${messageId[chargerId]++}",
      "MeterValues",
      {
        "connectorId": 1,
        "transactionId": transactionId[chargerId] ?? 1,
        "meterValue": [payload]
      }
    ]);

    await sendMessage(startTransaction, chargerId);
  }

  Future<void> stopTransaction(
      int chargerId, double beginValue, double lastValue, String idTag) async {
    DateTime utcNow = DateTime.now().toUtc();
    String sign = timeZone.substring(3, 4); // Extracting the sign (+ or -)
    int hours = int.parse(timeZone.substring(4, 6)); // Extracting the hours
    int minutes = int.parse(timeZone.substring(7)); // Extracting the minutes
    int totalOffsetMinutes = (hours * 60 + minutes);
    DateTime now = utcNow.add(Duration(
        minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

    String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
    var stopTransaction = jsonEncode([
      2,
      "${messageId[chargerId]++}",
      "StopTransaction",
      {
        "timestamp": "${timestamp}",
        "transactionId": transactionId[chargerId],
        "meterStop": lastValue.round(),
        "idTag": idTag,
        "reason": "EVDisconnected",
        "transactionData": [
          {
            "timestamp": "${startTime[chargerId]}",
            "sampledValue": [
              {
                "value": "${(beginValue / 1000).toStringAsFixed(3)}",
                "context": "Transaction.Begin",
                "unit": "kWh"
              }
            ]
          },
          {
            "timestamp": "${timestamp}",
            "sampledValue": [
              {
                "value": "${(lastValue / 1000).toStringAsFixed(3)}",
                "context": "Transaction.End",
                "unit": "kWh"
              }
            ]
          }
        ]
      }
    ]);
    await sendMessage(stopTransaction, chargerId);
    DatabaseHelper.instance.deleteNotificationLog(chargerId);
  }

  Future<void> blockedChargerHandle(int chargerId) async {
    logger.i(
        "updating response status ${responseStatus[chargerId]}");
    Map<String, dynamic>? cardData = await DatabaseHelper.instance
        .getCardByChargerId(chargerId);
    CardViewModel card = CardViewModel.fromJson(cardData!);
    // TODO: and send mail to admin
    var uid = cardUId[chargerId];
    var chargeBoxNumber = chargeBoxSerialNumber[chargerId];
    var cardNumber = card.cardNumber;
    var msp = card.msp;

    /**updating charger status*/
    await DatabaseHelper.instance
        .updateChargingStatus(chargerId, "Start", -1);
    await DatabaseHelper.instance
        .updateChargerStatus(chargerId, "0");

    SmtpService.sendEmail(
        subject: 'Card Blocked',
        text: "$uid has blocked!",
        headerText: "BoxSerialNumber: $chargeBoxNumber",
        contentText: "MSP: $msp <br> Card Number: $cardNumber");

    nextSession[chargerId] =
        await getRandomSessionRestTime(
        numberOfCharge[chargerId],
        numberOfChargeDays[chargerId],
        randomTime[chargerId]);

    await DatabaseHelper.instance.updateTimeField(
        cardId[chargerId],
        nextSession[chargerId]);
    await DatabaseHelper.instance.updateChargerId(card.id!, '');

    await sendStatusNotification(chargerId,
    "StatusNotification", "Available", "", "", "", 0, 1);

    await sendHeartbeat(chargerId);
    chargerState[chargerId] = 'heartbeat';

    logger.i("blockedChargerHandle() closed ${responseStatus[chargerId]}");
  }
}

class ChargerData {
  int time;
  String url;

  ChargerData({required this.time, required this.url});
}
