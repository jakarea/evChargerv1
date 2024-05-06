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
  List<double> lastMeterValue = List.filled(900, 0);
  List<double> sumKwh = List.filled(900, 0);
  int force = 0;
  String nextTimezone = 'UTC+01:00';
  int nextTimezoneChange = 0;

  Map<String, dynamic>? forceCardData;
  Map<String, dynamic>? forceChargerr;
  List<String> startTime = List.filled(900,
      DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(DateTime.now()).toString());
  static const Duration delayDuration = Duration(seconds: 3);

  factory BackgroundService() {
    return _instance;
  }
  BackgroundService._internal() {
    startPeriodicTask();
    decideNextTimezoneChangerDate();
    _sockets = List.filled(100, null);
    // _channels = List.filled(100, null);
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
    // print(chargerState[chargerId!]);
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

  //   Future<bool> checkInternetConnection() async {
  //   try {
  //     var connectivityResult = await (Connectivity().checkConnectivity());
  //     if (connectivityResult == ConnectivityResult.none) {
  //       return false;
  //     } else {
  //       return true;
  //     }
  //   } catch (_) {
  //     return false;
  //   }
  // }

  Future<bool> checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void startChargingImmediately(int chargerId, int cardId) async {
    force = 1;
    forceChargerr = await DatabaseHelper.instance.getChargerById(chargerId);
    forceCardData = await DatabaseHelper.instance.getCardById(cardId);
    ChargersViewModel charger = ChargersViewModel.fromJson(forceChargerr!);
    chargerState[charger.id!] = 'heartbeat';
    await DatabaseHelper.instance.updateTime(chargerId, 5);
    print("startChargingImmediately 163");
  }

  int getRandomNumber() {
    //return randomNumber = 2 + Random().nextInt(11);
    return 0;
  }

  int getRandomSessionRestTime(int numberOfSeaaion, int days, int lastSession) {
    if (lastSession < 12000) {
      lastSession = 12000;
    }

    int totalTime = 86400 * days;

    int averageUse = totalTime ~/ numberOfSeaaion;

    Random random = Random();
    int halfOfAverageUse = averageUse ~/ 2;
    int thirdOfAverageUse = averageUse ~/ 3;
    int randomNumber =
        random.nextInt(thirdOfAverageUse) + random.nextInt(halfOfAverageUse);
    int nextSession = randomNumber.abs() + lastSession * 3;
    DateTime utcNow = DateTime.now().toUtc();
    String sign = timeZone.substring(3, 4);
    int hours = int.parse(timeZone.substring(4, 6));
    int minutes = int.parse(timeZone.substring(7));
    int totalOffsetMinutes = (hours * 60 + minutes);
    DateTime now = utcNow.add(Duration(
        minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

    return nextSession.toInt() + now.millisecondsSinceEpoch ~/ 1000;
  }

  void startPeriodicTask() async {
    int time = 0;
    timeZone = await DatabaseHelper.instance.getUtcTime();
    bool isConnected = true;
    Timer.periodic(const Duration(seconds: 15), (Timer t) async {
      time++;
      // print(timeZone);
      // print("time: $time");
      // print("timeZone: $timeZone");
      DateTime utcNow = DateTime.now().toUtc();
      int utcNotInSec = utcNow.millisecondsSinceEpoch ~/ 1000;
      if (nextTimezoneChange != 0 && nextTimezoneChange <= utcNotInSec) {
        await DatabaseHelper.instance.insertOrReplaceTimeFormat(timeZone);
        decideNextTimezoneChangerDate();
      }
      // print("utcNow: $utcNow");
      String sign = timeZone.substring(3, 4); // Extracting the sign (+ or -)
      int hours = int.parse(timeZone.substring(4, 6)); // Extracting the hours
      int minutes = int.parse(timeZone.substring(7)); // Extracting the minutes
      int totalOffsetMinutes = (hours * 60 + minutes);
      DateTime now = utcNow.add(Duration(
          minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

      // print("now: $now");
      // String timestamp = DateFormat("HH:mm:ss").format(now);

      // print( "Periodic time called at $timestamp $nextTimezone $timeZone $nextTimezoneChange   ");
      // print("Time: $time , Timezone: $timeZone");
      if (time >= 5) {
        isConnected = await checkInternetConnection();
        time = 0;
        timeZone = await DatabaseHelper.instance.getUtcTime();
        // print("Time: $time , Timezone: $timeZone");
      }

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
      // print(charger.urlToConnect);
      // print('WebSocket connection hello established: 168');
      // print(charger.id);
    }).catchError((error) {
      // print('Error establishing WebSocket connection 282: $error');
    });
    //  print('Step 1 BootNotification for newly added charger');
    // BootNotification for newly added charger
    await sendBootNotification(charger);
    chargerState[charger.id!] = 'heartbeat';
  }

  Future<void> checkAndUpdateDatabase() async {
    Map<String, dynamic>? chargerr =
        await DatabaseHelper.instance.queryDueChargers();
    // await DatabaseHelper.instance.updateTimeField(
    //     1, (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 300);

    // await DatabaseHelper.instance.updateTimeField(
    //     2, (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 500);

    // bool isConnected = await checkInternetConnection();

    // print("isConnected test");
    final SessionController sessionController = Get.find<SessionController>();

    if (force == 1) {
      // print("force = 1,  297");
      chargerr = forceChargerr;
    }
    if (chargerr != null) {
      // print("chargerr not null,  301");
      ChargersViewModel charger = ChargersViewModel.fromJson(chargerr);
      String currentState = chargerState[charger.id!];
      intervalTime[charger.id!] = int.parse(charger.intervalTime!);
      CardViewModel? card;

      switch (currentState) {
        case 'heartbeat':
          // await connectToWebSocket(charger.urlToConnect!, charger.id!)
          //     .then((_) {
          //   // print('WebSocket connection established in heartbeat: xx');
          //   // print(charger.id);
          // }).catchError((error) {
          //   // print('Error establishing WebSocket connection: $error');
          // });
          //  print('Step 3 ');
          // print(charger.id);
          // print("force heartbeat ,  318");
          await DatabaseHelper.instance
              .updateChargingStatus(charger.id!, "start");

          Map<String, dynamic>? cardData = await DatabaseHelper.instance
              .getCardByGroupAndTime(charger.groupId!);

          if (force == 1) {
            cardData = forceCardData;
            // print("force cardData ,  328");
          }

          if (cardData != null) {
            // print("cardData not null,  331");
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
                .updateChargerId(card.id!, charger.id.toString());

            double minKwh = double.parse(card.minKwhPerSession);
            double maxKwh = double.parse(card.maxKwhPerSession);
            randomKw[charger.id!] =
                minKwh + Random().nextDouble() * (maxKwh - minKwh);

            int minSessionTime = int.parse(card.minSessionTime!);
            int maxSessionTime = int.parse(card.maxSessionTime!);

            randomTime[charger.id!] = minSessionTime +
                Random().nextInt(maxSessionTime - minSessionTime + 1);

            sessionEndTime[charger.id!] =
                randomTime[charger.id!] + now.millisecondsSinceEpoch ~/ 1000;
            wPerSec[charger.id!] = randomKw[charger.id!] / 3.6;

            beginMeterValue[charger.id!] = double.parse(charger.meterValue!);

            sumKwh[charger.id!] = beginMeterValue[charger.id!];
            cardUId[charger.id!] = card.uid;
            chargeBoxSerialNumber[charger.id!] = charger.chargeBoxSerialNumber!;
            cardId[charger.id!] = card.id!;
            minIntervalBeforeReuse[charger.id!] = card.minIntervalBeforeReuse!;
            numberOfCharge[charger.id!] = int.parse(card.times);
            numberOfChargeDays[charger.id!] = int.parse(card.daysUntil);
            force = 0;
            //
            //
            //    print('Step 4 force heartbear');
            // await sendHeartbeat(charger.id!, intervalTime[charger.id!]);
            // print(meterInterval);
            Random random = Random();
            int min = 10;
            // Generate a random number within the range
            int preparingInterval =
                min + random.nextInt(meterInterval - min + 1);
            // print("preparingInterval: $preparingInterval");
            await Future.delayed(Duration(seconds: preparingInterval));

            await sendStatusNotification(charger.id!, "StatusNotification",
                "Preparing", "", "", "", randomTime[charger.id!], 1);

            // Delay for 1 second
            // await Future.delayed(delayDuration);

            //  print('Step 5');
            await sendStatusNotification(
                charger.id!,
                "StatusNotification",
                "Available",
                "Card detected",
                card.uid,
                "",
                randomTime[charger.id!],
                1);
            // await Future.delayed(delayDuration);
            //  print('Step 6');
            await sendStatusNotification(charger.id!, "AuthorizeNotification",
                "Authorize", "", card.uid, "", randomTime[charger.id!], 1);
            //You can now use 'card' safely within this block.
            await Future.delayed(delayDuration);

            // ignore: unrelated_type_equality_checks
            if (responseStatus[charger.id!] == 'Blocked' ||
                responseStatus[charger.id!] == 'Invalid') {
              // print("card blocked,  410");
              // TODO: and send mail to admin
              var uid = cardUId[charger.id!];
              var chargeBoxNumber = chargeBoxSerialNumber[charger.id!];
              var cardNumber = card.cardNumber;
              var msp = card.msp;

              //  print('Blocked');

              SmtpService.sendEmail(
                  subject: 'Card Blocked',
                  text: "$uid has blocked!",
                  headerText: "BoxSerialNumber: $chargeBoxNumber",
                  contentText: "MSP: $msp <br> Card Number: $cardNumber");

              //await DatabaseHelper.instance
              // .updateTimeField(cardId[charger.id!], nextSession[charger.id!]);

              nextSession[charger.id!] = await getRandomSessionRestTime(
                  numberOfCharge[charger.id!],
                  numberOfChargeDays[charger.id!],
                  randomTime[charger.id!]);

              //print('nextSession');
              // print(nextSession[charger.id!]);

              await DatabaseHelper.instance.updateTimeField(
                  cardId[charger.id!], nextSession[charger.id!]);
              await DatabaseHelper.instance.updateChargerId(card.id!, '');

              await sendStatusNotification(charger.id!, "StatusNotification",
                  "Available", "", "", "", 0, 1);
              // print('regular heartbeat');
              await sendHeartbeat(charger.id!, intervalTime[charger.id!]);
              chargerState[charger.id!] = 'heartbeat';
            } else {
              //  print('Step 7');
              print("start chargong,  447");
              nextSession[charger.id!] = getRandomSessionRestTime(
                  numberOfCharge[charger.id!],
                  numberOfChargeDays[charger.id!],
                  randomTime[charger.id!]);
              await DatabaseHelper.instance.updateTimeField(
                  cardId[charger.id!], nextSession[charger.id!]);
              await sendStatusNotification(charger.id!, "SuspendedEV", "", "",
                  "", "", randomTime[charger.id!], 1);
              // await Future.delayed(delayDuration);
              //  print('Step 8');
              await DatabaseHelper.instance
                  .updateChargingStatus(charger.id!, "Charging");
              await DatabaseHelper.instance
                  .updateChargerStatus(charger.id!, "1");

              final SessionController sessionController =
                  Get.find<SessionController>();

              await startTransaction(
                  charger.id!, card.uid, beginMeterValue[charger.id!]);
              await Future.delayed(delayDuration);

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
                  chargerId: charger.id!,
                  cardId: card.id!,
                  transactionStartTime: now.millisecondsSinceEpoch ~/ 1000,
                  kwh: randomKw[charger.id!].toString(),
                  sessionTime: randomTime[charger.id!].toString());

              sessionController.addSession(ActiveSessionModel(
                  cardId: card.id.toString(),
                  chargerId: charger.id.toString(),
                  chargerName: charger.chargePointVendor!,
                  chargerModel: charger.chargePointModel!,
                  serialBox: charger.chargeBoxSerialNumber!,
                  cardNumber: card.cardNumber,
                  msp: card.msp,
                  uid: card.uid,
                  transactionSession:
                      (now.millisecondsSinceEpoch ~/ 1000).toString(),
                  kwh: randomKw[charger.id!].toString(),
                  sessionTime: randomTime[charger.id!].toString()));

              //  print('Step 9');

              await sendMeterValues(charger.id!, {
                "timestamp": "${timestamp}",
                "sampledValue": [
                  {
                    "value":
                        "${(sumKwh[charger.id!] / 1000).toStringAsFixed(3)}",
                    "context": "Transaction.Begin",
                    "unit": "kWh"
                  }
                ]
              });

              await Future.delayed(delayDuration);
              //  print('Step 10');

              utcNow = DateTime.now().toUtc();
              sign = timeZone.substring(3, 4);
              hours = int.parse(timeZone.substring(4, 6));
              minutes = int.parse(timeZone.substring(7));
              totalOffsetMinutes = (hours * 60 + minutes);
              now = utcNow.add(Duration(
                  minutes:
                      sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

              timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
              await sendMeterValues(charger.id!, {
                "timestamp": "${timestamp}",
                "sampledValue": [
                  {
                    "value":
                        "${(sumKwh[charger.id!] / 1000).toStringAsFixed(3)}",
                    "context": "Sample.Periodic",
                    "measurand": "Energy.Active.Import.Register",
                    "location": "Outlet",
                    "unit": "kWh"
                  }
                ]
              });

              DatabaseHelper.instance.logNotification(
                  messageId: messageId[charger.id!],
                  chargerId: charger.id!,
                  uid: cardUId[charger.id!],
                  transactionId: transactionId[charger.id!],
                  meterValue: sumKwh[charger.id!],
                  beginMeterValue: beginMeterValue[charger.id!],
                  startTime: startTime[charger.id!],
                  status: "charging",
                  numberOfCharge: numberOfCharge[charger.id!],
                  numberOfChargeDays: numberOfChargeDays[charger.id!]);
              //  print('Step 11');
              await sendStatusNotification(charger.id!, "StatusNotification",
                  "Charging", "", "", "", randomTime[charger.id!], 1);
              chargerState[charger.id!] = 'charging';
              lastNotificationTime[charger.id!] =
                  now.millisecondsSinceEpoch ~/ 1000;
              intervalTime[charger.id!] = meterInterval;
            }
          } else {
            //// print('..............No card found heartbeat ...........');
            //  print('Step 4');
            await sendHeartbeat(charger.id!, 300);
          }
          break;

        case 'charging':
          // await connectToWebSocket(charger.urlToConnect!, charger.id!)
          //     .then((_) {
          //   //  print('WebSocket connection established in heartbeat: 447');
          //   // print(charger.id);
          // }).catchError((error) {
          //   // print('Error establishing WebSocket connection: $error');
          // });
          intervalTime[charger.id!] = meterInterval;
          DateTime utcNow = DateTime.now().toUtc();
          String sign = timeZone.substring(3, 4);
          int hours = int.parse(timeZone.substring(4, 6));
          int minutes = int.parse(timeZone.substring(7));
          int totalOffsetMinutes = (hours * 60 + minutes);
          DateTime now = utcNow.add(Duration(
              minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

          if (sessionEndTime[charger.id!] >=
              (now.millisecondsSinceEpoch ~/ 1000)) {
            print('Step 12 charging');
            DateTime utcNow = DateTime.now().toUtc();
            String sign = timeZone.substring(3, 4);
            int hours = int.parse(timeZone.substring(4, 6));
            int minutes = int.parse(timeZone.substring(7));
            int totalOffsetMinutes = (hours * 60 + minutes);
            DateTime now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            nowTime = now.millisecondsSinceEpoch ~/ 1000;
            lastNotificationTimeDiff[charger.id!] =
                nowTime - lastNotificationTime[charger.id!];
            if (lastNotificationTimeDiff[charger.id!] >= meterInterval * 2) {
              // await connectToWebSocket(charger.urlToConnect!, charger.id!)
              //     .then((_) {
              //   // print('WebSocket connection established: 443 step 12');
              //   // print(charger.id);

              // }).catchError((error) {
              //   // print('Error establishing WebSocket connection: $error');
              // });
              stopChargingImmediately(charger.id!);
            }
            sumKwh[charger.id!] = sumKwh[charger.id!] +
                (lastNotificationTimeDiff[charger.id!] * wPerSec[charger.id!]);

            utcNow = DateTime.now().toUtc();
            sign = timeZone.substring(3, 4);
            hours = int.parse(timeZone.substring(4, 6));
            minutes = int.parse(timeZone.substring(7));
            totalOffsetMinutes = (hours * 60 + minutes);
            now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
            await sendMeterValues(charger.id!, {
              "timestamp": "${timestamp}",
              "sampledValue": [
                {
                  "value": "${(sumKwh[charger.id!] / 1000).toStringAsFixed(3)}",
                  "context": "Sample.Periodic",
                  "measurand": "Energy.Active.Import.Register",
                  "location": "Outlet",
                  "unit": "kWh"
                }
              ]
            });
            lastNotificationTime[charger.id!] =
                now.millisecondsSinceEpoch ~/ 1000;
            await DatabaseHelper.instance
                .updateBeginMeterValue(charger.id!, sumKwh[charger.id!]);

            DatabaseHelper.instance.logNotification(
                messageId: messageId[charger.id!],
                chargerId: charger.id!,
                uid: cardUId[charger.id!],
                transactionId: transactionId[charger.id!],
                meterValue: sumKwh[charger.id!],
                beginMeterValue: beginMeterValue[charger.id!],
                startTime: startTime[charger.id!],
                status: "charging",
                numberOfCharge: numberOfCharge[charger.id!],
                numberOfChargeDays: numberOfChargeDays[charger.id!]);
            // check if it is near about to end session time then set a random interval to make make it natual, when suspenend it
            int interval = intervalTime[charger.id!];
            //  print('Step 12');
            // print(sessionEndTime[charger.id!] <=
            //     (now.millisecondsSinceEpoch ~/ 1000) + interval);
            if (sessionEndTime[charger.id!] <=
                (now.millisecondsSinceEpoch ~/ 1000) + interval) {
              Random random = Random();
              int min = interval ~/ 5;
              int max = interval - min;
              intervalTime[charger.id!] = min + random.nextInt(max - min + 1);
            }
          } else {
            //  print('Step 13');
            // print("currentState: $currentState");
            DateTime utcNow = DateTime.now().toUtc();
            String sign = timeZone.substring(3, 4);
            int hours = int.parse(timeZone.substring(4, 6));
            int minutes = int.parse(timeZone.substring(7));
            int totalOffsetMinutes = (hours * 60 + minutes);
            DateTime now = utcNow.add(Duration(
                minutes:
                    sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

            nowTime = now.millisecondsSinceEpoch ~/ 1000;
            lastNotificationTimeDiff[charger.id!] =
                nowTime - lastNotificationTime[charger.id!];

            sumKwh[charger.id!] = sumKwh[charger.id!] +
                (lastNotificationTimeDiff[charger.id!] * wPerSec[charger.id!]);
            await sendStatusNotification(charger.id!, "SuspendedEV", "", "", "",
                "", randomTime[charger.id!], 1);
            await DatabaseHelper.instance.deleteNotificationLog(charger.id!);

            //  print('Step 14');
            // print("currentState: $currentState");
            nowTime = now.millisecondsSinceEpoch ~/ 1000;

            String timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);

            await sendMeterValues(charger.id!, {
              "timestamp": "${timestamp}",
              "sampledValue": [
                {
                  "value": "${(sumKwh[charger.id!] / 1000).toStringAsFixed(3)}",
                  "context": "Sample.Periodic",
                  "measurand": "Energy.Active.Import.Register",
                  "location": "Outlet",
                  "unit": "kWh"
                }
              ]
            });

            //  print('Step 15');
            // print("currentState: $currentState");
            await sendStatusNotification(charger.id!, "StatusNotification",
                "Finishing", "", "", "", randomTime[charger.id!], 1);

            timestamp = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(now);
            //  print('Step 16');
            // print("currentState: $currentState");
            await sendMeterValues(charger.id!, {
              "timestamp": "${timestamp}",
              "sampledValue": [
                {
                  "value": "${(sumKwh[charger.id!] / 1000).toStringAsFixed(3)}",
                  "context": "Transaction.End",
                  "measurand": "Energy.Active.Import.Register",
                  "location": "Outlet",
                  "unit": "kWh"
                }
              ]
            });
// TODO:

            //  print('Step 17');
            // print("currentState: $currentState");
            await DatabaseHelper.instance
                .updateChargingStatus(charger.id!, "N/A");
            await DatabaseHelper.instance.updateChargerStatus(charger.id!, "2");

            await stopTransaction(charger.id!, beginMeterValue[charger.id!],
                sumKwh[charger.id!], cardUId[charger.id!]);
            await DatabaseHelper.instance
                .deleteActiveSessionByChargerId(charger.id!);

            await DatabaseHelper.instance
                .updateBeginMeterValue(charger.id!, sumKwh[charger.id!]);
            sessionController.removeSessionByChargerId(charger.id.toString());
            await DatabaseHelper.instance
                .updateChargerId(cardId[charger.id!], "");
            await DatabaseHelper.instance.removeChargerId(charger.id!, "");

            //chargerState[charger.id!] = 'available';

            await sendStatusNotification(charger.id!, "StatusNotification",
                "Available", "", "", "", 0, 0);
            // Delay for 1 second
            await Future.delayed(delayDuration);
            //  print('Step 2');
            await sendStatusNotification(charger.id!, "StatusNotification",
                "Available", "", "", "", 0, 1);

            chargerState[charger.id!] = 'heartbeat';
          }

          break;
        default:
          //  print('STEP 1');
          await connectToWebSocket(charger.urlToConnect!, charger.id!)
              .then((_) {
            //  print('Default WebSocket connection established: 592');
            // print(charger.urlToConnect);
          }).catchError((error) {
            // print('Error establishing WebSocket connection: $error');
          });

          await DatabaseHelper.instance.updateChargerStatus(charger.id!, "2");
          await sendBootNotification(charger);
        // chargerState[charger.id!] = 'available';
      } // switch end

      int interval = intervalTime[charger.id!];

      // If charger is available, do not wait for interval time, set a new interval time and show available immedately
      if (chargerState[charger.id!] == 'available') {
        interval = 3;
      }
      // print("interval: $interval");
      await DatabaseHelper.instance.updateTime(charger.id!, interval);
    } // No charger found
    // // print('No charger found!');
  }

  Future<void> connectToWebSocket(String url, int chargerId) async {
    if (url.isNotEmpty && url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    try {
      // print("URL: $url");
      WebSocketChannel channel = await IOWebSocketChannel.connect(
        url,
        protocols: ['ocpp1.6', 'ocpp1.5'],
      );

      final SessionController sessionController = Get.find<SessionController>();

      // Listen to incoming messages
      channel.stream.listen((data) async {
        // Decode the incoming JSON data
        dynamic decodedData = jsonDecode(data);
        print("Received:");
        print(decodedData);
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

          if (decodedData[2] is Map &&
              decodedData[2].containsKey('idTagInfo') &&
              decodedData[2]['idTagInfo'] is Map &&
              decodedData[2]['idTagInfo'].containsKey('status')) {
            // Extract the status from idTagInfo
            status = decodedData[2]['idTagInfo']['status'];
            responseStatus[chargerId] = status;
          }
        }
      });
      _sockets[chargerId] = channel;
      // Optionally, send an initial message or perform an action upon successful connection
      // For example, sending a BootNotification for each charger
    } catch (e) {
      // print('WebSocket connection error 846');
      // print(e);
      // Handle connection errors
    }
  }

  Future<void> sendMessage(String message, int? chargerId) async {
    if (_sockets[chargerId!] != null) {
      print(message);

      _sockets[chargerId]?.sink.add(message);
    } else {
      await DatabaseHelper.instance.updateChargerStatus(chargerId, "0");
      //  print('WebSocket is not connected 857. $chargerId');
    }
  }

  Future<void> sendBootNotification(ChargersViewModel charger) async {
    // print(charger);
    int? chargerId = charger.id;

    var log = await DatabaseHelper.instance.getNotificationLog("$chargerId");
    String status;
    // print(log);
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
      await DatabaseHelper.instance.updateChargingStatus(charger.id!, "N/A");
      await DatabaseHelper.instance.removeChargerId(charger.id!, "");

      await sendMessage(bootNotification, charger.id);

      await DatabaseHelper.instance
          .updateTime(charger.id!, int.parse(charger.intervalTime!));

      //  print('Step 2');
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

  Future<void> sendHeartbeat(int chargerId, int repeat) async {
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
                  // "connectorId": chargerId,
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
                      // "connectorId": chargerId,
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
                      // "connectorId": chargerId,
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
        // "connectorId": chargerId,
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
        // "connectorId": chargerId,
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
}
