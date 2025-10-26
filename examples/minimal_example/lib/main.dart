import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalExampleApp());
}

class MinimalExampleApp extends StatelessWidget {
  const MinimalExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Minimal Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MinimalExampleHomePage(),
    );
}

class MinimalExampleHomePage extends StatefulWidget {
  const MinimalExampleHomePage({super.key});

  @override
  State<MinimalExampleHomePage> createState() => _MinimalExampleHomePageState();
}

class _MinimalExampleHomePageState extends State<MinimalExampleHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Minimal Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to Minimal Example!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a minimal Flutter project created with Fly CLI.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
}
