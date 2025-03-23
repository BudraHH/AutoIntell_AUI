import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool isOnline = true;
  late final Connectivity _connectivity;
  late final Stream<ConnectivityResult> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivityStream.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          isOnline = result != ConnectivityResult.none;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AutoIntell Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOnline ? "Connected ✅" : "Offline Mode ⚠️",
              style: TextStyle(
                fontSize: 18,
                color: isOnline ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Engine Health Status: 🚗",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
