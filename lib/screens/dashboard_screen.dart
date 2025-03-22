import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isOnline = true;
  late Connectivity _connectivity;
  late Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((ConnectivityResult result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AutoIntell Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOnline ? "Connected ✅" : "Offline Mode ⚠️",
              style: TextStyle(fontSize: 18, color: isOnline ? Colors.green : Colors.red),
            ),
            SizedBox(height: 20),
            Text("Engine Health Status: 🚗", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
