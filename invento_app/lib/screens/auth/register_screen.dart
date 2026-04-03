import 'package:flutter/material.dart';
import 'package:invento_app/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
	const RegisterScreen({super.key});

	@override
	State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
	final emailController = TextEditingController();
	final passwordController = TextEditingController();
	final authController = AuthController();

	Future<void> register() async {
		final user = await authController.registerUser(
			emailController.text,
			passwordController.text,
		);

		if (!mounted) return;

		if (user != null) {
			Navigator.pushReplacementNamed(context, '/home');
			return;
		}

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('Registration failed')),
		);
	}

	@override
	void dispose() {
		emailController.dispose();
		passwordController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text('Register')),
			body: Padding(
				padding: EdgeInsets.all(16),
				child: Column(
					children: [
						TextField(
							controller: emailController,
							decoration: InputDecoration(labelText: 'Email'),
						),
						TextField(
							controller: passwordController,
							decoration: InputDecoration(labelText: 'Password'),
							obscureText: true,
						),
						SizedBox(height: 20),
						ElevatedButton(
							onPressed: register,
							child: Text('Register'),
						),
					],
				),
			),
		);
	}
}
