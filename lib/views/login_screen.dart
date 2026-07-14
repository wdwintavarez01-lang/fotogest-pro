import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(
    text: 'edwin.tavarez@example.com',
  );
  final passwordController = TextEditingController(text: '123456');
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.camera_alt, size: 48),
                    const SizedBox(height: 20),
                    Text(
                      'FotoGest Pro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gestion movil para trabajos fotograficos',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'El correo es obligatorio';
                        }
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Escribe un correo valido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        final password = value?.trim() ?? '';
                        if (password.isEmpty) {
                          return 'La contrasena es obligatoria';
                        }
                        if (password.length < 6) {
                          return 'Debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(isSubmitting ? 'Entrando...' : 'Entrar'),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                setState(() {
                                  isSubmitting = true;
                                });
                                final signedIn = await viewModel.signIn(
                                  email: emailController.text,
                                  password: passwordController.text,
                                );
                                if (!mounted) return;
                                setState(() {
                                  isSubmitting = false;
                                });
                                if (!signedIn &&
                                    viewModel.connectionMessage != null) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        viewModel.connectionMessage!,
                                      ),
                                    ),
                                  );
                                }
                                navigator.pushReplacementNamed(
                                  DashboardScreen.routeName,
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
