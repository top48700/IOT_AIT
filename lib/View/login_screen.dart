// Unchanged imports...
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'Dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Unchanged variables...
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  String? usernameError;
  String? passwordError;

  void showDialogBox({required bool success, required String message}) {
    AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.scale,
      title: success ? 'Welcome!' : 'Login Failed',
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: success ? Colors.green : Colors.red,
    ).show();
  }

  Future<void> login() async {
    // Unchanged login logic...
    final String username = usernameController.text.trim();
    final String password = passwordController.text.trim();

    setState(() {
      usernameError = username.isEmpty ? 'Username is required' : null;
      passwordError = password.isEmpty ? 'Password is required' : null;
    });

    if (username.isEmpty || password.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      // .timeout(const Duration(seconds: 30));

      if (mounted) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String accessToken = responseData['access_token'];
        final String refreshToken = responseData['refresh_token'];

        if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
          await prefs.setString('refresh_token', refreshToken);
          await prefs.setString('username', username);

          print("Token saved: $accessToken");

          if (mounted) {
            showDialogBox(success: true, message: 'Login successful!');

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      DashboardPage(accessToken: accessToken)),
            );
          }
        } else {
          showDialogBox(
              success: false, message: 'Invalid response: Tokens not found.');
        }
      } else {
        jsonDecode(response.body)['error'] ?? 'Invalid credentials';
        showDialogBox(success: false, message: 'Invalid username or password');
      }
    } catch (error) {
      if(mounted){
        Navigator.pop(context);
      showDialogBox(success: false, message: 'An error occurred: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unchanged UI...
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bacakgroundAIT.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: usernameError,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorText: passwordError,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text("Remember me"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: login,
                    child: const Text("Sign in"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
