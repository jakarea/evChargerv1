import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';

class CardSettingsDialog extends StatefulWidget {
  const CardSettingsDialog({super.key, required this.onUpdated,
    required this.initialMinKwh,
    required this.initialMaxKwh,
    required this.initialMaxSessionTime,
    required this.initialUsageHour,
    required this.initialMinInterval,
    required this.initialReference,
    required this.initialGroupCard});

  final Function(bool, bool, bool, bool, bool, bool, bool) onUpdated;
  final bool initialMinKwh;
  final bool initialMaxKwh;
  final bool initialMaxSessionTime;
  final bool initialUsageHour;
  final bool initialMinInterval;
  final bool initialReference;
  final bool initialGroupCard;

  static void show(BuildContext context,
      Function(bool, bool, bool, bool, bool, bool, bool) onUpdated,
      {
        bool initialMinKwh = true,
        bool initialMaxKwh = true,
        bool initialMaxSessionTime = true,
        bool initialUsageHour = true,
        bool initialMinInterval = true,
        bool initialReference = true,
        bool initialGroupCard = true,
      }
      ){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return CardSettingsDialog(onUpdated: onUpdated,
            initialMinKwh: initialMinKwh,
            initialMaxKwh: initialMaxKwh,
            initialMaxSessionTime: initialMaxSessionTime,
            initialUsageHour: initialUsageHour,
            initialMinInterval: initialMinInterval,
            initialReference: initialReference,
            initialGroupCard: initialGroupCard,
          );
        }
    );
  }

  @override
  State<CardSettingsDialog> createState() => _CardSettingsDialogState();
}

class _CardSettingsDialogState extends State<CardSettingsDialog> {

  bool minKwh = true;
  bool maxKwh = true;
  bool maxSessionTime = true;
  bool usageHour = true;
  bool minInterval = true;
  bool reference = true;
  bool groupCard = true;

  @override
  void initState() {
    super.initState();
    minKwh = widget.initialMinKwh;
    maxKwh = widget.initialMaxKwh;
    maxSessionTime = widget.initialMaxSessionTime;
    usageHour = widget.initialUsageHour;
    minInterval = widget.initialMinInterval;
    reference = widget.initialReference;
    groupCard = widget.initialGroupCard;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text("Hide fields"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Unselect field to hide them"),
              SizedBox(height: 10,),
              buildCheckboxRow(
                  (){
                    minKwh = !minKwh;
                    setState(() {

                    });
                  },
                  'Minimum kWh',
                  minKwh,
                      (value) => setState(() => minKwh = value ?? true)),
              SizedBox(height: 10,),
              buildCheckboxRow(
                      (){
                        maxKwh = !maxKwh;setState(() {

                        });
                  },
                  'Maximum kWh', maxKwh, (value) => setState(() => maxKwh = value ?? true)),
              SizedBox(height: 10,),
              buildCheckboxRow(
                      (){
                        maxSessionTime = !maxSessionTime;setState(() {

                        });
                  },
                  'Maximum Session Time', maxSessionTime, (value) => setState(() => maxSessionTime = value ?? true)),
              SizedBox(height: 10,),
              buildCheckboxRow(
                      (){
                        usageHour = !usageHour;setState(() {

                        });
                  },
                  'Usage Hour', usageHour, (value) => setState(() => usageHour = value ?? true)),
              SizedBox(height: 10,),
              buildCheckboxRow(
                      (){
                        minInterval = !minInterval;setState(() {

                        });
                  },
                  'Minimum Interval', minInterval, (value) => setState(() => minInterval = value ?? true)),
              SizedBox(height: 10,),
              buildCheckboxRow(
                      (){
                        reference = !reference;setState(() {

                        });
                  },
                  'Reference', reference, (value) => setState(() => reference = value ?? true)),
              SizedBox(height: 10,),
              buildCheckboxRow(
                      (){
                        groupCard = !groupCard;setState(() {

                        });
                  },
                  'Group Card', groupCard, (value) => setState(() => groupCard = value ?? true)),
            ],
          )

        ],
      ),
      actions: [
        Button(child: Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        FilledButton(child: Text('Apply'), onPressed: (){
          widget.onUpdated(minKwh, maxKwh, maxSessionTime, usageHour, minInterval, reference, groupCard);
          Navigator.of(context).pop();
        }),
      ],
    );
  }

  Widget buildCheckboxRow(VoidCallback onPressed, String title, bool value, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          Checkbox(
            checked: value,
            onChanged: onChanged,
          ),
          SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}
