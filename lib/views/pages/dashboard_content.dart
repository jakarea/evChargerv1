import 'package:fluent_ui/fluent_ui.dart';

import '../../services/database_helper.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/navigation_item.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent(
      {super.key,
      required this.chargersGroupOnPressed,
      required this.chargersOnPressed,
      required this.cardsOnPressed,
      required this.stationOnPressed});

  final VoidCallback chargersGroupOnPressed;
  final VoidCallback chargersOnPressed;
  final VoidCallback cardsOnPressed;
  final VoidCallback stationOnPressed;

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int groupCount = 0;
  int chargerCount = 0;
  int cardCount = 0;

  @override
  void initState() {
    super.initState();
    getAllTotalCount();
  }

  Future<void> getAllTotalCount() async {
    groupCount = await DatabaseHelper.instance.getTotalGroupCount();
    chargerCount = await DatabaseHelper.instance.getTotalChargerCount();
    cardCount = await DatabaseHelper.instance.getTotalCardCount();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
        title: "Dashboard",
        content: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            GestureDetector(
              onTap: widget.chargersGroupOnPressed,
              child: DashboardCard(
                icon: FluentIcons.cloud,
                title: "Chargers Group",
                totalAmount: groupCount.toString(),
              ),
            ),
            GestureDetector(
              onTap: widget.chargersOnPressed,
              child: DashboardCard(
                icon: FluentIcons.plug,
                title: "Chargers",
                totalAmount: chargerCount.toString(),
              ),
            ),
            GestureDetector(
              onTap: widget.cardsOnPressed,
              child: DashboardCard(
                icon: FluentIcons.credit_card_bill,
                title: "Cards",
                totalAmount: cardCount.toString(),
              ),
            ),
            GestureDetector(
              onTap: widget.stationOnPressed,
              child: DashboardCard(
                icon: FluentIcons.activate_orders,
                title: "Active Session",
              ),
            )
          ],
        ));
  }
}
