import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/tienda.dart';
import 'package:flutter_application_1/screens/categoria.dart';
import 'package:flutter_application_1/screens/promos.dart';
import 'package:flutter_application_1/screens/pedidos.dart';
import 'package:flutter_application_1/screens/cuenta.dart';
import 'package:flutter_application_1/widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState(); // Corregido el nombre del estado
}

class HomeScreenState extends State<HomeScreen> { // Corregido el nombre de la clase
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Tienda(),
    const Categoria(),
    const Promos(),
    const Pedidos(),
    const Cuenta(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiendas Mass'),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}