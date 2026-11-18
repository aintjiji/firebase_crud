import 'package:firebase_crud/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crud/auth_service.dart';
import 'package:firebase_crud/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        auth: auth,
        initialEmail: emailCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    if (sent == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "If an account exists for that email, a reset link has been sent. "
            "Check your inbox (and spam folder).",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login_Caras")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Email Login ---
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              // --- Forgot Password ---
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : _showForgotPasswordDialog,
                  child: const Text("Forgot password?"),
                ),
              ),
              const SizedBox(height: 4),

              ElevatedButton(
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login with Email"),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await auth.signInWithEmail(
                    emailCtrl.text.trim(),
                    passwordCtrl.text,
                  );
                  if (!mounted) return;
                  setState(() => loading = false);

                  if (user != null) {
                    if (!user.emailVerified) {
                      await auth.signOut();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Please verify your email before logging in."),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => HomePage()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Invalid email or password")),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              // --- Google Sign-In ---
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Sign in with Google"),
                onPressed: () async {
                  setState(() => loading = true);
                  final user = await auth.signInWithGoogle();
                  if (!mounted) return;
                  setState(() => loading = false);

                  if (user != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                child: const Text("Don't have an account? Register"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog that owns its own controller so it's disposed safely.
class _ForgotPasswordDialog extends StatefulWidget {
  final AuthService auth;
  final String initialEmail;

  const _ForgotPasswordDialog({
    required this.auth,
    required this.initialEmail,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailCtrl;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = "Please enter a valid email address.");
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    final error = await widget.auth.sendPasswordResetEmail(email);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reset password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter your email and we'll send you a reset link."),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            enabled: !_sending,
            decoration: InputDecoration(
              labelText: "Email",
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Send link"),
        ),
      ],
    );
  }
}
