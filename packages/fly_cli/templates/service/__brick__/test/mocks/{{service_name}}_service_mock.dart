import 'package:mocktail/mocktail.dart';
import 'package:fly_tools/features/{{feature}}/services/{{service_name}}_service.dart';

class Mock{{service_name.pascalCase()}}Service extends Mock implements {{service_name.pascalCase()}}Service {}

// Example usage in tests:
// final mockService = Mock{{service_name.pascalCase()}}Service();
<% if (service_type == 'api') { %>// when(() => mockService.fetchData()).thenAnswer((_) async => {'data': 'test'});
// when(() => mockService.postData(any())).thenAnswer((_) async => {'id': 1});
<% } %><% if (service_type == 'local') { %>// when(() => mockService.loadData()).thenAnswer((_) async => {'key': 'value'});
// when(() => mockService.saveData(any())).thenAnswer((_) async {});
<% } %><% if (service_type == 'cache') { %>// when(() => mockService.getData(any())).thenAnswer((_) async => {'value': 'test'});
// when(() => mockService.setData(any(), any())).thenReturn();
<% } %><% if (service_type == 'analytics') { %>// when(() => mockService.logEvent(any(), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
// when(() => mockService.logScreenView(any())).thenAnswer((_) async {});
<% } %><% if (service_type == 'storage') { %>// when(() => mockService.setString(any(), any())).thenAnswer((_) async => true);
// when(() => mockService.getString(any())).thenAnswer((_) async => 'value');
<% } %>
