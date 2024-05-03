import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/views/widgets/dialog/stop_dialog.dart';
import 'package:ev_charger/views/widgets/navigation_item.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ActiveSessionContent extends StatefulWidget {
  const ActiveSessionContent({super.key});

  @override
  State<ActiveSessionContent> createState() => _ActiveSessionContentState();
}

class _ActiveSessionContentState extends State<ActiveSessionContent> {
  final SessionController sessionController = Get.put(SessionController());

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
                            child: Text(
                              DateFormat('yyyy-MM-dd – HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(session.transactionSession) *
                                          1000)),
                              textAlign: TextAlign.center,
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
