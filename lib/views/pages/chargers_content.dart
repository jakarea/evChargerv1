import 'dart:async';

import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/models/chargers_view_model.dart';
import 'package:ev_charger/views/widgets/dialog/choose_card_dialog.dart';
import 'package:ev_charger/views/widgets/dialog/hide_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../services/database_helper.dart';
import '../widgets/custom_search_box.dart';
import '../widgets/dialog/charger_dialog.dart';
import '../widgets/dialog/custom_info_bar.dart';
import '../widgets/navigation_item.dart';
import '../widgets/pagination_controls.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

class ChargersContent extends StatefulWidget {
  const ChargersContent({super.key});

  @override
  State<ChargersContent> createState() => _ChargersContentState();
}

class _ChargersContentState extends State<ChargersContent>
    with WidgetsBindingObserver {
  final SettingsController settingsController = Get.find<SettingsController>();

  final SessionController sessionController = Get.find<SessionController>();

  TextEditingController pageCounterController = TextEditingController();

  List<ChargersViewModel> chargers = [];
  List<ChargersViewModel> selectedCharger = [];
  List<String> waiting = List.filled(900, "");

  String searchText = '';

  bool isFetching =
      false; // To keep track of whether data is currently being fetched
  int itemsPerPage = 10; // The number of items to display per page
  int currentPage = 1; // The current page number
  bool hasMoreData = true;
  int totalPages = 1;
  Timer? _timer;
  // bool boxSerial = true;
  // bool firmwareVersion = true;
  // bool intervalTime = true;
  // bool urlToConnect = true;
  // bool group = true;
  // bool maximumChargingPower = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sessionController.addAllChargers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _adjustItemsPerPage();
        calculateTotalPages();
      }
    });
    _fetchPage(currentPage);
    // _timer = Timer.periodic(
    //     Duration(seconds: 10), (Timer t) => _fetchPage(currentPage));
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

  /// Fetches and displays a specific page of charger data, updating the UI accordingly.
  Future<void> _fetchPage(int pageNumber) async {
    isFetching = true;
    List<Map<String, dynamic>> chargerMaps = await DatabaseHelper.instance
        .getChargerPaginated(pageNumber, itemsPerPage);

    List<ChargersViewModel> pageChargers = chargerMaps
        .map((chargerMap) => ChargersViewModel.fromJson(chargerMap))
        .toList();

    if (mounted) {
      setState(() {
        if (pageNumber == 1) {
          chargers = pageChargers; // Replace chargers if it's the first page
        } else {
          chargers = pageChargers; // Append chargers for subsequent pages
        }
        currentPage = pageNumber;
        pageCounterController.text = currentPage.toString();
        isFetching = false;
      });
    }
  }

  /// Filters the charger list based on the search text.
  ///
  /// It filters chargers by checking if their fields
  /// contains the search text.
  void filterChargers(String text) async {
    searchText = text.toLowerCase();
    currentPage = 1; // Reset to the first page for new search results
    pageCounterController.text = currentPage.toString();
    // Fetch the first page of filtered results from the database
    List<Map<String, dynamic>> filteredChargers = await DatabaseHelper.instance
        .getChargerPaginated(currentPage, itemsPerPage,
            searchQuery: searchText);

    setState(() {
      // Update the chargers list with the new filtered and paginated results
      chargers = filteredChargers
          .map((chargerMap) => ChargersViewModel.fromJson(chargerMap))
          .toList();
      // You might also need to update totalPages based on the new filtered results
    });
  }

  /// the method is for clear the search text
  void onCleared() {
    _fetchPage(currentPage);
  }

  /// Callback function to update the charger list.
  ///
  /// This method is invoked to reload the charger list, for example, after a new charger is added.
  void _onChargerAdded() {
    _fetchPage(currentPage);
    selectedCharger = [];
  }

  /// calculating the total pages
  void calculateTotalPages() async {
    int totalItems = await DatabaseHelper.instance.getTotalChargerCount();
    setState(() {
      totalPages = (totalItems / itemsPerPage).ceil(); // Use itemsPerPage here
    });
  }

  void _updateValues(
      bool newBoxSerial,
      bool newFirmwareVersion,
      bool newIntervalTime,
      bool newUrlToConnect,
      bool newGroup,
      bool newMaximumChargingPower) {
    settingsController.updateSettings(newBoxSerial, newFirmwareVersion,
        newIntervalTime, newUrlToConnect, newGroup, newMaximumChargingPower);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
        title: "Chargers",
        content: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomSearchBox(
                      placeholder: "Search Charger",
                      onChanged: (text) {
                        // Invokes the filterCustomers method with the current input text.
                        // This method filters the customer list based on the input.
                        filterChargers(text);
                      },
                      onCleared: onCleared),
                ),
                SizedBox(
                  width: 12,
                ),
                Button(
                    child: Text("Add Chargers"),
                    onPressed: () {
                      ChargersViewModel chargerViewModel = ChargersViewModel(
                        chargePointVendor: "",
                        chargePointModel: "",
                        chargePointSerialNumber: "",
                        firmwareVersion: "",
                        chargeBoxSerialNumber: "",
                        intervalTime: "",
                        urlToConnect: "",
                        maximumChargingPower: "",
                        meterValue: "",
                        isEdit: false,
                      );
                      ChargerDialog.show(context, _onChargerAdded,
                          chargersViewModel: chargerViewModel);
                    })
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Button(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Filter"),
                      SizedBox(
                        width: 5,
                      ),
                      Icon(FluentIcons.filter)
                    ],
                  ),
                  onPressed: () {
                    HideDialog.show(
                      context,
                      _updateValues,
                      initialBoxSerial: settingsController.boxSerial.value,
                      initialFirmwareVersion:
                          settingsController.firmwareVersion.value,
                      initialIntervalTime:
                          settingsController.intervalTime.value,
                      initialUrlToConnect:
                          settingsController.urlToConnect.value,
                      initialGroup: settingsController.group.value,
                      initialMaximumChargingPower:
                          settingsController.maximumChargingPower.value,
                    );
                  }),
            ),
            ListTile.selectable(
                title: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Vendor",
                            style: TextStyle(fontSize: 14),
                          ),
                        )),
                    Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Model",
                            style: TextStyle(fontSize: 14),
                          ),
                        )),
                    Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Serial Number",
                            style: TextStyle(fontSize: 14),
                          ),
                        )),
                    Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Meter value",
                            style: TextStyle(fontSize: 14),
                          ),
                        )),
                    Obx(() => Visibility(
                          visible: settingsController.boxSerial.value,
                          child: Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Box Serial Number",
                                    style: TextStyle(fontSize: 14)),
                              )),
                        )),
                    Obx(() => Visibility(
                          visible: settingsController.firmwareVersion.value,
                          child: Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Firmware Version",
                                    style: TextStyle(fontSize: 14)),
                              )),
                        )),
                    Obx(() => Visibility(
                          visible: settingsController.intervalTime.value,
                          child: Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Interval Time",
                                    style: TextStyle(fontSize: 14)),
                              )),
                        )),
                    Obx(() => Visibility(
                          visible: settingsController.urlToConnect.value,
                          child: Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("URL to connect to",
                                    style: TextStyle(fontSize: 14)),
                              )),
                        )),
                    Obx(() => Visibility(
                          visible: settingsController.group.value,
                          child: Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Group",
                                    style: TextStyle(fontSize: 14)),
                              )),
                        )),
                    Obx(() => Visibility(
                          visible:
                              settingsController.maximumChargingPower.value,
                          child: Expanded(
                              flex: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("Maximum Charging Power",
                                    style: TextStyle(fontSize: 14)),
                              )),
                        )),
                    Expanded(
                        flex: 5,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Action", style: TextStyle(fontSize: 14)),
                        )),
                  ],
                ),
                selected: selectedCharger.length == chargers.length,
                selectionMode: ListTileSelectionMode.multiple,
                onSelectionChange: (selected) {
                  setState(() {
                    if (selected) {
                      /// first clearing all customer if there are selected any
                      selectedCharger = [];

                      /// now selecting all customers
                      selectedCharger.addAll(chargers);
                    } else {
                      selectedCharger.clear();
                    }
                  });
                }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ListView.builder(
                  itemCount: chargers.length,
                  itemBuilder: (context, index) {
                    final charger = chargers[index];

                    return Obx(() {
                      // Find the corresponding session charger with updated information
                      ChargersViewModel sessionCharger =
                          sessionController.chargers.firstWhere(
                        (sc) => sc.id == charger.id,
                        orElse: () => ChargersViewModel(
                          id: charger.id,
                          status: "0", // Default status if not found
                          chargingStatus: "N/A", // Default charging status
                        ),
                      );

                      // Determine the color based on the status
                      Color backgroundColor = Colors.grey; // Default color
                      switch (sessionCharger.status) {
                        case "0":
                          backgroundColor = Colors.red;
                          break;
                        case "1":
                          backgroundColor = Colors.blue;
                          break;
                        case "2":
                          backgroundColor = Colors.green;
                          break;
                      }

                      return ListTile.selectable(
                          title: Container(
                            color: backgroundColor,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        charger.chargePointVendor!,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    )),
                                Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        charger.chargePointModel!,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    )),
                                Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        charger.chargePointSerialNumber!,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    )),
                                Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "${(double.parse(charger.meterValue!) / 1000).toStringAsFixed(3)} wh",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    )),
                                Visibility(
                                  visible: settingsController.boxSerial.value,
                                  child: Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          charger.chargeBoxSerialNumber!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                                Visibility(
                                  visible:
                                      settingsController.firmwareVersion.value,
                                  child: Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          charger.firmwareVersion!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                                Visibility(
                                  visible:
                                      settingsController.intervalTime.value,
                                  child: Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          charger.intervalTime!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                                Visibility(
                                  visible:
                                      settingsController.urlToConnect.value,
                                  child: Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          charger.urlToConnect!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                                Visibility(
                                  visible: settingsController.group.value,
                                  child: Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          charger.groupName ?? '',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                                Visibility(
                                  visible: settingsController
                                      .maximumChargingPower.value,
                                  child: Expanded(
                                      flex: 5,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          charger.maximumChargingPower!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                                Expanded(
                                    flex: 5,
                                    child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Button(
                                            onPressed: sessionCharger
                                                        .chargingStatus ==
                                                    "start"
                                                ? () async {
                                                    ChooseCardDialog.show(
                                                        context,
                                                        chargerId: charger.id
                                                            .toString(),
                                                        groupId: charger.groupId
                                                            .toString(),
                                                        onBack: () {
                                                      _fetchPage(currentPage);
                                                    });
                                                  }
                                                : null,
                                            child: Text(
                                              sessionCharger.chargingStatus!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ))))
                              ],
                            ),
                          ),
                          selected: selectedCharger.contains(charger),
                          selectionMode: ListTileSelectionMode.multiple,
                          onSelectionChange: (selected) {
                            setState(() {
                              if (selected) {
                                selectedCharger.add(charger);
                              } else {
                                selectedCharger.remove(charger);
                              }
                            });
                          }
                          );
                    });
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
                selectedCharger = [];
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
                selectedCharger = [];
                setState(() {});
              },
              pageCounterController: pageCounterController,
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                    child: Text("Duplicate"),
                    onPressed: selectedCharger.length != 1
                        ? null
                        : () {
                            if (selectedCharger.length == 1) {
                              // ChargersViewModel chargerViewModel =
                              // selectedCharger[0];
                              // int lastIndex = selectedCharger[0]
                              //     .urlToConnect!
                              //     .lastIndexOf('/');
                              //
                              // // Remove the last part of the URL
                              // String newUrl = selectedCharger[0]
                              //     .urlToConnect!
                              //     .substring(0, lastIndex);
                              // if (!newUrl.endsWith("/")) {
                              //   newUrl += '/';
                              // }
                              ChargersViewModel chargerViewModel =
                                  ChargersViewModel(
                                      chargePointVendor:
                                          selectedCharger[0].chargePointVendor,
                                      chargePointModel:
                                          selectedCharger[0].chargePointModel,
                                      chargePointSerialNumber:
                                          selectedCharger[0]
                                              .chargePointSerialNumber,
                                      firmwareVersion:
                                          selectedCharger[0].firmwareVersion,
                                      chargeBoxSerialNumber: selectedCharger[0]
                                          .chargeBoxSerialNumber,
                                      intervalTime:
                                          selectedCharger[0].intervalTime,
                                      urlToConnect:  selectedCharger[0]
                                          .urlToConnect,
                                      maximumChargingPower: selectedCharger[0]
                                          .maximumChargingPower,
                                      meterValue: "0",
                                      groupId: selectedCharger[0].groupId,
                                      isDuplicate: true);

                              ChargerDialog.show(context, _onChargerAdded,
                                  chargersViewModel: chargerViewModel);
                            }
                          }),
                SizedBox(
                  width: 12,
                ),
                Button(
                    child: Text("Edit"),
                    onPressed: selectedCharger.length != 1
                        ? null
                        : () {
                            if (selectedCharger.length == 1) {
                              ChargersViewModel chargerViewModel =
                                  selectedCharger[0];

                              ChargerDialog.show(context, _onChargerAdded,
                                  chargersViewModel: chargerViewModel);
                            }
                          }),
                SizedBox(
                  width: 12,
                ),
                Button(
                    style: ButtonStyle(
                      backgroundColor: ButtonState.all(Colors.red),
                    ),
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async {
                      if (selectedCharger.isNotEmpty) {
                        var groupToDelete =
                            List<ChargersViewModel>.from(selectedCharger);

                        for (var group in groupToDelete) {
                          await DatabaseHelper.instance
                              .deleteCharger(int.parse(group.id.toString()));
                          chargers.remove(group); // Remove from the main list
                          selectedCharger
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
                    }),
              ],
            )
          ],
        ));
  }
}
