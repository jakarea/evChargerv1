import 'dart:math';

import 'package:ev_charger/models/card_view_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../services/database_helper.dart';
import 'custom_info_bar.dart';

class CardDialog extends StatefulWidget {
  const CardDialog({Key? key, required this.onCardUpdated, this.cardViewModel})
      : super(key: key);

  final VoidCallback onCardUpdated;
  final CardViewModel? cardViewModel;

  static void show(
    BuildContext context,
    VoidCallback onCardUpdated, {
    CardViewModel? cardViewModel,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CardDialog(
            onCardUpdated: onCardUpdated, cardViewModel: cardViewModel);
      },
    );
  }

  @override
  State<CardDialog> createState() => _CardDialogState();
}

class _CardDialogState extends State<CardDialog> {
  // Define a TextEditingController for each TextFormBox
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _mspController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _minKWhPerSessionController =
      TextEditingController();
  final TextEditingController _maxKWhPerSessionController =
      TextEditingController();
  final TextEditingController _minSessionTimeController =
      TextEditingController();
  final TextEditingController _maxSessionTimeController =
      TextEditingController();
  final TextEditingController _usageHoursController = TextEditingController();
  final TextEditingController _minIntervalBeforeReuseController =
      TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _fromHour = TextEditingController();
  final TextEditingController _untilHour = TextEditingController();

  final TextEditingController _times = TextEditingController();
  final TextEditingController _daysFrom = TextEditingController();
  final TextEditingController _daysUntil = TextEditingController();

  String? _selectedGroup;
  String? buttonName;

  List<ComboBoxItem<String>> _groupItems = [];

  DateTime fromSelectedTime = DateTime.now();
  DateTime untilSelectedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if ((widget.cardViewModel?.isEdit ?? false) &&
        !(widget.cardViewModel?.isDuplicate ?? false)) {
      buttonName = "Update Card";
    } else if (widget.cardViewModel?.isDuplicate ?? false) {
      buttonName = "Duplicate Card";
    } else {
      buttonName = "Add Card";
    }
    _fetchGroups();
    _initializeTextControllers();
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

  void _initializeTextControllers() {
    if (widget.cardViewModel != null) {
      _cardNumberController.text = widget.cardViewModel!.cardNumber;
      _mspController.text = widget.cardViewModel!.msp;
      _uidController.text = widget.cardViewModel!.uid;
      _minKWhPerSessionController.text = widget.cardViewModel!.minKwhPerSession;
      _maxKWhPerSessionController.text = widget.cardViewModel!.maxKwhPerSession;
      if (widget.cardViewModel!.minSessionTime != null &&
          widget.cardViewModel!.minSessionTime!.isNotEmpty) {
        int? minSessionTimeInt =
            int.tryParse(widget.cardViewModel!.minSessionTime!);
        int? maxSessionTimeInt =
            int.tryParse(widget.cardViewModel!.maxSessionTime!);
        if (minSessionTimeInt != null) {
          _minSessionTimeController.text = (minSessionTimeInt / 60).toString();
          _maxSessionTimeController.text = (maxSessionTimeInt! / 60).toString();
        }
      }

      _usageHoursController.text = widget.cardViewModel!.usageHours;
      //_minIntervalBeforeReuseController.text = (double.parse(widget.cardViewModel!.minIntervalBeforeReuse) / 3600).toString();
      _referenceController.text = widget.cardViewModel!.reference;
      _fromHour.text = widget.cardViewModel!.usageHours.split(" - ")[0];
      _untilHour.text = widget.cardViewModel!.usageHours.split(" - ")[1];
      _times.text = widget.cardViewModel!.times;
      _daysFrom.text = widget.cardViewModel!.daysFrom;
      _daysUntil.text = widget.cardViewModel!.daysUntil;

      // Set the selected group if groupName is available
      if (widget.cardViewModel!.groupName != null) {
        _selectedGroup = widget.cardViewModel!.groupId.toString();
      }
    } else {
      _minKWhPerSessionController.text = "10.4";
      _maxKWhPerSessionController.text = "10.9";
      _minSessionTimeController.text = "225";
      _maxSessionTimeController.text = "420";
      _fromHour.text = "00";
      _untilHour.text = "24";
      _times.text = "1";
      _daysFrom.text = "1";
      _daysUntil.text = "1";
    }
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
    _cardNumberController.dispose();
    _mspController.dispose();
    _uidController.dispose();
    _minKWhPerSessionController.dispose();
    _maxKWhPerSessionController.dispose();
    _minSessionTimeController.dispose();
    _maxSessionTimeController.dispose();
    _usageHoursController.dispose();
    _minIntervalBeforeReuseController.dispose();
    _referenceController.dispose();
    super.dispose();
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
            Text('Card Number'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9a-zA-Z]')), // Allows digits and spaces
              ],
              maxLength: 16,
              controller: _cardNumberController,
              placeholder: "Card number",
            ),
            SizedBox(
              height: 12,
            ),
            Text('MSP'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _mspController,
              placeholder: "MSP (Name of the card issuer)",
            ),
            SizedBox(
              height: 12,
            ),
            Text('UID'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _uidController,
              placeholder: "UID (Digital card number)",
            ),
            SizedBox(
              height: 12,
            ),
            Text('Minimum kWh per session'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              controller: _minKWhPerSessionController,
              placeholder: "Minimum kWh per session",
            ),
            SizedBox(
              height: 12,
            ),
            Text('Maximum kWh per session'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              controller: _maxKWhPerSessionController,
              placeholder: "Maximum kWh per session",
            ),
            SizedBox(
              height: 12,
            ),
            Text('Minimum session time'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly, // Only allows digits to be entered
              ],
              controller: _minSessionTimeController,
              placeholder: "Minimum session time (in minute)",
            ),
            SizedBox(
              height: 12,
            ),
            Text('Maximum session time'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly, // Only allows digits to be entered
              ],
              controller: _maxSessionTimeController,
              placeholder: "Maximum session time  (in minute)",
            ),
            SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From'),
                      // TimePicker(
                      //   selected: fromSelectedTime,
                      //   hourFormat: HourFormat.HH,
                      //   onChanged: (newTime){
                      //     fromSelectedTime = newTime;
                      //     setState(() {
                      //
                      //     });
                      //   },
                      // ),
                      TextFormBox(
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^([01]?[0-9]|2[0-3])?$')), // Custom formatter to restrict input to 0-23
                        ],
                        controller: _fromHour,
                        placeholder: "Form Hour (00 - 23)",
                      )
                    ],
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Until'),
                      // TimePicker(
                      //   selected: untilSelectedTime,
                      //   hourFormat: HourFormat.HH,
                      //   onChanged: (newTime){
                      //     untilSelectedTime = newTime;
                      //     setState(() {
                      //
                      //     });
                      //   },
                      // ),
                      TextFormBox(
                        controller: _untilHour,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^([01]?[0-9]|2[0-3])?$')), // Custom formatter to restrict input to 0-23
                        ],
                        placeholder: "Until Hour (00 - 23)",
                      )
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 12,
            ),
            Text('Minimum interval before reuse'),
            SizedBox(
              height: 5,
            ),
            // TextFormBox(
            //   controller: _minIntervalBeforeReuseController,
            //   placeholder: "Minimum interval before reuse (in hour)",
            // ),
            Row(
              children: [
                Expanded(
                  child: TextFormBox(
                    controller: _times,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only allows digits to be entered
                    ],
                    placeholder: "Times",
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Text("times per"),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: TextFormBox(
                    controller: _daysFrom,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only allows digits to be entered
                    ],
                    placeholder: "days",
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Text("to"),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: TextFormBox(
                    controller: _daysUntil,
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // Only allows digits to be entered
                    ],
                    placeholder: "days",
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 12,
            ),
            Text('Reference'),
            SizedBox(
              height: 5,
            ),
            TextFormBox(
              controller: _referenceController,
              placeholder: "Reference",
            ),
            const SizedBox(height: 12),
            Text("Assign Group"),
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
            if (_cardNumberController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Card number is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_mspController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "MSP (Name of the card issuer) is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_uidController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "UID (Digital card number) is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_minKWhPerSessionController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Minimum kWh per session is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_maxKWhPerSessionController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Maximum kWh per session is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_minSessionTimeController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Minimum session time is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_maxSessionTimeController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Maximum session time is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_fromHour.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "From hour is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_untilHour.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Until hour is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_times.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Times is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_daysFrom.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Day is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_daysUntil.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Day is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_referenceController.text.isEmpty) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Reference is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else if (_selectedGroup == null) {
              CustomInfoBar.show(context,
                  title: "Action not allowed. :/",
                  content: "Group selection is required. :/",
                  infoBarSeverity: InfoBarSeverity.warning);
            } else {
              int randomDay = Random().nextInt(int.parse(_daysUntil.text) -
                      int.parse(_daysFrom.text) +
                      1) +
                  int.parse(_daysFrom.text);
              double interVal = (randomDay * 24) / int.parse(_times.text);

              int futureTime;


              /// Calculating random future time between 3-8 hours
              var now = DateTime.now();
              Random random = Random();
              int randomHours = 3 + random.nextInt(6);
              var randomFutureTime = now.add(Duration(hours: randomHours));
              futureTime = randomFutureTime.millisecondsSinceEpoch ~/ 1000;

              CardViewModel cardViewModel = CardViewModel(
                cardNumber: _cardNumberController.text.trim(),
                msp: _mspController.text.trim(),
                uid: _uidController.text.trim(),
                minKwhPerSession: _minKWhPerSessionController.text.trim(),
                maxKwhPerSession: _maxKWhPerSessionController.text.trim(),
                minSessionTime:
                    (double.parse(_minSessionTimeController.text.trim()) * 60)
                        .round()
                        .toString(),
                maxSessionTime:
                    (double.parse(_maxSessionTimeController.text.trim()) * 60)
                        .round()
                        .toString(),
                usageHours:
                    '${_fromHour.text.trim()} - ${_untilHour.text.trim()}',
                minIntervalBeforeReuse: (interVal * 3600).toString(),
                groupId: int.parse(_selectedGroup!),
                reference: _referenceController.text.trim(),
                // time: DateTime.now().millisecondsSinceEpoch ~/ 1000 -
                //     (double.parse(interVal.toString()) * 3600).round(),
                time: futureTime,
                times: _times.text,
                daysFrom: _daysFrom.text,
                daysUntil: _daysUntil.text,
              );

              if (widget.cardViewModel == null) {
                await DatabaseHelper.instance
                    .insertCard(cardViewModel.toJson());
              } else if (widget.cardViewModel!.isDuplicate! ||
                  !widget.cardViewModel!.isEdit!) {
                await DatabaseHelper.instance
                    .insertCard(cardViewModel.toJson());
              } else {
                await DatabaseHelper.instance.updateCard(cardViewModel.toJson(),
                    int.parse(widget.cardViewModel!.id.toString()));
              }
              widget.onCardUpdated();
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
