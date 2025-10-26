import 'package:flutter/material.dart';

void main() {
  runApp(const {{project_name_pascal}}App());
}

class {{project_name_pascal}}App extends StatelessWidget {
  const {{project_name_pascal}}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{project_name}}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const {{project_name_pascal}}HomePage(),
    );
  }
}

class {{project_name_pascal}}HomePage extends StatelessWidget {
  const {{project_name_pascal}}HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('{{project_name}}'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to {{project_name}}!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            Text(
              'This is a minimal Flutter project created with Fly CLI.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
