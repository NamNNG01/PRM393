import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/order.dart';
import 'models/configuration.dart';
import 'models/event.dart';
import 'models/customer.dart';
import 'models/ticket.dart';
import 'screens/home.dart';

import 'hive/hive_boxes.dart';
import 'hive/config_box.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(ConfigurationAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(TicketAdapter());
  await Hive.openBox<Ticket>(HiveBoxes.ticketBox);
  await Hive.openBox<Order>(HiveBoxes.orderBox);
  await Hive.openBox<Configuration>(HiveBoxes.configBox);
  await Hive.openBox<Event>(HiveBoxes.eventBox);
  await Hive.openBox(ConfigBox.boxName);
  await Hive.openBox<Customer>(HiveBoxes.customerBox);
  final configBox = Hive.box<Configuration>(HiveBoxes.configBox);

  if (configBox.isEmpty) {
    configBox.add(
      Configuration(
        ticketPriceA: 1000,
        refundRateA: 80,
        commissionRateA: 0.3,
        ticketPriceB: 23000,
        refundRateB: 80000,
        commissionPerPointB: 1000,
        maxRiskMultiplier: 2,
      ),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản Lý Đại Lý Vé Số',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}
