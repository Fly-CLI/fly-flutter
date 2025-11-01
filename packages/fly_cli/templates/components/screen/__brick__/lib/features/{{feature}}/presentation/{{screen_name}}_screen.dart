import 'package:flutter/material.dart';
{{#with_viewmodel}}import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/{{screen_name}}_provider.dart';
{{/with_viewmodel}}

class {{screen_name.pascalCase()}}Screen extends StatelessWidget {
const {{screen_name.pascalCase()}}Screen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('{{screen_name.titleCase()}}'),
{{#with_navigation}} leading: IconButton(
icon: const Icon(Icons.arrow_back),
onPressed: () => Navigator.of(context).pop(),
),
{{/with_navigation}} ),
body: {{#with_viewmodel}}Consumer({{/with_viewmodel}}_buildBody({{#with_viewmodel}}ref{{/with_viewmodel}}){{#with_viewmodel}}){{/with_viewmodel}},
);
}

{{#with_viewmodel}} Widget _buildBody(WidgetRef ref) {
final state = ref.watch({{screen_name}}Provider);

if (state.isLoading) {
return const Center(child: CircularProgressIndicator());
}

if (state.hasError) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.error, size: 64, color: Colors.red),
const SizedBox(height: 16),
Text('Error: \${state.error}'),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () => ref.refresh({{screen_name}}Provider),
child: const Text('Retry'),
),
],
),
);
}

return _buildContent(state);
}

Widget _buildContent({{screen_name.pascalCase()}}State state) {
switch ('{{screen_type}}') {
case 'list':
return _buildListScreen(state);
case 'detail':
return _buildDetailScreen(state);
case 'form':
return _buildFormScreen(state);
case 'auth':
return _buildAuthScreen(state);
case 'settings':
return _buildSettingsScreen(state);
default:
return _buildDefaultScreen(state);
}
}
{{/with_viewmodel}}{{^with_viewmodel}} Widget _buildBody() {
switch ('{{screen_type}}') {
case 'list':
return _buildListScreen();
case 'detail':
return _buildDetailScreen();
case 'form':
return _buildFormScreen();
case 'auth':
return _buildAuthScreen();
case 'settings':
return _buildSettingsScreen();
default:
return _buildDefaultScreen();
}
}
{{/with_viewmodel}}

{{#screen_type_list}} Widget _buildListScreen({{#with_viewmodel}}{{screen_name.pascalCase()}}State state{{/with_viewmodel}}) {
return ListView.builder(
itemCount: {{#with_viewmodel}}state.items.length{{/with_viewmodel}}{{^with_viewmodel}}10{{/with_viewmodel}},
itemBuilder: (context, index) {
return Card(
margin: const EdgeInsets.all(8.0),
child: ListTile(
leading: const Icon(Icons.item),
title: Text('Item \${index + 1}'),
subtitle: const Text('Description of item'),
trailing: const Icon(Icons.arrow_forward_ios),
onTap: () {
// TODO: Navigate to detail screen
},
),
);
},
);
}
{{/screen_type_list}}

{{#screen_type_detail}} Widget _buildDetailScreen({{#with_viewmodel}}{{screen_name.pascalCase()}}State state{{/with_viewmodel}}) {
return SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Details',
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
),
const SizedBox(height: 16),
const Text('Detail content goes here...'),
const SizedBox(height: 16),
ElevatedButton(
onPressed: () {
// TODO: Implement action
},
child: const Text('Action'),
),
],
),
);
}
{{/screen_type_detail}}

{{#screen_type_form}} Widget _buildFormScreen({{#with_viewmodel}}{{screen_name.pascalCase()}}State state{{/with_viewmodel}}) {
final formKey = GlobalKey<FormState>();

return Form(
key: formKey,
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
children: [
TextFormField(
decoration: const InputDecoration(
labelText: 'Name',
border: OutlineInputBorder(),
),
{{#with_validation}} validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter a name';
}
return null;
},
{{/with_validation}} ),
const SizedBox(height: 16),
TextFormField(
decoration: const InputDecoration(
labelText: 'Email',
border: OutlineInputBorder(),
),
{{#with_validation}} validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter an email';
}
if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
return 'Please enter a valid email';
}
return null;
},
{{/with_validation}} ),
const SizedBox(height: 24),
ElevatedButton(
onPressed: () {
if (formKey.currentState!.validate()) {
// TODO: Process form
}
},
child: const Text('Submit'),
),
],
),
),
);
}
{{/screen_type_form}}

{{#screen_type_auth}} Widget _buildAuthScreen({{#with_viewmodel}}{{screen_name.pascalCase()}}State state{{/with_viewmodel}}) {
return Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.lock, size: 64),
const SizedBox(height: 16),
const Text(
'Authentication',
style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
),
const SizedBox(height: 32),
TextFormField(
decoration: const InputDecoration(
labelText: 'Username',
border: OutlineInputBorder(),
),
),
const SizedBox(height: 16),
TextFormField(
decoration: const InputDecoration(
labelText: 'Password',
border: OutlineInputBorder(),
),
obscureText: true,
),
const SizedBox(height: 24),
ElevatedButton(
onPressed: () {
// TODO: Implement authentication
},
child: const Text('Sign In'),
),
],
),
);
}
{{/screen_type_auth}}

{{#screen_type_settings}} Widget _buildSettingsScreen({{#with_viewmodel}}{{screen_name.pascalCase()}}State state{{/with_viewmodel}}) {
return ListView(
children: [
const ListTile(
leading: Icon(Icons.person),
title: Text('Profile'),
trailing: Icon(Icons.arrow_forward_ios),
),
const ListTile(
leading: Icon(Icons.notifications),
title: Text('Notifications'),
trailing: Icon(Icons.arrow_forward_ios),
),
const ListTile(
leading: Icon(Icons.security),
title: Text('Privacy'),
trailing: Icon(Icons.arrow_forward_ios),
),
const ListTile(
leading: Icon(Icons.help),
title: Text('Help & Support'),
trailing: Icon(Icons.arrow_forward_ios),
),
const Divider(),
ListTile(
leading: const Icon(Icons.logout, color: Colors.red),
title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
onTap: () {
// TODO: Implement sign out
},
),
],
);
}
{{/screen_type_settings}}

Widget _buildDefaultScreen({{#with_viewmodel}}{{screen_name.pascalCase()}}State state{{/with_viewmodel}}) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.home, size: 64),
const SizedBox(height: 16),
Text(
'Welcome to {{screen_name.titleCase()}}!',
style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Text(
'This is the {{screen_name}} screen in the {{feature}} feature.',
textAlign: TextAlign.center,
),
],
),
);
}
}
