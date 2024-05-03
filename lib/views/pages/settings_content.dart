import 'package:ev_charger/views/widgets/dialog/email_dialog.dart';
import 'package:ev_charger/views/widgets/dialog/receiver_email_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../models/smtp_view_model.dart';
import '../../services/database_helper.dart';
import '../widgets/custom_search_box.dart';
import '../widgets/navigation_item.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({
    super.key,
  });

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  String? selectedTimeFormat;
  SmtpViewModel? smtpSettings;
  String? receiverEmail;

  @override
  void initState() {
    fetchSmtpSettings();
    fetchReceiverEmail();
    fetchUtcTime();
    super.initState();
  }

  Future<void> fetchSmtpSettings() async {
    try {
      final settings = await DatabaseHelper.instance.getSmtpEmail();
      setState(() {
        smtpSettings = settings;
      });
    } catch (e) {}
  }

  Future<void> fetchReceiverEmail() async {
    try {
      final email = await DatabaseHelper.instance.getReceiverEmail();
      setState(() {
        receiverEmail = email;
      });
    } catch (e) {}
  }

  Future<void> fetchUtcTime() async {
    try {
      final settings = await DatabaseHelper.instance.getUtcTime();
      setState(() {
        selectedTimeFormat = settings;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
        title: "Settings",
        content: Column(
          children: [
            Row(
              children: [
                Text("Time Format:"),
                SizedBox(
                  width: 12,
                ),
                ComboBox<String>(
                  placeholder: const Text("Select Time Zone"),
                  items: [
                    ComboBoxItem(child: Text('Device Time'), value: null),
                    ComboBoxItem(child: Text('Netherlands Time'), value: 'NL'),
                    ComboBoxItem(child: Text('UTC-12:00'), value: 'UTC-12:00'),
                    ComboBoxItem(child: Text('UTC-11:00'), value: 'UTC-11:00'),
                    ComboBoxItem(child: Text('UTC-10:00'), value: 'UTC-10:00'),
                    ComboBoxItem(child: Text('UTC-09:30'), value: 'UTC-09:30'),
                    ComboBoxItem(child: Text('UTC-09:00'), value: 'UTC-09:00'),
                    ComboBoxItem(child: Text('UTC-08:00'), value: 'UTC-08:00'),
                    ComboBoxItem(child: Text('UTC-07:00'), value: 'UTC-07:00'),
                    ComboBoxItem(child: Text('UTC-06:00'), value: 'UTC-06:00'),
                    ComboBoxItem(child: Text('UTC-05:00'), value: 'UTC-05:00'),
                    ComboBoxItem(child: Text('UTC-04:00'), value: 'UTC-04:00'),
                    ComboBoxItem(child: Text('UTC-03:30'), value: 'UTC-03:30'),
                    ComboBoxItem(child: Text('UTC-03:00'), value: 'UTC-03:00'),
                    ComboBoxItem(child: Text('UTC-02:00'), value: 'UTC-02:00'),
                    ComboBoxItem(child: Text('UTC-01:00'), value: 'UTC-01:00'),
                    ComboBoxItem(child: Text('UTC±00:00'), value: 'UTC±00:00'),
                    ComboBoxItem(child: Text('UTC+01:00'), value: 'UTC+01:00'),
                    ComboBoxItem(child: Text('UTC+02:00'), value: 'UTC+02:00'),
                    ComboBoxItem(child: Text('UTC+03:00'), value: 'UTC+03:00'),
                    ComboBoxItem(child: Text('UTC+03:30'), value: 'UTC+03:30'),
                    ComboBoxItem(child: Text('UTC+04:00'), value: 'UTC+04:00'),
                    ComboBoxItem(child: Text('UTC+04:30'), value: 'UTC+04:30'),
                    ComboBoxItem(child: Text('UTC+05:00'), value: 'UTC+05:00'),
                    ComboBoxItem(child: Text('UTC+05:30'), value: 'UTC+05:30'),
                    ComboBoxItem(child: Text('UTC+05:45'), value: 'UTC+05:45'),
                    ComboBoxItem(child: Text('UTC+06:00'), value: 'UTC+06:00'),
                    ComboBoxItem(child: Text('UTC+06:30'), value: 'UTC+06:30'),
                    ComboBoxItem(child: Text('UTC+07:00'), value: 'UTC+07:00'),
                    ComboBoxItem(child: Text('UTC+08:00'), value: 'UTC+08:00'),
                    ComboBoxItem(child: Text('UTC+08:45'), value: 'UTC+08:45'),
                    ComboBoxItem(child: Text('UTC+09:00'), value: 'UTC+09:00'),
                    ComboBoxItem(child: Text('UTC+09:30'), value: 'UTC+09:30'),
                    ComboBoxItem(child: Text('UTC+10:00'), value: 'UTC+10:00'),
                    ComboBoxItem(child: Text('UTC+10:30'), value: 'UTC+10:30'),
                    ComboBoxItem(child: Text('UTC+11:00'), value: 'UTC+11:00'),
                    ComboBoxItem(child: Text('UTC+12:00'), value: 'UTC+12:00'),
                    ComboBoxItem(child: Text('UTC+12:45'), value: 'UTC+12:45'),
                    ComboBoxItem(child: Text('UTC+13:00'), value: 'UTC+13:00'),
                    ComboBoxItem(child: Text('UTC+14:00'), value: 'UTC+14:00'),
                  ],
                  value: selectedTimeFormat,
                  onChanged: (value) async {
                    setState(() {
                      selectedTimeFormat = value;
                    });
                    await DatabaseHelper.instance
                        .insertOrReplaceTimeFormat(value.toString());
                  },
                ),
              ],
            ),
            SizedBox(
              height: 12,
            ),
            Row(
              children: [
                smtpSettings != null
                    ? Text('SMTP email: ${smtpSettings!.email!}')
                    : Text(
                        "SMTP email: Email isn't set yet",
                      ),
                SizedBox(
                  width: 12,
                ),
                Button(
                    child: smtpSettings == null ? Text("Add") : Text("Change"),
                    onPressed: () {
                      EmailDialog.show(context, smtpViewModel: smtpSettings,
                          onBack: () async {
                        await fetchSmtpSettings();
                      });
                    }),
                // SizedBox(width: 12,),
                // Button(child: Text("Edit"), onPressed: (){}),
              ],
            ),
            SizedBox(
              height: 12,
            ),
            Row(
              children: [
                receiverEmail != null
                    ? Text('Admin email: ${receiverEmail!}')
                    : Text(
                        "Receiver email: Email isn't set yet",
                      ),
                SizedBox(
                  width: 12,
                ),
                Button(
                    child: receiverEmail == null ? Text("Add") : Text("Change"),
                    onPressed: () {
                      ReceiverEmail.show(context, email: receiverEmail,
                          onBack: () async {
                        await fetchReceiverEmail();
                      });
                    }),
                // SizedBox(width: 12,),
                // Button(child: Text("Edit"), onPressed: (){}),
              ],
            )
          ],
        ));
  }
}
