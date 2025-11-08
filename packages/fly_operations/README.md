# fly_operations

Async operation handling with retry logic, network awareness, and offline queuing for Flutter applications.

## Features

- Network-aware operation execution
- Configurable retry with exponential backoff
- Offline queue integration
- Timeout configuration
- Progress callbacks
- Event emission for observability

## Usage

```dart
import 'package:fly_operations/fly_operations.dart';
import 'package:fly_logger/fly_logger.dart';
import 'package:fly_connectivity/fly_connectivity.dart';

// Create handler
final logger = FlyLoggerImpl('MyApp');
final connectivityService = ConnectivityService(
  checker: myChecker,
  logger: logger,
);
final handler = AsyncOperationHandler(
  logger: logger,
  connectivityService: connectivityService,
);

// Execute operation
final result = await handler.execute(() => apiService.fetchData());
if (result.isSuccess) {
  final data = result.data;
}

// Execute with retry
final result = await handler.executeWithRetry(
  () => apiService.fetchData(),
  retryConfig: RetryConfig.standard(),
);

// Execute network operation
final result = await handler.executeNetworkOperation(
  () => apiService.postData(data),
  queueIfOffline: true,
);
```

