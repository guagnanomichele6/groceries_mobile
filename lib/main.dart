import 'package:flutter/material.dart';

import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il database all'avvio
  await DatabaseHelper.instance.database;
  print("Database SQLite inizializzato correttamente nell'app!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal ERP',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text('Personal ERP Mobile - DB Pronto!')),
      ),
    );
  }
}
