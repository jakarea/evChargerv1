import 'package:fluent_ui/fluent_ui.dart';

class CustomInfoBar {
  static Future<void> show(BuildContext context,
      {required String title,
      required String content,
      required infoBarSeverity}) async {
    await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(title),
        content: Text(content),
        action:
            IconButton(icon: const Icon(FluentIcons.clear), onPressed: close),
        severity: infoBarSeverity,
      );
    });
  }
}
