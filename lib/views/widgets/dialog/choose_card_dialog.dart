import 'package:ev_charger/models/card_view_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:ev_charger/views/widgets/dialog/custom_info_bar.dart';
import 'package:fluent_ui/fluent_ui.dart';
import './../../../services/background_service.dart';

class ChooseCardDialog extends StatefulWidget {
  const ChooseCardDialog(
      {super.key,
      required this.chargerId,
      required this.onBack,
      required this.groupId});

  final String chargerId;
  final String groupId;
  final Function onBack;

  static void show(BuildContext context,
      {required String chargerId,
      required String groupId,
      required Function onBack}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChooseCardDialog(
          chargerId: chargerId,
          onBack: onBack,
          groupId: groupId,
        );
      },
    );
  }

  @override
  State<ChooseCardDialog> createState() => _ChooseCardDialogState();
}

class _ChooseCardDialogState extends State<ChooseCardDialog> {
  List<CardViewModel> cards = [];
  CardViewModel? selectedCard;

  @override
  void initState() {
    _getCards();
    super.initState();
  }

  Future<void> _getCards() async {
    // Retrieve the list of cards from the database as a List<Map<String, dynamic>>
    List<Map<String, dynamic>> cardMaps = await DatabaseHelper.instance
        .getCardsByGroup(int.parse(widget.groupId));

    // Clear the existing cards in case this function is called multiple times
    cards.clear();

    // Iterate over the list of maps
    for (Map<String, dynamic> cardMap in cardMaps) {
      // Check if the status field is an empty string
      if (cardMap["charger_id"] == "") {
        // If the status is an empty string, convert the map to a CardViewModel and add to the cards list
        cards.add(CardViewModel.fromJson(cardMap));
      }
    }

    // Optionally, if you're updating the UI based on the cards list (e.g., in a Flutter app),
    // you might want to call setState to refresh the UI with the new data
    setState(() {
      // This will trigger a rebuild of your widget with the updated cards list
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text("Choose card"),
      content: Container(
          height: 300,
          child: ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile.selectable(
                  title: Text(cards[index].uid),
                  selected: selectedCard == card,
                  selectionMode: ListTileSelectionMode.single,
                  onSelectionChange: (selected) {
                    setState(() {
                      if (selected) {
                        selectedCard = card;
                      } else if (selectedCard == card) {
                        // If the currently selected card is tapped again, deselect it
                        selectedCard = null;
                      }
                    });
                  });
            },
          )),
      actions: [
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Button(
          child: const Text('OK'),
          onPressed: () async {
            if (selectedCard != null) {
              await DatabaseHelper.instance
                  .updateChargerId(selectedCard!.id!, widget.chargerId);
              // await DatabaseHelper.instance.updateTimeField(selectedCard!.id!,
              //     (DateTime.now().millisecondsSinceEpoch ~/ 1000).toInt());
              await DatabaseHelper.instance
                  .updateChargingStatus(int.parse(widget.chargerId), "waiting",0);
              BackgroundService().startChargingImmediately(
                  int.parse(widget.chargerId), selectedCard!.id!);
              widget.onBack();
            } else {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Please select a card. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
