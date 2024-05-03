import 'package:ev_charger/models/chargers_view_model.dart';
import 'package:ev_charger/services/database_helper.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import 'custom_info_bar.dart';

class ChargerDialog extends StatefulWidget {
  const ChargerDialog(
      {Key? key, required this.onChargerUpdated, this.chargersViewModel})
      : super(key: key);

  final VoidCallback onChargerUpdated;
  final ChargersViewModel? chargersViewModel;

  static void show(BuildContext context, VoidCallback onChargerUpdated,
      {ChargersViewModel? chargersViewModel}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChargerDialog(
          onChargerUpdated: onChargerUpdated,
          chargersViewModel: chargersViewModel,
        );
      },
    );
  }

  @override
  State<ChargerDialog> createState() => _ChargerDialogState();
}

class _ChargerDialogState extends State<ChargerDialog> {
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _boxSerialNumberController =
      TextEditingController();
  final TextEditingController _intervalTimeController = TextEditingController();
  final TextEditingController _firmwareVersionController =
      TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _maxChargingPowerController =
      TextEditingController();
  final TextEditingController _meterValueController = TextEditingController();
  String? _selectedGroup;

  List<ComboBoxItem<String>> _groupItems = [];

  String? buttonName;
  String _previousBoxSerialNumber = '';
  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.chargersViewModel!.isEdit! &&
        !widget.chargersViewModel!.isDuplicate!) {
      buttonName = "Update Charger";
    } else if (widget.chargersViewModel!.isDuplicate!) {
      buttonName = "Duplicate Charger";
    } else {
      buttonName = "Add Charger";
    }
    _fetchGroups();
    _initializeTextControllers();
  }

  String _removeEndpoint(String url) {
    // Check if the URL ends with a '/', if not add one to ensure the last endpoint is removed.
    if (!url.endsWith('/')) {
      url += '/';
    }
    // Find the index of the last '/' - after ensuring there's a trailing '/'
    int lastIndex = url.lastIndexOf('/', url.length - 2);

    // If found, separate the URL up to the last '/' (not including the endpoint)
    return _baseUrl = lastIndex != -1 ? url.substring(0, lastIndex + 1) : url;
  }


  void _initializeTextControllers() {
    if (widget.chargersViewModel != null) {
      _vendorController.text = widget.chargersViewModel!.chargePointVendor!;
      _modelController.text = widget.chargersViewModel!.chargePointModel!;
      _serialNumberController.text =
          widget.chargersViewModel!.chargePointSerialNumber!;
      _boxSerialNumberController.text =
          widget.chargersViewModel!.chargeBoxSerialNumber!;
      _intervalTimeController.text = widget.chargersViewModel!.intervalTime!;
      _firmwareVersionController.text =
          widget.chargersViewModel!.firmwareVersion!;

      if(!widget.chargersViewModel!.isDuplicate! && widget.chargersViewModel!.isEdit!){
        _urlController.text = widget.chargersViewModel!.urlToConnect!;
        _removeEndpoint(widget.chargersViewModel!.urlToConnect!);
        //_baseUrl = "ws://connect.longship.io/93f511b5af8c363135deb16f4feed1e5/";
        _meterValueController.text = widget.chargersViewModel!.meterValue!;
      }


      _maxChargingPowerController.text =
          widget.chargersViewModel!.maximumChargingPower!;

      // Set the selected group if groupName is available
      if (widget.chargersViewModel!.groupName != null) {
        _selectedGroup = widget.chargersViewModel!.groupId.toString();
      }
    } if(widget.chargersViewModel!.isDuplicate!) {
      _boxSerialNumberController.text = "";
      _removeEndpoint(widget.chargersViewModel!.urlToConnect!);
      _urlController.text = _baseUrl;

      //_baseUrl = "ws://connect.longship.io/93f511b5af8c363135deb16f4feed1e5/";
      _previousBoxSerialNumber = '';
      _meterValueController.text = "0";
      _selectedGroup = widget.chargersViewModel!.groupId.toString();
    }

  }

  Future<void> _fetchGroups() async {
    List<Map<String, dynamic>> groupData =
        await DatabaseHelper.instance.getGroups();
    List<ComboBoxItem<String>> groupItems = groupData.map((group) {
      return ComboBoxItem(
        value:
            group['id'].toString(), // Assuming 'id' is the field for group ID
        child: Text(group[
            'group_name']), // Assuming 'group_name' is the field for the group name
      );
    }).toList();

    setState(() {
      _groupItems = groupItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(buttonName ?? ""),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Charge Point Vendor"),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _vendorController,
              placeholder: "Charge Point Vendor",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Charge Point Model",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _modelController,
              placeholder: "Charge Point Model",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Charge Point Serial Number",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _serialNumberController,
              placeholder: "Charge Point Serial Number",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Charge Box Serial Number",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _boxSerialNumberController,
              onChanged: (value){

                if(widget.chargersViewModel!.isDuplicate! || widget.chargersViewModel!.isEdit!){
                  _previousBoxSerialNumber = value.replaceAll(' ', '-');

                  _urlController.text = _baseUrl + _previousBoxSerialNumber;

                  setState(() {});
                }


              },
              placeholder: "Charge Box Serial Number",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Interval Time",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _intervalTimeController,
              keyboardType:
                  TextInputType.number, // Set the keyboard type to numeric
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter
                    .digitsOnly, // Restrict input to digits only
              ],
              placeholder: "Interval Time (in seconds)900",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Firmware Version",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _firmwareVersionController,
              placeholder: "Firmware Version",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "URL to connect to",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _urlController,
              placeholder: "URL to connect to",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Meter Value(w)",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _meterValueController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              placeholder: "Meter value(w)",
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              "Maximum charging power",
            ),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _maxChargingPowerController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              placeholder: "Maximum charging power",
            ),
            const SizedBox(height: 12),
            const Text("Assign Group"),
            const SizedBox(height: 12),
            ComboBox<String>(
              placeholder: const Text("Select Group"),
              items: _groupItems,
              value: _selectedGroup,
              onChanged: (value) => setState(() {
                _selectedGroup = value;
              }),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        FilledButton(
          child: Text(buttonName ?? ""),
          onPressed: () async {
            if (_vendorController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Charge Point Vendor is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_modelController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Charge Point Model is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_serialNumberController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Charge Point Serial Number is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_boxSerialNumberController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Charge Box Serial Number is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_firmwareVersionController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Firmware version is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_intervalTimeController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Interval Time is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            }
            else if (_meterValueController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Meter value is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_maxChargingPowerController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Maximum charging value is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_selectedGroup == null) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Group is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else {

              String urlToConnect = _urlController.text;

              if (!urlToConnect.endsWith('/')) {
                urlToConnect += '/';
              }

              String? chargerId;

              if(widget.chargersViewModel!.isEdit! && !widget.chargersViewModel!.isDuplicate!){
                chargerId = widget.chargersViewModel!.id!.toString();
              } else{
                chargerId = null;
              }

              if(await DatabaseHelper.instance.isCombinationUnique(
                  urlToConnect,
                id: chargerId
              )){
                ChargersViewModel chargersViewModel = ChargersViewModel(
                    chargePointVendor: _vendorController.text,
                    chargePointModel: _modelController.text,
                    chargePointSerialNumber: _serialNumberController.text,
                    firmwareVersion: _firmwareVersionController.text,
                    chargeBoxSerialNumber: _boxSerialNumberController.text,
                    intervalTime: _intervalTimeController.text,
                    lastUpdate: DateTime.now().millisecondsSinceEpoch ~/ 1000 +
                        int.parse(_intervalTimeController
                            .text), // Convert current time to Unix timestamp
                    urlToConnect: urlToConnect,
                    groupId: int.parse(_selectedGroup!),
                    maximumChargingPower: _maxChargingPowerController.text,
                    meterValue: _meterValueController.text);

                if (!widget.chargersViewModel!.isEdit! ||
                    widget.chargersViewModel!.isDuplicate!) {
                  await DatabaseHelper.instance
                      .insertCharger(context, chargersViewModel.toJson());
                } else if (!widget.chargersViewModel!.isDuplicate!) {
                  await DatabaseHelper.instance.updateCharger(
                      chargersViewModel.toJson(),
                      int.parse(widget.chargersViewModel!.id.toString()));
                }
                widget.onChargerUpdated();
                Navigator.pop(context);
              } else{
                CustomInfoBar.show(context,
                    title: "Action not allowed. :/",
                    content: "Charge Box Serial Number with this URL already connected :/",
                    infoBarSeverity: InfoBarSeverity.warning);
              }
            }
          },
        ),
      ],
    );
  }
}
