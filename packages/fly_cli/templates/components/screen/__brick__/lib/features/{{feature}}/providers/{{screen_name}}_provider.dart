import 'package:flutter_riverpod/flutter_riverpod.dart';

class {{screen_name.pascalCase()}}Notifier extends StateNotifier<{{screen_name.pascalCase()}}State> {
{{screen_name.pascalCase()}}Notifier() : super(const {{screen_name.pascalCase()}}State());

{{#screen_type_list}} Future<void> loadData() async {
state = state.copyWith(isLoading: true, error: null);

try {
// TODO: Implement data loading logic
await Future.delayed(const Duration(seconds: 1)); // Simulate API call

state = state.copyWith(
isLoading: false,
items: List.generate(10, (index) => 'Item \${index + 1}'),
);
} catch (e) {
state = state.copyWith(
isLoading: false,
error: e.toString(),
);
}
}
{{/screen_type_list}}{{^screen_type_list}} Future<void> loadData() async {
state = state.copyWith(isLoading: true, error: null);

try {
// TODO: Implement data loading logic
await Future.delayed(const Duration(seconds: 1)); // Simulate API call

state = state.copyWith(
isLoading: false,
);
} catch (e) {
state = state.copyWith(
isLoading: false,
error: e.toString(),
);
}
}
{{/screen_type_list}}

{{#screen_type_form}} Future<void> submitForm(Map<String, dynamic> formData) async {
state = state.copyWith(isLoading: true, error: null);

try {
// TODO: Implement form submission
await Future.delayed(const Duration(seconds: 1));

state = state.copyWith(
isLoading: false,
isSubmitted: true,
);
} catch (e) {
state = state.copyWith(
isLoading: false,
error: e.toString(),
);
}
}
{{/screen_type_form}}

{{#screen_type_auth}} Future<void> authenticate(String username, String password) async {
state = state.copyWith(isLoading: true, error: null);

try {
// TODO: Implement authentication logic
await Future.delayed(const Duration(seconds: 1));

state = state.copyWith(
isLoading: false,
isAuthenticated: true,
);
} catch (e) {
state = state.copyWith(
isLoading: false,
error: e.toString(),
);
}
}
{{/screen_type_auth}}

void refresh() {
loadData();
}

void clearError() {
state = state.copyWith(error: null);
}
}

class {{screen_name.pascalCase()}}State {
const {{screen_name.pascalCase()}}State({
this.isLoading = false,
this.error,
{{#screen_type_list}} this.items = const [],
{{/screen_type_list}}{{#screen_type_form}} this.isSubmitted = false,
{{/screen_type_form}}{{#screen_type_auth}} this.isAuthenticated = false,
{{/screen_type_auth}} });

final bool isLoading;
final String? error;
{{#screen_type_list}} final List<String> items;
{{/screen_type_list}}{{#screen_type_form}} final bool isSubmitted;
{{/screen_type_form}}{{#screen_type_auth}} final bool isAuthenticated;
{{/screen_type_auth}}

bool get hasError => error != null;

{{screen_name.pascalCase()}}State copyWith({
bool? isLoading,
String? error,
{{#screen_type_list}} List<String>? items,
{{/screen_type_list}}{{#screen_type_form}} bool? isSubmitted,
{{/screen_type_form}}{{#screen_type_auth}} bool? isAuthenticated,
{{/screen_type_auth}} }) {
return {{screen_name.pascalCase()}}State(
isLoading: isLoading ?? this.isLoading,
error: error,
{{#screen_type_list}} items: items ?? this.items,
{{/screen_type_list}}{{#screen_type_form}} isSubmitted: isSubmitted ?? this.isSubmitted,
{{/screen_type_form}}{{#screen_type_auth}} isAuthenticated: isAuthenticated ?? this.isAuthenticated,
{{/screen_type_auth}} );
}
}

final {{screen_name}}Provider = StateNotifierProvider<{{screen_name.pascalCase()}}Notifier, {{screen_name.pascalCase()}}State>(
(ref) => {{screen_name.pascalCase()}}Notifier
(
)
,
);
