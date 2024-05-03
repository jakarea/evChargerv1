import 'package:ev_charger/controllers/session_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:get/get.dart';
import '../../../services/database_helper.dart';
import '../../../services/background_service.dart';

class StopDialog extends StatelessWidget {
  const StopDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  static void show(
    BuildContext context, {
    String? chargerId,
    String? cardId,
  }) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ContentDialog(
            title: Text("Are you sure you want to stop?"),
            content: Column(
              mainAxisSize: MainAxisSize
                  .min, // To handle the column size based on children
              children: [
                Text("This action will stop the process."), // Example content
                // Add more widgets as needed
              ],
            ),
            actions: [
              Button(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              Button(
                child: Text(
                  'Stop',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {

                  BackgroundService()
                      .stopChargingImmediately(int.parse(chargerId!));

                  final SessionController sessionController =
                      Get.find<SessionController>();
                  sessionController.removeSessionByChargerId(chargerId);

                  await DatabaseHelper.instance
                      .updateChargerId(int.parse(cardId!), "");

                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(Colors.red),
                ),
              ),
            ],
          );
        });
  }
}
