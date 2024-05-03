import 'package:fluent_ui/fluent_ui.dart';

import '../../theme/app_theme.dart';

/// A custom widget to display a card on the dashboard.
///
/// It shows an icon, a title, and an optional total amount.
/// This widget is designed to be reusable and configurable with different data.
class DashboardCard extends StatefulWidget {
  /// Creates a [DashboardCard] widget.
  ///
  /// Requires an [icon] and a [title]. The [totalAmount] is optional.
  const DashboardCard(
      {super.key,
      required this.icon, // Icon to display on the card.
      required this.title, // Title text of the card.
      this.totalAmount // Optional total amount text.
      });

  final IconData icon;
  final String title;
  final String? totalAmount;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  @override
  Widget build(BuildContext context) {
    Color systemColor = AppTheme.getCurrentThemeColor(context);

    return Container(
      padding: const EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
      width: 258,
      height: 110,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), color: systemColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 50.0,
            height: 50.0,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon, // Your chosen icon
              size: 30.0, // Adjust icon size as needed
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
              ),
              Text(
                widget.totalAmount ?? '',
              ),
            ],
          )
        ],
      ),
    );
  }
}
