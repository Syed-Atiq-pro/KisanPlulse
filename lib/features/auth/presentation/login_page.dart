import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Enter your email and password.');
      return;
    }
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Unable to sign in: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.agriculture_rounded, size: 32),
                ),
                const SizedBox(height: 28),
                Text('Welcome to AgriSense', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Your intelligent farming companion.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 32),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline))),
                const SizedBox(height: 14),
                TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: loading ? null : _signIn, child: loading ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'))),
                const SizedBox(height: 18),
                Center(child: TextButton(onPressed: loading ? null : () => context.go('/signup'), child: const Text('Create a farmer account'))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
