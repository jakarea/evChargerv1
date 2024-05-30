import 'package:ev_charger/models/smtp_view_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class SmtpService {
  static void sendEmail(
      {required String subject,
      required String text,
      required String headerText,
      required String contentText}) async {
    SmtpViewModel? smtpViewModel;
    String? adminEmail;
    try {
      smtpViewModel = await DatabaseHelper.instance.getSmtpEmail();
    } catch (e) {}

    try {
      adminEmail = await DatabaseHelper.instance.getReceiverEmail();
    } catch (e) {}

    // String username = 'mostafijur1812@gmail.com'; // Your Gmail address
    // String password = 'oelc miyw izzp cuzy '; // Your App Password or Gmail password
    String username =
        smtpViewModel?.email ?? 'sendinfo98@gmail.com'; // Your Gmail address
    String password = smtpViewModel?.password ??
        'oelcmiywizzpcuzy '; // Your App Password or Gmail password

    // Creating the SMTP server with Gmail settings
    final smtpServer = gmail(username, password);

    // Create the message
    final message = Message()
      ..from = Address(username, 'System Mail')
      ..recipients
          .add(adminEmail ?? 'dorian@gonextlevelagency.nl') // recipient email dorian@gonextlevelagency.nl
      ..subject = subject
      ..text = text
      ..html = "<h1>$headerText</h1>\n<p>$text</p><p>$contentText</p>";

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      //print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
