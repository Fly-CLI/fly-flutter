# fly_glow_guard

Flow Guard delivers network-aware async execution with retry logic, offline queuing, and rich telemetry for Flutter applications.

## Features

- Network-aware operation execution
- Configurable retry with exponential backoff
- Offline queue integration
- Timeout configuration
- Progress callbacks
- Event emission for observability

## Usage

```dart
import 'package:fly_glow_guard/fly_glow_guard.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_connectivity/fly_connectivity.dart';

// Create handler
final logger = FlyLoggerImpl('MyApp');
final connectivityService = ConnectivityService(
  checker: myChecker,
  logger: logger,
);
final guard = FlowGuard(
  logger: logger,
  connectivityService: connectivityService,
);

// Execute operation
final result = await guard.execute(() => apiService.fetchData());
if (result.isSuccess) {
  final data = result.data;
}

// Execute with retry
final result = await guard.executeWithRetry(
  () => apiService.fetchData(),
  retryConfig: RetryConfig.standard(),
);

// Execute network operation
final result = await guard.executeNetworkOperation(
  () => apiService.postData(data),
  queueIfOffline: true,
);
```

