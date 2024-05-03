import 'package:fluent_ui/fluent_ui.dart';

class NavigationItem extends StatelessWidget {
  const NavigationItem({super.key, required this.title, required this.content});

  final String title;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage.withPadding(
      header: PageHeader(
        title: Text(title),
      ),
      content: content,
    );
  }
}
