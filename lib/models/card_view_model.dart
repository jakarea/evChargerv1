class CardViewModel{
  final int? id;
  final String cardNumber;
  final String msp;
  final String uid;
  final String minKwhPerSession;
  final String maxKwhPerSession;
  String? minSessionTime;
  String? maxSessionTime;
  final String usageHours;
  final String? groupName;
  final int? groupId;
  String? minIntervalBeforeReuse;
  final String reference;
  int? time;
  final double? beginMeterValue;
  final double? lastMeterValue;
  final String times;
  final String daysFrom;
  final String daysUntil;
  final String? chargerId;
  bool? isEdit;
  bool? isDuplicate;

  CardViewModel({
    this.id,
    required this.cardNumber,
    required this.msp,
    required this.uid,
    required this.minKwhPerSession,
    required this.maxKwhPerSession,
    this.minSessionTime,
    this.maxSessionTime,
    required this.usageHours,
    this.groupName,
    this.groupId,
    this.minIntervalBeforeReuse,
    required this.reference,
    this.time,
    this.beginMeterValue,
    this.lastMeterValue,
    required this.times,
    required this.daysFrom,
    required this.daysUntil,
    this.chargerId,
    this.isEdit = true,
    this.isDuplicate = false
  });

  /// Converting data to json format
  Map<String, dynamic> toJson(){
    final Map<String, dynamic> data = <String, dynamic>{};

    data['card_number'] = cardNumber;
    data['msp'] = msp;
    data['uid'] = uid;
    data['min_kwh_per_session'] = minKwhPerSession;
    data['max_kwh_per_session'] = maxKwhPerSession;
    data['min_session_time'] = minSessionTime;
    data['max_session_time'] = maxSessionTime;
    data['usage_hours'] = usageHours;
    data['group_id'] = groupId;
    data['min_interval_before_reuse'] = minIntervalBeforeReuse;
    data['reference'] = reference;
    data['time'] = time;
    data['times'] = times;
    data['days_from'] = daysFrom;
    data['days_until'] = daysUntil;
    data['charger_id'] = chargerId ?? '';
    return data;
  }

  /// Factory constructor to create a GroupViewModel from a Map
  factory CardViewModel.fromJson(Map<String, dynamic> json){
    return CardViewModel(
      id: json['id'],
      cardNumber: json['card_number'],
      msp: json ['msp'],
      uid: json ['uid'],
      minKwhPerSession: json ['min_kwh_per_session'],
      maxKwhPerSession: json ['max_kwh_per_session'],
      minSessionTime: json['min_session_time'],
      maxSessionTime: json['max_session_time'],
      usageHours: json ['usage_hours'],
      groupId: json['group_id'],
      groupName: json ['group_name'],
      minIntervalBeforeReuse: json ['min_interval_before_reuse'],
      reference: json ['reference'],
      time: json['time'],
      times: json['times'],
      daysFrom: json['days_from'],
      daysUntil: json['days_until'],
      beginMeterValue: json['begin_meter_value'],
      lastMeterValue: json['last_meter_value'],
      chargerId: json['charger_id'],
    );
  }
}