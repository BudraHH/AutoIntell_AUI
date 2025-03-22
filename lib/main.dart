import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:autointell_aui/screens/login_screen.dart';
import 'package:autointell_aui/screens/dashboard_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main(){
  runApp(AutoIntellApp());
}

class AutoIntellApp extends StatelessWidget {
  final storage = FlutterSecureStorage();

  Future<bool> checkLoginStatus() async {
    String? token = await storage.read(key: "access_token");
    if(token != null){
      return true;
    }
    String? offlineMode = await storage.read(key: "offline_mode");
    return offlineMode == "enabled";
  }

  Future<bool> isConnected() async{
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
      return MaterialApp(
        title: 'AutoIntell',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FutureBuilder<bool>(
          future: checkLoginStatus(),
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if(snapshot.hasData && snapshot.data == true){
              return DashboardScreen();
            }
            else {
              return LoginScreen();
            }
          },
        ),
      );
  }
}