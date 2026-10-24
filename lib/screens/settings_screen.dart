import 'package:flutter/material.dart';

import '../settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: SettingsStore.instance.displayName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _saving = true);
    try {
      await SettingsStore.instance.setDisplayName(_nameController.text);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name saved on this phone.')),
      );
    } catch (error) {
      debugPrint('save name failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save the name.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsStore.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'These settings stay on the phone. They are not uploaded anywhere.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'Used for the home greeting',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _saveName,
          child: Text(_saving ? 'Saving...' : 'Save name'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Dark mode'),
          subtitle: const Text('I like this when I study at night.'),
          value: settings.darkMode,
          onChanged: (value) => settings.setDarkMode(value),
        ),
        const SizedBox(height: 12),
        Text(
          'Habit Mastery League',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'A small offline tracker for weekly habits like studying, reading, or water. The week here means the last 7 days. The goal card on Add/Edit is a simple rule, not a trained model. Apply does not save by itself.',
        ),
      ],
    );
  }
}
