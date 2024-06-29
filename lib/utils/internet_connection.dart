
import 'package:connectivity_plus/connectivity_plus.dart';

class CheckInternetConnection{
  Future<bool> hasInternetConnection() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }
}