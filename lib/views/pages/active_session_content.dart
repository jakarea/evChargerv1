import 'dart:async';

import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/models/active_session_model.dart';
import 'package:ev_charger/views/widgets/dialog/stop_dialog.dart';
import 'package:ev_charger/views/widgets/navigation_item.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../services/database_helper.dart';

class ActiveSessionContent extends StatefulWidget {
  const ActiveSessionContent({super.key});

  @override
  State<ActiveSessionContent> createState() => _ActiveSessionContentState();
}

class _ActiveSessionContentState extends State<ActiveSessionContent> {
  final SessionController sessionController = Get.put(SessionController());

  List<ActiveSessionModel> sessionData = [];

  @override
  void initState() {
    super.initState();
    getAllSessions();
  }

  Future<List<ActiveSessionModel>> getAllSessions() async {
    var sessionMaps = await DatabaseHelper.instance.getSessions();

    if (sessionMaps.isNotEmpty) {
      sessionData.assignAll(sessionMaps
          .map((chargerMap) => ActiveSessionModel.fromJson(chargerMap))
          .toList());
    }

    return sessionData;
  }

  Future<String> formatDate(int unixTime) async {
    var timeZone = await DatabaseHelper.instance.getUtcTime();
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);

    // Get the system's local time zone offset
    DateTime localDateTime = dateTime.toLocal();
    Duration timeZoneOffset = localDateTime.timeZoneOffset;

    // Adjust dateTime by the local time zone offset
    DateTime adjustedDateTime = dateTime.add(timeZoneOffset);

    return DateFormat('yyyy-MM-dd HH:mm').format(adjustedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
        title: "Active Session",
        content: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.4),
                  )),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Box Serial Number",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Card Number",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "MSP",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "UID",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Transaction Session Time",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "kWh",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Session Time",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Action",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ActiveSessionModel>>(
                future:
                    getAllSessions(), // Replace with your future function to fetch session data
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // While data is loading
                    return Text('loading: ${snapshot.error}');
                  } else if (snapshot.hasError) {
                    // If there's an error
                    return Text('Error: ${snapshot.error}');
                  } else {
                    // If data is loaded successfully
                    final sessionData = snapshot.data!;
                    return ListView.builder(
                      itemCount: sessionData.length,
                      itemBuilder: (context, index) {
                        final session = sessionData[index];
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  session.serialBox,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  session.cardNumber,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  session.msp,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  session.uid,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: FutureBuilder<String>(
                                  future:
                                      formatDate(session.transactionSession),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      // While data is loading
                                      return const Text("null");
                                    } else if (snapshot.hasError) {
                                      // If there's an error
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      // If data is loaded successfully
                                      return ChildText(data: snapshot.data!);
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  (double.parse(session.kwh) /
                                          60 *
                                          double.parse(session.sessionTime) /
                                          60)
                                      .toStringAsFixed(3),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${(int.parse(session.sessionTime) / 60).round()} min",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Button(
                                  onPressed: () {
                                    stopDialog(context, session);
                                  },
                                  child: Text(
                                    'Stop',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        ButtonState.all(Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            )
          ],
        ));
  }

  void stopDialog(context, session) {
    StopDialog.show(
      context,
      chargerId: session.chargerId,
      cardId: session.cardId.toString(),
    );
  }
}

class ChildText extends StatelessWidget {
  final String data;

  const ChildText({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Text(data, textAlign: TextAlign.center);
  }
}
