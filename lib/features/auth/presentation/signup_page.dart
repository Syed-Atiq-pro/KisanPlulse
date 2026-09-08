import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _signUp() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Please complete all required fields.');
      return;
    }
    if (password.text.length < 8) {
      _message('Password must contain at least 8 characters.');
      return;
    }
    if (password.text != confirm.text) {
      _message('Passwords do not match.');
      return;
    }
    setState(() => loading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        data: {'full_name': name.text.trim(), 'role': 'farmer'},
      );
      if (!mounted) return;
      if (response.session != null) {
        context.go('/dashboard');
      } else {
        _message('Account created. Check your email to verify your account.');
        context.pop();
      }
    } on AuthException catch (e) {
      _message(e.message);
    } catch (e) {
      _message('Unable to create account: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create farmer account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Start farming smarter', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Create your AgriSense farmer account.'),
                const SizedBox(height: 28),
                TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline))),
                const SizedBox(height: 14),
                TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', helperText: 'Minimum 8 characters', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)))),
                const SizedBox(height: 14),
                TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.verified_user_outlined))),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: loading ? null : _signUp, child: loading ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account'))),
                const SizedBox(height: 12),
                Center(child: TextButton(onPressed: loading ? null : () => context.pop(), child: const Text('Already have an account? Sign in'))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
