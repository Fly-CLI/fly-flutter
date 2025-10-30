import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return _buildListScreen();
  }

  Widget _buildListScreen() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.circle),
            title: Text('Item ${index + 1}'),
            subtitle: const Text('Description of item'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO(john): Navigate to detail screen
            },
          ),
        );
      },
    );
  }
}
