import 'dart:async';

import 'package:ev_charger/controllers/session_controller.dart';
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

  @override
  void initState() {
    super.initState();
  }

  Future<String> formatDate(String dateTime) async {
    var timeZone = await DatabaseHelper.instance.getUtcTime();

    var time = DateFormat('yyyy-MM-dd – HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(int.parse(dateTime) * 1000));
    print("time $time");
    DateTime utcNow = DateTime.now().toUtc();

    String sign = timeZone.substring(3, 4); // Extracting the sign (+ or -)
    int hours = int.parse(timeZone.substring(4, 6)); // Extracting the hours
    int minutes = int.parse(timeZone.substring(7)); // Extracting the minutes
    int totalOffsetMinutes = (hours * 60 + minutes);
    DateTime now = utcNow.add(Duration(
        minutes: sign == '-' ? -totalOffsetMinutes : totalOffsetMinutes));

    return DateFormat('yyyy-MM-dd HH:mm').format(now);
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
              child: Obx(() {
                return ListView.builder(
                  itemCount: sessionController.sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessionController.sessions[index];
                    return Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.4))),
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
                             future: formatDate(session.transactionSession),
                             builder: (context,snapshot){
                               if (snapshot.connectionState == ConnectionState.waiting) {
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
                              StopDialog.show(context,
                                  chargerId: session.chargerId,
                                cardId: session.cardId
                              );
                            },
                            child: Text(
                              'Stop',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ButtonStyle(
                              backgroundColor: ButtonState.all(Colors.red),
                            ),
                          ))
                        ],
                      ),
                    );
                  },
                );
              }),
            )
          ],
        ));
  }
}

class ChildText extends StatelessWidget {
  final String data;

  const ChildText({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Text(data,textAlign: TextAlign.center);
  }
}
