import 'dart:convert';
import 'dart:math';
import 'package:ev_charger/utils/internet_connection.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../controllers/sharedPreference_controller.dart';
import '../utils/log.dart';
import 'database_helper.dart';

class WebSocketHandler with ChangeNotifier{
  static final WebSocketHandler _instance = WebSocketHandler._internal();
  factory WebSocketHandler() => _instance;
  WebSocketHandler._internal();

  final Map<int, WebSocketChannel> _sockets = {};
  Map<int, int> transactionId = {};
  Map<int, String> responseStatus = {};
  Set<int> _acceptedChargerList = {};
  Map<int, ChargerData> chargerData = {};
  bool _socketConnected = false;
  bool blocked = false;

  Map<int, WebSocketChannel> get sockets => _sockets;
  Map<int, int> get getTransactionId => transactionId;
  Map<int, String> get getResponseStatus => responseStatus;
  Set<int> get getAcceptedChargerList => _acceptedChargerList;
  bool get isSocketConnected => _socketConnected;
  bool get isBlocked => blocked;

  final SharedPreferenceController sharedPreferenceController = SharedPreferenceController();

  Future<void>loadAcceptedChargers() async{
    _acceptedChargerList = await sharedPreferenceController.loadAcceptedChargerList();
    Log.d("loading accepted List $_acceptedChargerList");
    notifyListeners();
  }

  void addAcceptedCharger(int chargerId) {
    _acceptedChargerList.add(chargerId);
    notifyListeners();
  }

  void updateTransactionId(int chargerId, int newTransactionId) {
    transactionId[chargerId] = newTransactionId;
    notifyListeners();
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

      channel.stream.listen((data) async {
        dynamic decodedData = jsonDecode(data);
        print("$chargerId Received: ${decodedData}\n");
        if (decodedData[0] != 3) {
          await DatabaseHelper.instance.updateChargerStatus(chargerId, "0");
        }

        if (decodedData is List && decodedData.length >= 3) {
          if (decodedData[2] is Map &&
              decodedData[2].containsKey('transactionId')) {
            updateTransactionId(chargerId, decodedData[2]['transactionId']);
          }

          /**checking accepted status*/
          if (decodedData[2] is Map &&
              decodedData[2].containsKey('status') &&
              decodedData[2]['status'] == 'Accepted') {
            addAcceptedCharger(chargerId);
            sharedPreferenceController.addToAcceptedList(chargerId);
          }

          String status = '';

          if (decodedData[2] is Map &&
              decodedData[2].containsKey('idTagInfo') &&
              decodedData[2]['idTagInfo'] is Map &&
              decodedData[2]['idTagInfo'].containsKey('status')) {
            status = decodedData[2]['idTagInfo']['status'];
            responseStatus[chargerId] = status;
            if (responseStatus[chargerId] == 'Blocked' ||
                responseStatus[chargerId] == 'Invalid') {
              blocked = true;
              var detectionDelay = Random().nextInt(2);
              await delayInSeconds(detectionDelay + 1);
              //blockedChargerHandle(chargerId);
            } else {
              blocked = false;
            }
          }

          /**checking index 2 and its status for stopChargingImmediately*/
          if ((decodedData[2] as Map).isEmpty) {
            //stopChargingImmediately(chargerId);
          }
        }
      }, onDone: () {
        _socketConnected = false;
        //_retryConnection(url, chargerId);
      }, onError: (error) {
        _socketConnected = false;
        Log.e("ws error $error");
        //_retryConnection(url, chargerId);
      });
      _sockets[chargerId] = channel;
      notifyListeners();
      _socketConnected = true;
    } catch (e) {
      Log.e("ws tryCatch $e");
    }
  }

  // Function to add a new charger with initial time = 0 and URL
  void acquireCharger(int chargerId, String url) {
    chargerData[chargerId] = ChargerData(time: 0, url: url);
  }

  void updateChargerTime() {
    chargerData.forEach((chargerId, data) async {
      if (data.time == 4) {
        resetChargerTime(chargerId);
        if (await CheckInternetConnection().hasInternetConnection()) {
          connectToWebSocket(data.url, chargerId);
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

  Future<void> delayInSeconds(int seconds) async {
    await Future.delayed(Duration(seconds: seconds));
  }
}

class ChargerData {
  int time;
  String url;

  ChargerData({required this.time, required this.url});
}
