class ChargersViewModel{
  final int? id;
  final String? chargePointVendor;
  final String? chargePointModel;
  final String? chargePointSerialNumber;
  final String? firmwareVersion;
  final String? chargeBoxSerialNumber;
  final String? intervalTime;
  final int? lastUpdate;
  final String? urlToConnect;
  final String? groupName;
  final int? groupId;
  final String? maximumChargingPower;
  final String? meterValue;
  final String? status;
  final String? chargingStatus;
  bool? isEdit;
  bool? isDuplicate;

  ChargersViewModel({
    this.id,
     this.chargePointVendor,
     this.chargePointModel,
     this.chargePointSerialNumber,
     this.firmwareVersion,
     this.chargeBoxSerialNumber,
     this.intervalTime,
     this.lastUpdate,
     this.urlToConnect,
    this.groupName,
     this.groupId,
     this.maximumChargingPower,
     this.meterValue,
    this.status,
    this.chargingStatus,
    this.isEdit = true,
    this.isDuplicate = false
  });

  /// Converting data to json format
  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = <String, dynamic>{};

    data['charge_point_vendor'] = chargePointVendor;
    data['charge_point_model'] = chargePointModel;
    data['charge_point_serial_number'] = chargePointSerialNumber;
    data['firmware_version'] = firmwareVersion;
    data['charge_box_serial_number'] = chargeBoxSerialNumber;
    data['interval_time'] = intervalTime;
    data['next_update'] = lastUpdate;
    data['url_to_connect'] = urlToConnect;
    data['group_id'] = groupId;
    data['maximum_charging_power'] = maximumChargingPower;
    data['meter_value'] = meterValue;

    return data;
  }

  /// Factory constructor to create a GroupViewModel from a Map
  factory ChargersViewModel.fromJson(Map<String, dynamic> json){
    return ChargersViewModel(
        id: json['id'],
        chargePointVendor: json['charge_point_vendor'],
        chargePointModel: json ['charge_point_model'],
        chargePointSerialNumber: json ['charge_point_serial_number'],
        firmwareVersion: json ['firmware_version'],
        chargeBoxSerialNumber: json ['charge_box_serial_number'],
        intervalTime: json['interval_time'],
        lastUpdate: json['next_update'],
        urlToConnect: json ['url_to_connect'],
        groupName: json ['group_name'],
        groupId: json['group_id'],
        maximumChargingPower: json ['maximum_charging_power'],
        meterValue: json['meter_value'],
        status: json['status'],
        chargingStatus: json['charging_status']
    );
  }
}