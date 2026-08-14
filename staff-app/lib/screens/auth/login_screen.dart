import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff_role.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  StaffRole _role = StaffRole.deliveryPartner;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.badge, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Staff Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login with your assigned role',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                items: StaffRole.values
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _role = val);
                },
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email / Phone',
                  hintText: 'Enter your email or phone',
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password / OTP',
                  hintText: 'Enter your password or OTP',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  await auth.login(
                    identifier: _identifierController.text.trim(),
                    password: _passwordController.text,
                    role: _role,
                  );

                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
