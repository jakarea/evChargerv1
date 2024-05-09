class ActiveSessionModel{
  final int cardId;
  final String chargerId;
  final String chargerName;
  final String chargerModel;
  final String serialBox;
  final String cardNumber;
  final String msp;
  final String uid;
  final int transactionSession;
  final String kwh;
  final String sessionTime;

  ActiveSessionModel({
    required this.cardId,
    required this.chargerId,
    required this.chargerName,
    required this.chargerModel,
    required this.serialBox,
    required this.cardNumber,
    required this.msp,
    required this.uid,
    required this.transactionSession,
    required this.kwh,
    required this.sessionTime,
  });

  /// Factory constructor to create a GroupViewModel from a Map
  factory ActiveSessionModel.fromJson(Map<String, dynamic> json){
    print("session MODEl ${json}");
    return ActiveSessionModel(
        cardId: json['id'],
        chargerId: json['charger_id'],
        chargerName: "",
        chargerModel: "",
        serialBox: json['charge_box_serial_number'],
        cardNumber: json['card_number'],
        msp: json['msp'],
        uid: json['uid'],
        transactionSession: json ['transaction_start_time'],
        kwh: json ['kwh'],
        sessionTime: json['session_time']
    );
  }
}