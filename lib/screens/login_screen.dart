import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:autointell_aui/api/api_service.dart';
import 'package:autointell_aui/screens/dashboard_screen.dart';
import 'package:logging/logging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService apiService = ApiService();
  final storage = const FlutterSecureStorage();
  final _logger = Logger('LoginScreen');

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!mounted) return;

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both username and password"),
        ),
      );
      return;
    }

    _logger.info('Attempting login for user: $username');

    try {
      final token = await apiService.loginUser(username, password);
      if (!mounted) return;

      if (token != null) {
        await storage.write(key: "offline_mode", value: "enabled");
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Failed - Please check your credentials"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _logger.severe('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred during login")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: handleLogin, child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}
