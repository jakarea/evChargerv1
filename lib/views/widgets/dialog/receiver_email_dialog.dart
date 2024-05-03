import 'package:ev_charger/models/smtp_view_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'custom_info_bar.dart';

class ReceiverEmail extends StatefulWidget {
  const ReceiverEmail({super.key, required this.onBack, this.email});

  final Function onBack;
  final String? email;

  static void show(
      BuildContext context,
      {
        required Function onBack,
        String? email,
      }
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReceiverEmail(
          onBack: onBack,
          email: email,
        );
      },
    );
  }

  @override
  State<ReceiverEmail> createState() => _ReceiverEmailState();
}

class _ReceiverEmailState extends State<ReceiverEmail> {

  TextEditingController emailController = TextEditingController();

  RegExp emailRegExp = RegExp(r'^[\w.-]+@[a-zA-Z\d-]+\.[a-zA-Z\d-]+(?:\.[a-zA-Z\d-]+)*$');

  @override
  void initState(){
    super.initState;

    if(widget.email != null) {
      emailController.text = widget.email!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text("Add Admin Email"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Email'),
          SizedBox(
            height: 5,
          ),
          TextFormBox(
            // inputFormatters: [
            //   FilteringTextInputFormatter.allow(
            //       RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$')), // Allows digits and spaces
            // ],
            controller: emailController,
            placeholder: "Email address",
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        FilledButton(child: const Text('Add Email'), onPressed: () async{
          if(emailController.text.isEmpty){
            CustomInfoBar.show(context,
                title: "Action not allowed. :/",
                content: "Email is required. :/",
                infoBarSeverity: InfoBarSeverity.warning);
            return;
          } else if(!emailRegExp.hasMatch(emailController.text)){
            CustomInfoBar.show(context,
                title: "Action not allowed. :/",
                content: "Please enter a valid email address. :/",
                infoBarSeverity: InfoBarSeverity.warning);
            return;
          }   else{
            SmtpViewModel smtpViewModel = SmtpViewModel(
              email: emailController.text,
            );

            await DatabaseHelper.instance.insertOrReplaceReceiverEmail(smtpViewModel);
            widget.onBack();
            Navigator.pop(context);
          }
        })
      ],
    );
  }
}
