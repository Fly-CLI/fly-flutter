# fly_connectivity

Network connectivity checking with pluggable implementations for Flutter applications.

## Features

- Abstract connectivity checking interface
- Network connectivity service with real-time monitoring
- Connection state tracking
- Wait for connection with timeout
- Stream-based connectivity change notifications

## Usage

```dart
import 'package:fly_connectivity/fly_connectivity.dart';
import 'package:fly_logger/fly_logger.dart';

// Implement ConnectivityChecker
class MyConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasInternetConnection() async {
    // Your implementation
  }
  
  @override
  Future<bool> isConnectedToWifi() async {
    // Your implementation
  }
  
  @override
  Future<ConnectivityType> getConnectivityStatus() async {
    // Your implementation
  }
  
  @override
  Stream<List<ConnectivityType>> get onConnectivityChanged {
    // Your implementation
  }
}

// Use ConnectivityService
final logger = FlyLoggerImpl('MyApp');
final checker = MyConnectivityChecker();
final connectivityService = ConnectivityService(
  checker: checker,
  logger: logger,
);

// Check connectivity
final hasConnection = await connectivityService.hasInternetConnection();

// Listen to connectivity changes
connectivityService.onConnectivityChanged.listen((types) {
  print('Connectivity changed: $types');
});
```

