import 'package:flutter_riverpod/flutter_riverpod.dart';

class {{screen_name.pascalCase()}}Notifier extends StateNotifier<{{screen_name.pascalCase()}}State> {
  {{screen_name.pascalCase()}}Notifier() : super(const {{screen_name.pascalCase()}}State());

  Future<void> loadData() async {
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

<% if (screen_type == 'form') { %>  Future<void> submitForm(Map<String, dynamic> formData) async {
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
<% } %>

<% if (screen_type == 'auth') { %>  Future<void> authenticate(String username, String password) async {
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
<% } %>

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
<% if (screen_type == 'list') { %>    this.items = const [],
<% } %><% if (screen_type == 'form') { %>    this.isSubmitted = false,
<% } %><% if (screen_type == 'auth') { %>    this.isAuthenticated = false,
<% } %>  });

  final bool isLoading;
  final String? error;
<% if (screen_type == 'list') { %>  final List<String> items;
<% } %><% if (screen_type == 'form') { %>  final bool isSubmitted;
<% } %><% if (screen_type == 'auth') { %>  final bool isAuthenticated;
<% } %>

  bool get hasError => error != null;

  {{screen_name.pascalCase()}}State copyWith({
    bool? isLoading,
    String? error,
<% if (screen_type == 'list') { %>    List<String>? items,
<% } %><% if (screen_type == 'form') { %>    bool? isSubmitted,
<% } %><% if (screen_type == 'auth') { %>    bool? isAuthenticated,
<% } %>  }) {
    return {{screen_name.pascalCase()}}State(
      isLoading: isLoading ?? this.isLoading,
      error: error,
<% if (screen_type == 'list') { %>      items: items ?? this.items,
<% } %><% if (screen_type == 'form') { %>      isSubmitted: isSubmitted ?? this.isSubmitted,
<% } %><% if (screen_type == 'auth') { %>      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
<% } %>    );
  }
}

final {{screen_name}}Provider = StateNotifierProvider<{{screen_name.pascalCase()}}Notifier, {{screen_name.pascalCase()}}State>(
  (ref) => {{screen_name.pascalCase()}}Notifier(),
);
