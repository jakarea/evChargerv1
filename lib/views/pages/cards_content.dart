import 'package:ev_charger/models/card_view_model.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../controllers/settings_controller.dart';
import '../../services/database_helper.dart';
import '../widgets/custom_search_box.dart';
import '../widgets/dialog/card_dialog.dart';
import '../widgets/dialog/custom_info_bar.dart';
import '../widgets/dialog/hide_card_dialog.dart';
import '../widgets/navigation_item.dart';
import '../widgets/pagination_controls.dart';
import 'package:get/get.dart';

class CardsContent extends StatefulWidget {
  const CardsContent({super.key});

  @override
  State<CardsContent> createState() => _CardsContentState();
}

class _CardsContentState extends State<CardsContent> with WidgetsBindingObserver {
  final SettingsController settingsController = Get.find<SettingsController>();

  TextEditingController pageCounterController = TextEditingController();

  List<CardViewModel> cards = [];
  List<CardViewModel> selectedCard = [];

  String searchText = '';

  bool isFetching =
  false; // To keep track of whether data is currently being fetched
  int itemsPerPage = 10; // The number of items to display per page
  int currentPage = 1; // The current page number
  bool hasMoreData = true;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _adjustItemsPerPage();
        calculateTotalPages();
      }
    });
    _fetchPage(1);

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pageCounterController.dispose(); // Remove the observer
    super.dispose();
  }

  /// Reacts to screen size changes, updating pagination and total pages accordingly.
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _adjustItemsPerPage();
        calculateTotalPages();
      }
    });
  }


  /// Dynamically adjusts pagination based on screen height and estimated item height.
  void _adjustItemsPerPage() {
    if (!mounted) return;

    final screenHeight = MediaQuery.of(context).size.height;
    const estimatedItemHeight = 65.0; // Adjust based on your list item height
    const navBarHeight =
    45.0; // If you have a navigation bar or other UI elements taking up vertical space

    setState(() {
      itemsPerPage =
          ((screenHeight - navBarHeight) / estimatedItemHeight).floor();
      _fetchPage(
          currentPage); // Re-fetch the current page with the new itemsPerPage
    });
  }

  /// Fetches and displays a specific page of card data, updating the UI accordingly.
  Future<void> _fetchPage(int pageNumber) async {
    isFetching = true;
    List<Map<String, dynamic>> cardMaps = await DatabaseHelper.instance
        .getCardPaginated(pageNumber, itemsPerPage);

    List<CardViewModel> pageCard = cardMaps
        .map((cardMap) => CardViewModel.fromJson(cardMap))
        .toList();

    if (mounted) {
      setState(() {
        if (pageNumber == 1) {
          cards = pageCard; // Replace cards if it's the first page
        } else {
          cards = pageCard; // Append cards for subsequent pages
        }
        currentPage = pageNumber;
        pageCounterController.text = currentPage.toString();
        isFetching = false;
      });
    }
  }

  /// Filters the card list based on the search text.
  ///
  /// It filters cards by checking if their fields
  /// contains the search text.
  void filterCards(String text) async {
    searchText = text.toLowerCase();
    currentPage = 1; // Reset to the first page for new search results
    pageCounterController.text = currentPage.toString();
    // Fetch the first page of filtered results from the database
    List<Map<String, dynamic>> filteredCards = await DatabaseHelper.instance
        .getCardPaginated(currentPage, itemsPerPage,
        searchQuery: searchText);

    setState(() {
      // Update the cards list with the new filtered and paginated results
      cards = filteredCards
          .map((cardMap) => CardViewModel.fromJson(cardMap))
          .toList();
      // You might also need to update totalPages based on the new filtered results
    });
  }

  /// the method is for clear the search text
  void onCleared() {
    _fetchPage(currentPage);
  }

  /// Callback function to update the card list.
  ///
  /// This method is invoked to reload the card list, for example, after a new card is added.
  void _onCardAdded() {
    _fetchPage(currentPage);
    selectedCard =
    [];
  }

  /// calculating the total pages
  void calculateTotalPages() async {
    int totalItems = await DatabaseHelper.instance.getTotalCardCount();
    setState(() {
      totalPages = (totalItems / itemsPerPage).ceil(); // Use itemsPerPage here
    });
  }

  void _updateCardValues(bool newMinKwh, bool newMaxKwh, bool newMaxSessionTime, bool newUsageHour, bool newMinInterval, bool newReference, bool newGroupCard) {
    settingsController.updateCardSettings(
      newMinKwh,
      newMaxKwh,
      newMaxSessionTime,
      newUsageHour,
      newMinInterval,
      newReference,
      newGroupCard,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
      title: "Cards",
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomSearchBox(
                    placeholder: "Search Card",
                    onChanged: (text) {
                      // Invokes the filterCustomers method with the current input text.
                      // This method filters the customer list based on the input.
                      filterCards(text);
                    },
                    onCleared: onCleared
                ),
              ),
              SizedBox(width: 12,),
              Button(
                  child: Text(
                      "Add Card"
                  ),
                  onPressed: () {
                    CardDialog.show(context,
                      _onCardAdded,
                    );
                  }
              )
            ],
          ),
          SizedBox(height: 12,),
          Align(
            alignment: Alignment.centerLeft,
            child: Button(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Filter"),
                    SizedBox(width: 5,),
                    Icon(FluentIcons.filter)
                  ],
                ),
                onPressed: () {
                  CardSettingsDialog.show(
                    context,
                    _updateCardValues,  // Make sure to define this method to handle updates from CardSettingsDialog
                    initialMinKwh: settingsController.minKwh.value,
                    initialMaxKwh: settingsController.maxKwh.value,
                    initialMaxSessionTime: settingsController.maxSessionTime.value,
                    initialUsageHour: settingsController.usageHour.value,
                    initialMinInterval: settingsController.minInterVal.value,
                    initialReference: settingsController.reference.value,
                    initialGroupCard: settingsController.groupCard.value,
                  );
                }

            ),
          ),
          ListTile.selectable(
            title: Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Card No.",
                        style: TextStyle(fontSize: 14),
                      ),
                    )),
                Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("MSP",
                        style: TextStyle(fontSize: 14),),
                    )),
                Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("UID",
                        style: TextStyle(fontSize: 14),),
                    )),
                Obx(() => Visibility(
                  visible: settingsController.minKwh.value,
                  child: Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Min kWh per session", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                )),

                Obx(() => Visibility(
                  visible: settingsController.maxKwh.value,
                  child: Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Max kWh per session", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                )),

                Obx(() => Visibility(
                  visible: settingsController.maxSessionTime.value,
                  child: Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Max session time", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                )),

                Obx(() => Visibility(
                  visible: settingsController.usageHour.value,
                  child: Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Usage Hours", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                )),
                Obx(() => Visibility(
                  visible: settingsController.reference.value,
                  child: Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Reference", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                )),

                Obx(() => Visibility(
                  visible: settingsController.groupCard.value, // Assuming 'groupCard' controls the visibility of the "Group" text
                  child: Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Group", style: TextStyle(fontSize: 14)),
                    ),
                  ),
                )),

              ],
            ),
            selected: selectedCard.length == cards.length,
            selectionMode: ListTileSelectionMode.multiple,
              onSelectionChange: (selected) {
                setState(() {
                  if (selected) {
                    /// first clearing all customer if there are selected any
                    selectedCard = [];

                    /// now selecting all customers
                    selectedCard.addAll(cards);
                  } else {
                    selectedCard.clear();
                  }
                });
              }
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return ListTile.selectable(
                    title: Row(
                      children: [
                        Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.cardNumber,
                                style: TextStyle(fontSize: 12),),
                            )),
                        Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.msp,
                                style: TextStyle(fontSize: 12),),
                            )),
                        Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.uid,
                                style: TextStyle(fontSize: 12),),
                            )),

                        Obx(() => Visibility(
                          visible: settingsController.minKwh.value,
                          child: Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.minKwhPerSession, style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )),
                        Obx(() => Visibility(
                          visible: settingsController.maxKwh.value,
                          child: Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.maxKwhPerSession, style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )),

                        Obx(() => Visibility(
                          visible: settingsController.maxSessionTime.value,
                          child: Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text((double.parse(card.maxSessionTime!) / 60).toStringAsFixed(2), style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )),
                        Obx(() => Visibility(
                          visible: settingsController.usageHour.value,
                          child: Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.usageHours, style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )),
                        Obx(() => Visibility(
                          visible: settingsController.reference.value,
                          child: Expanded(
                            flex: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.reference, style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )),
                        Obx(() => Visibility(
                          visible: settingsController.groupCard.value,
                          child: Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(card.groupName.toString(), style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        )),
                      ],
                    ),
                      selected: selectedCard.contains(card),
                      selectionMode: ListTileSelectionMode.multiple,
                      onSelectionChange: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCard.add(card);
                          } else {
                            selectedCard.remove(card);
                          }
                        });
                      }
                  );
                },
              ),
            ),
          ),
          PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: (int page) {
              _fetchPage(page);
              // This will automatically update the currentPage and fetch the new page data
            },
            onPreviousPage: () {
              _fetchPage(currentPage - 1);
              selectedCard = [];
              setState(() {});
            },
            onNextPage: () {
              // Increment currentPage only if it's less than totalPages
              currentPage++;
              _fetchPage(currentPage); // Fetch the next page
              // Update the TextFormBox to reflect the current page
              pageCounterController.text = currentPage.toString();
              pageCounterController.selection = TextSelection.fromPosition(
                  TextPosition(
                      offset: pageCounterController
                          .text.length)); // Place cursor at the end
              selectedCard = [];
              setState(() {});
            },
            pageCounterController: pageCounterController,
          ),
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(child: Text("Duplicate"),
                  onPressed: selectedCard.length != 1 ? null :
                      (){
                    if (selectedCard.length == 1) {
                      // ChargersViewModel chargerViewModel =
                      // selectedCharger[0];

                      CardViewModel cardVewModel = CardViewModel(
                          cardNumber: selectedCard[0].cardNumber,
                          msp: selectedCard[0].msp,
                          uid: selectedCard[0].uid,
                          minKwhPerSession: selectedCard[0].minKwhPerSession,
                          maxKwhPerSession: selectedCard[0].maxKwhPerSession,
                          minSessionTime: selectedCard[0].minSessionTime,
                          maxSessionTime: selectedCard[0].maxSessionTime,
                          usageHours: selectedCard[0].usageHours,
                          minIntervalBeforeReuse: selectedCard[0].minIntervalBeforeReuse,
                          reference: selectedCard[0].reference,
                          times: selectedCard[0].times,
                          daysFrom: selectedCard[0].daysFrom,
                          daysUntil: selectedCard[0].daysUntil,
                          isDuplicate: true
                      );

                      CardDialog.show(
                          context,
                          _onCardAdded,
                          cardViewModel: cardVewModel
                      );
                    }
                  }
              ),
              SizedBox(width: 12,),
              Button(child: Text("Edit"),
                  onPressed: selectedCard.length != 1 ? null : (){

                if (selectedCard.length == 1) {
                  CardViewModel cardViewModel =
                  selectedCard[0];

                  CardDialog.show(
                      context,
                      _onCardAdded,
                      cardViewModel: cardViewModel
                  );
                }
              }),
              SizedBox(width: 12,),
              Button(
                  style: ButtonStyle(
                    backgroundColor: ButtonState.all(Colors.red),
                  ),
                  child: Text("Delete",
                    style: TextStyle(color: Colors.white),
                  ), onPressed: ()async{
                if (selectedCard.isNotEmpty) {
                  var groupToDelete =
                  List<CardViewModel>.from(selectedCard);

                  for (var group in groupToDelete) {
                    await DatabaseHelper.instance
                        .deleteCards(int.parse(group.id.toString()));
                    cards.remove(group); // Remove from the main list
                    selectedCard
                        .remove(group); // Remove from the selected list
                  }

                  calculateTotalPages();

                  setState(() {
                    // State is updated, triggering a rebuild of the widget
                  });
                } else {
                  CustomInfoBar.show(context,
                      title: "Action not allowed",
                      content: "Please select group to delete",
                      infoBarSeverity: InfoBarSeverity.warning);
                }
              }
              ),
            ],
          )
        ],
      ),
    );
  }
}
