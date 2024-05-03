import 'package:fluent_ui/fluent_ui.dart';


class CustomSearchBox extends StatefulWidget {
  const CustomSearchBox({
    super.key,
    required this.placeholder,
    required this.onChanged,
    required this.onCleared,
  });

  final String placeholder;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  State<CustomSearchBox> createState() => _CustomSearchBoxState();
}

class _CustomSearchBoxState extends State<CustomSearchBox> {


  TextEditingController controller = TextEditingController();



  @override
  Widget build(BuildContext context) {
    return TextFormBox(
      controller: controller,
      placeholder: widget.placeholder,
      onChanged: widget.onChanged,
      prefix: const Padding(
        padding: EdgeInsets.only(left: 10),
        child: Icon(FluentIcons.search),
      ),
      suffixMode: OverlayVisibilityMode.always,
      suffix: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () {
            widget.onCleared();
            controller.clear();
          },
          child: const Icon(FluentIcons.clear, size: 14),
        ),
      ),
    );
  }
}
