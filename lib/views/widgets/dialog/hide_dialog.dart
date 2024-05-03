import 'package:fluent_ui/fluent_ui.dart';

class HideDialog extends StatefulWidget {
  const HideDialog({super.key, required this.onUpdated,
    required this.initialBoxSerial,
    required this.initialFirmwareVersion,
    required this.initialIntervalTime,
    required this.initialUrlToConnect,
    required this.initialGroup,
    required this.initialMaximumChargingPower});

  final Function(bool, bool, bool, bool, bool, bool) onUpdated;
  final bool initialBoxSerial;
  final bool initialFirmwareVersion;
  final bool initialIntervalTime;
  final bool initialUrlToConnect;
  final bool initialGroup;
  final bool initialMaximumChargingPower;

  static void show(BuildContext context,
      Function(bool, bool, bool, bool, bool, bool) onUpdated,
      {
        bool initialBoxSerial = true,
        bool initialFirmwareVersion = true,
        bool initialIntervalTime = true,
        bool initialUrlToConnect = true,
        bool initialGroup = true,
        bool initialMaximumChargingPower = true,
      }
      ){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return HideDialog(onUpdated: onUpdated,
            initialBoxSerial: initialBoxSerial,
            initialFirmwareVersion: initialFirmwareVersion,
            initialIntervalTime: initialIntervalTime,
            initialUrlToConnect: initialUrlToConnect,
            initialGroup: initialGroup,
            initialMaximumChargingPower: initialMaximumChargingPower,
          );
        }
    );
  }

  @override
  State<HideDialog> createState() => _HideDialogState();
}

class _HideDialogState extends State<HideDialog> {

  bool boxSerial = true;
  bool firmwareVersion = true;
  bool intervalTime = true;
  bool urlToConnect = true;
  bool group = true;
  bool maximumChargingPower = true;

  @override
  void initState() {
    boxSerial = widget.initialBoxSerial;
    firmwareVersion = widget.initialFirmwareVersion;
    intervalTime = widget.initialIntervalTime;
    urlToConnect = widget.initialUrlToConnect;
    group = widget.initialGroup;
    maximumChargingPower = widget.initialMaximumChargingPower;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text("Hide fields"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Unselect field to hide them"),
          SizedBox(height: 10,),
          GestureDetector(
            onTap: () {
              setState(() {
                // Toggle the checkbox state
                boxSerial = !boxSerial;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  checked: boxSerial,
                  onChanged: (bool? value) {
                    setState(() {
                      boxSerial = value ?? true;
                    });
                  },
                ),
                SizedBox(width: 10),
                Expanded(child: Text("Box Serial Number"))
              ],
            ),
          ),
          SizedBox(height: 10,),
          GestureDetector(
            onTap: (){
              setState(() {
                // Toggle the checkbox state
                firmwareVersion = !firmwareVersion;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  checked: firmwareVersion,
                  onChanged: (bool? value){
                    setState(() {
                      firmwareVersion = value ?? false;
                    });
                  },
                ),
                SizedBox(width: 10,),
                Expanded(child: Text("Firmware Version"))
              ],
            ),
          ),
          SizedBox(height: 10,),
          GestureDetector(
            onTap: (){
              setState(() {
                // Toggle the checkbox state
                intervalTime = !intervalTime;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  checked: intervalTime,
                  onChanged: (bool? value){
                    setState(() {
                      intervalTime = value ?? false;
                    });
                  },
                ),
                SizedBox(width: 10,),
                Expanded(child: Text("Interval Time"))
              ],
            ),
          ),
          SizedBox(height: 10,),
          GestureDetector(
            onTap: (){
              setState(() {
                // Toggle the checkbox state
                urlToConnect = !urlToConnect;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  checked: urlToConnect,
                  onChanged: (bool? value){
                    setState(() {
                      urlToConnect = value ?? false;
                    });
                  },
                ),
                SizedBox(width: 10,),
                Expanded(child: Text("URL to connect to"))
              ],
            ),
          ),
          SizedBox(height: 10,),
          GestureDetector(
            onTap: (){
              setState(() {
                // Toggle the checkbox state
                group = !group;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  checked: group,
                  onChanged: (bool? value){
                    setState(() {
                      group = value ?? false;
                    });
                  },
                ),
                SizedBox(width: 10,),
                Expanded(child: Text("Group"))
              ],
            ),
          ),
          SizedBox(height: 10,),
          GestureDetector(
            onTap: (){
              setState(() {
                // Toggle the checkbox state
                maximumChargingPower = !maximumChargingPower;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  checked: maximumChargingPower,
                  onChanged: (bool? value){
                    setState(() {
                      maximumChargingPower = value ?? false;
                    });
                  },
                ),
                SizedBox(width: 10,),
                Expanded(child: Text("Maximum Charging Power"))
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(child: Text('Cancel'), onPressed: (){
          Navigator.of(context).pop();
        }),
        FilledButton(child: Text('Apply'), onPressed: (){
          widget.onUpdated(boxSerial, firmwareVersion, intervalTime, urlToConnect, group, maximumChargingPower);
          Navigator.of(context).pop();
        })
      ],
    );
  }
}
