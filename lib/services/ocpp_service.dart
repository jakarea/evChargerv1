import 'dart:convert';

import 'package:ev_charger/services/websocket_handler.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class OCPPService{
  final WebSocketHandler webSocketHandler = WebSocketHandler();
  List<int> messageId = List.filled(60, 1);
  List<String> startTime = List.filled(60,
      DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(DateTime.now()).toString());
  var timeZone = 'UTC+02:00';

  Future<void> sendMessage(String message, int? chargerId) async {
    if (webSocketHandler.sockets[chargerId!] != null) {
      webSocketHandler.sockets[chargerId]?.sink.add(message);
    } else {
      await DatabaseHelper.instance.updateChargerStatus(chargerId, "0");
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
    await Future.delayed(Duration(seconds: 2));
  }

  // await Future.delayed(Duration(seconds: 2));
  Future<void> sendMeterValues(
      int chargerId, Map<String, dynamic> payload) async {
    var meterValuesData = jsonEncode([
      2,
      "${messageId[chargerId]++}",
      "MeterValues",
      {
        "connectorId": 1,
        "transactionId": webSocketHandler.getTransactionId[chargerId] ?? 1,
        "meterValue": [payload]
      }
    ]);

    await sendMessage(meterValuesData, chargerId);
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
        "transactionId": webSocketHandler.getTransactionId[chargerId],
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