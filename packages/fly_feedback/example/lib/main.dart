import 'package:flutter/material.dart';
import 'screens/simple_direct_usage_screen.dart';
import 'screens/display_types_screen.dart';
import 'screens/feedback_types_screen.dart';
import 'screens/emitter_listener_screen.dart';
import 'screens/custom_handler_screen.dart';
import 'screens/real_world_scenarios_screen.dart';
import 'screens/semantics_screen.dart';

void main() {
  runApp(const FlyFeedbackExampleApp());
}

/// Main application entry point
///
/// This app demonstrates all usage patterns of the fly_feedback package,
/// from simple direct usage to advanced custom handlers and real-world scenarios.
class FlyFeedbackExampleApp extends StatelessWidget {
  const FlyFeedbackExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fly Feedback Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

/// Home screen with navigation to all examples
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fly Feedback Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Explore the Fly Feedback package through comprehensive examples.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _ExampleCard(
            title: '1. Simple Direct Usage',
            description:
                'Learn the basics of using FeedbackService directly with BuildContext.',
            icon: Icons.stars,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SimpleDirectUsageScreen(),
                ),
              );
            },
          ),
          _ExampleCard(
            title: '2. All Display Types',
            description:
                'Explore all feedback display strategies: SnackBar, Dialog, BottomSheet, Toast, Banner.',
            icon: Icons.visibility,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DisplayTypesScreen(),
                ),
              );
            },
          ),
          _ExampleCard(
            title: '3. All Feedback Types',
            description:
                'See all feedback types: Success, Error, Warning, Info, and Confirmation.',
            icon: Icons.category,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FeedbackTypesScreen(),
                ),
              );
            },
          ),
          _ExampleCard(
            title: '4. Emitter/Listener Pattern',
            description:
                'Learn how to emit feedback from services/view models and listen in widgets.',
            icon: Icons.radio,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmitterListenerScreen(),
                ),
              );
            },
          ),
          _ExampleCard(
            title: '5. Custom Handler',
            description:
                'Create custom feedback handlers for specialized display requirements.',
            icon: Icons.build,
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomHandlerScreen(),
                ),
              );
            },
          ),
          _ExampleCard(
            title: '6. Real-World Scenarios',
            description:
                'Practical examples: API calls, form validation, file operations, and more.',
            icon: Icons.work,
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RealWorldScenariosScreen(),
                ),
              );
            },
          ),
          _ExampleCard(
            title: '7. Accessibility Semantics',
            description:
                'Configure semantic labels and hints to make feedback accessible to screen readers.',
            icon: Icons.accessibility_new,
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SemanticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Card widget for example navigation
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

