import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:autointell_aui/api/api_service.dart';
import 'package:autointell_aui/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget{
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ApiService apiService = ApiService();
  final storage = FlutterSecureStorage();

  void handleLogin() async {
    String? token = await apiService.loginUser(usernameController.text, passwordController.text);
    if(token != null) {
      await storage.write(key: "offline_mode", value: "enabled");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed"))
      );
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("Login"),),
      body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: usernameController, decoration: InputDecoration(labelText: "Username"),),
              TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"),),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: handleLogin, child: Text("Login"))
            ],
          )
      )
    );
  }
}