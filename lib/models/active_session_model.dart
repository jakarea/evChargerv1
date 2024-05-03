class ActiveSessionModel{
  final String cardId;
  final String chargerId;
  final String chargerName;
  final String chargerModel;
  final String serialBox;
  final String cardNumber;
  final String msp;
  final String uid;
  final String transactionSession;
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
}