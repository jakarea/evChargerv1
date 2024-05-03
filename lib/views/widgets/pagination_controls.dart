import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final TextEditingController pageCounterController;
  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    required this.pageCounterController,
    required this.onNextPage,
    required this.onPreviousPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IntrinsicWidth(
          child: TextFormBox(
            controller: pageCounterController,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ], // Allow only digits
            onChanged: (value) {
              final pageNumber = int.tryParse(value);
              if (pageNumber != null &&
                  pageNumber >= 1 &&
                  pageNumber <= totalPages) {
                onPageChanged(pageNumber);
              } else {
                pageCounterController.text = currentPage.toString();
                pageCounterController.selection = TextSelection.fromPosition(
                    TextPosition(
                        offset: pageCounterController
                            .text.length)); // Place cursor at the end
              }
            },
          ),
        ),
        const SizedBox(width: 10,),
        Text(
              "of $totalPages pages",
        ),
        const SizedBox(width: 10,),
        Button(
          onPressed: currentPage > 1 ? onPreviousPage : null,
          child: const Icon(FluentIcons.chevron_left),
        ),
        const SizedBox(width: 10,),
        Button(
          onPressed: currentPage < totalPages ? onNextPage : null,
          child: const Icon(FluentIcons.chevron_right),
        ),
      ],
    );
  }
}
