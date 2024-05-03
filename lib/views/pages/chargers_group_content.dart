import 'package:ev_charger/models/group_view_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:ev_charger/views/widgets/custom_search_box.dart';
import 'package:ev_charger/views/widgets/dialog/custom_info_bar.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../widgets/navigation_item.dart';
import '../widgets/pagination_controls.dart';

class ChargersGroupContent extends StatefulWidget {
  const ChargersGroupContent({super.key});

  @override
  State<ChargersGroupContent> createState() => _ChargersGroupContentState();
}

class _ChargersGroupContentState extends State<ChargersGroupContent> with WidgetsBindingObserver {

  TextEditingController groupNameController = TextEditingController();
  TextEditingController pageCounterController = TextEditingController();

  List<GroupViewModel> groups = [];
  List<GroupViewModel> selectedGroup = [];

  String searchText = '';

  bool isFetching =
  false; // To keep track of whether data is currently being fetched
  int itemsPerPage = 10; // The number of items to display per page
  int currentPage = 1; // The current page number
  bool hasMoreData = true;
  bool isEdit = false;
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
    groupNameController.dispose();
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

  /// Fetches and displays a specific page of group data, updating the UI accordingly.
  Future<void> _fetchPage(int pageNumber) async {
    isFetching = true;
    List<Map<String, dynamic>> groupMaps = await DatabaseHelper.instance
        .getGroupsPaginated(pageNumber, itemsPerPage);

    List<GroupViewModel> pageGroups = groupMaps
        .map((groupMap) => GroupViewModel.fromJson(groupMap))
        .toList();

    if (mounted) {
      setState(() {
        if (pageNumber == 1) {
          groups = pageGroups; // Replace groups if it's the first page
        } else {
          groups = pageGroups; // Append groups for subsequent pages
        }
        currentPage = pageNumber;
        pageCounterController.text = currentPage.toString();
        isFetching = false;
      });
    }
  }

  /// Filters the group list based on the search text.
  ///
  /// It filters groups by checking if their fields
  /// contains the search text.
  void filterGroups(String text) async {
    searchText = text.toLowerCase();
    currentPage = 1; // Reset to the first page for new search results
    pageCounterController.text = currentPage.toString();
    // Fetch the first page of filtered results from the database
    List<Map<String, dynamic>> filteredGroups = await DatabaseHelper.instance
        .getGroupsPaginated(currentPage, itemsPerPage,
        searchQuery: searchText);

    setState(() {
      // Update the groups list with the new filtered and paginated results
      groups = filteredGroups
          .map((groupMap) => GroupViewModel.fromJson(groupMap))
          .toList();
      // You might also need to update totalPages based on the new filtered results
    });
  }

  /// the method is for clear the search text
  void onCleared() {
    _fetchPage(currentPage);
  }

  /// calculating the total pages
  void calculateTotalPages() async {
    int totalItems = await DatabaseHelper.instance.getTotalGroupCount();
    setState(() {
      totalPages = (totalItems / itemsPerPage).ceil(); // Use itemsPerPage here
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationItem(
        title: "Chargers Group Info",
        content: Row(
          children: [
             Expanded(
              child: Column(
                children: [
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          "Chargers Group",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        ),
                      )
                  ),
                  const SizedBox(height: 12,),
                  CustomSearchBox(
                      placeholder: "Search Group",
                      onChanged: (text) {
                        // Invokes the filterCustomers method with the current input text.
                        // This method filters the customer list based on the input.
                        filterGroups(text);
                      },
                      onCleared: onCleared
                  ),
                  const SizedBox(height: 5,),
                  ListTile.selectable(
                    title: const Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: Text(
                              "SL"
                            )
                        ),
                        Expanded(
                            flex: 4,
                            child: Text(
                                "Group Name"
                            )
                        ),
                        Expanded(
                            flex: 3,
                            child: Text(
                                "Status"
                            )
                        ),
                      ],
                    ),
                      selected: selectedGroup.length == groups.length,
                      selectionMode: ListTileSelectionMode.multiple,
                      onSelectionChange: (selected) {
                        setState(() {
                          if (selected) {
                            /// first clearing all customer if there are selected any
                            selectedGroup = [];

                            /// now selecting all customers
                            selectedGroup.addAll(groups);
                          } else {
                            selectedGroup.clear();
                          }
                        });
                      }
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index){
                          final group = groups[index];
                          return ListTile.selectable(
                            title: Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                        (index + 1).toString()
                                    )
                                ),
                                Expanded(
                                    flex: 4,
                                    child: Text(
                                        group.groupName
                                    )
                                ),
                                Expanded(
                                    flex: 3,
                                    child: Text(
                                        group.status
                                    )
                                ),
                              ],
                            ),
                              selected: selectedGroup.contains(group),
                              selectionMode: ListTileSelectionMode.multiple,
                              onSelectionChange: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedGroup.add(group);
                                  } else {
                                    selectedGroup.remove(group);
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
                      selectedGroup = [];
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
                      selectedGroup = [];
                      setState(() {});
                    },
                    pageCounterController: pageCounterController,
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(child: Text("Edit"),
                          onPressed:  selectedGroup.length != 1
                              ? null
                              :  () async{
                            if (selectedGroup.length == 1) {
                              GroupViewModel groupViewModel =
                              selectedGroup[0];
                                groupNameController.text = groupViewModel.groupName;
                                isEdit = true;
                                setState(() {

                                });
                            }
                      }),
                      SizedBox(width: 12,),
                      Button(
                          style: ButtonStyle(
                            backgroundColor: ButtonState.all(Colors.red),
                          ),
                          child: Text("Delete",
                            style: TextStyle(color: Colors.white),
                          ), onPressed: () async{
                        if (selectedGroup.isNotEmpty) {
                          var groupToDelete =
                          List<GroupViewModel>.from(selectedGroup);

                          for (var group in groupToDelete) {
                            await DatabaseHelper.instance
                                .deleteGroup(int.parse(group.id.toString()));
                            groups.remove(group); // Remove from the main list
                            selectedGroup
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
              ),
            ),
            SizedBox(width: 10,),
            Expanded(child: Column(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "New Group",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                      ),
                    )
                ),
                SizedBox(height: 12,),
                TextFormBox(
                  controller: groupNameController,
                  placeholder: "Your Group Name",
                ),
                // SizedBox(height: 8,),
                // TextFormBox(
                //   controller: groupStatusController,
                //   placeholder: "Your Status Name",
                // ),
                SizedBox(height: 12,),
                Align(
                  alignment: Alignment.centerRight,
                    child: Button(
                        child: Text("Save Group"),
                        onPressed: () async{
                          if(groupNameController.text.isEmpty){
                            CustomInfoBar.show(
                                context,
                                title: "Action not allowed. :/",
                                content: "Group name is required. :/",
                                infoBarSeverity: InfoBarSeverity.warning
                            );
                          }
                          else{

                            if(isEdit){
                              GroupViewModel groupViewModel =
                              selectedGroup[0];
                              groupViewModel.groupName = groupNameController.text;
                              await DatabaseHelper.instance.updateGroup(
                                  groupViewModel.toJson(),
                                  int.parse(groupViewModel.id.toString()));
                              print(groupViewModel.status);
                              calculateTotalPages();
                              setState(() {

                              });
                              isEdit = false;
                            }
                            else{
                              GroupViewModel groupViewModel = GroupViewModel(
                                  groupName: groupNameController.text,
                                  status: "Online"
                              );

                              await DatabaseHelper.instance.insertGroup(groupViewModel.toJson());

                              groupNameController.clear();

                              CustomInfoBar.show(
                                  context,
                                  title: "Successfully Added",
                                  content: "Group added successfully",
                                  infoBarSeverity: InfoBarSeverity.success
                              );
                              _fetchPage(currentPage);
                              selectedGroup =
                              [];
                            }

                          }
                        }
                        )
                )
              ],
            )),
          ],
        )
    );
  }
}
