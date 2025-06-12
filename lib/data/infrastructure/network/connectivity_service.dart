import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Stream<bool> get connectionStatusStream;
  Future<bool> get isConnected;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _connectionStatusController.add(false);
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final isConnected = result != ConnectivityResult.none;
    _connectionStatusController.add(isConnected);
  }

  @override
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
