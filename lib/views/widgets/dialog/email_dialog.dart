import 'package:ev_charger/models/smtp_view_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';

import 'custom_info_bar.dart';

class EmailDialog extends StatefulWidget {
  const EmailDialog({super.key, required this.onBack, this.smtpViewModel});

  final Function onBack;
  final SmtpViewModel? smtpViewModel;

  static void show(
      BuildContext context,
  {
    required Function onBack,
    SmtpViewModel? smtpViewModel
  }
     ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EmailDialog(
          onBack: onBack,
          smtpViewModel: smtpViewModel
        );
      },
    );
  }

  @override
  State<EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<EmailDialog> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _isHide = true;

  RegExp emailRegExp = RegExp(r'^[\w.-]+@[a-zA-Z\d-]+\.[a-zA-Z\d-]+(?:\.[a-zA-Z\d-]+)*$');

  @override
  void initState(){
    super.initState();

    if(widget.smtpViewModel != null) {
      emailController.text = widget.smtpViewModel!.email!;
      passwordController.text = widget.smtpViewModel!.password!;

    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text("Add Email"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email'),
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
          SizedBox(
            height: 12,
          ),
          Text('Password'),
          SizedBox(
            height: 5,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormBox(
                  obscureText: _isHide,
                  // inputFormatters: [
                  //   FilteringTextInputFormatter.allow(
                  //       RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$')), // Allows digits and spaces
                  // ],
                  controller: passwordController,
                  placeholder: "Password",
                ),
              ),
              IconButton(
                  icon: Icon(_isHide ? CupertinoIcons.eye_fill : CupertinoIcons.eye_slash_fill),
                  onPressed: (){
                    _isHide = !_isHide;
                    setState(() {

                    });
                  }
              )
            ],
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
          } else if(passwordController.text.isEmpty){
            CustomInfoBar.show(context,
                title: "Action not allowed. :/",
                content: "Password is required. :/",
                infoBarSeverity: InfoBarSeverity.warning);
            return;
          }

          else{
            SmtpViewModel smtpViewModel = SmtpViewModel(
              email: emailController.text,
              password: passwordController.text,
            );

            await DatabaseHelper.instance.insertOrReplaceEmail(smtpViewModel);
            widget.onBack();
            Navigator.pop(context);
          }
        })
      ],
    );
  }
}
