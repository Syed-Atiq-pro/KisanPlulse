import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  String language = 'en';
  bool loading = true;
  bool saving = false;

  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    final row = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row != null) {
      name.text = (row['full_name'] as String?) ?? (user.userMetadata?['full_name'] as String?) ?? '';
      phone.text = (row['phone'] as String?) ?? '';
      language = (row['preferred_language'] as String?) ?? 'en';
    } else {
      name.text = (user.userMetadata?['full_name'] as String?) ?? '';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (name.text.trim().length < 2) {
      _message('Enter your full name.');
      return;
    }
    final user = client.auth.currentUser;
    if (user == null) return;
    setState(() => saving = true);
    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': name.text.trim(),
        'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
        'preferred_language': language,
      });
      if (mounted) context.go('/dashboard');
    } on PostgrestException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Could not save profile: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer profile')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        Text('Complete your profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('This helps AgriSense personalize recommendations for your farm.'),
        const SizedBox(height: 28),
        TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 16),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number (optional)', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: language, decoration: const InputDecoration(labelText: 'Preferred language', prefixIcon: Icon(Icons.language)), items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'te', child: Text('తెలుగు')), DropdownMenuItem(value: 'hi', child: Text('हिन्दी'))], onChanged: (v) => setState(() => language = v ?? 'en')),
        const SizedBox(height: 28),
        SizedBox(height: 54, child: FilledButton(onPressed: saving ? null : _save, child: saving ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save and continue'))),
      ])),
    );
  }
}
