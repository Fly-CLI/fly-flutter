import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

// User Model
class User {

  const User({
    required this.name,
    required this.email,
    required this.age,
  });
  final String name;
  final String email;
  final int age;

  User copyWith({
    String? name,
    String? email,
    int? age,
  }) => User(
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
    );
}

// User Provider using Riverpod v3 syntax
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  AsyncValue<User> build() {
    _loadUser();
    return const AsyncValue.loading();
  }

  Future<void> _loadUser() async {
    // Simulate loading user data
    await Future<void>.delayed(const Duration(seconds: 1));
    
    state = const AsyncValue.data(
      User(
        name: 'John Doe',
        email: 'john.doe@example.com',
        age: 25,
      ),
    );
  }

  void updateUser(String name, String email, int age) {
    state.whenData((user) {
      state = AsyncValue.data(user.copyWith(
        name: name,
        email: email,
        age: age,
      ),
    );
    });
  }
}

// Theme Mode Provider using Riverpod v3 syntax
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
