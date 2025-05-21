import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/tienda.dart';
import 'screens/categoria.dart';
import 'screens/promos.dart';
import 'screens/pedidos.dart';
import 'screens/cuenta.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que los bindings estén inicializados
  await Firebase.initializeApp(); // Inicializa Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiendas Mass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFC107), // Amarillo principal
        scaffoldBackgroundColor: const Color(0xFFFFF9C4), // Fondo amarillo claro
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFC107), // Fondo amarillo
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black, // Texto negro
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black), // Íconos negros
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFFC107), // Fondo amarillo
          selectedItemColor: Colors.black, // Íconos seleccionados en negro
          unselectedItemColor: Colors.white, // Íconos no seleccionados en blanco
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black), // Texto negro
          bodyMedium: TextStyle(color: Colors.black), // Texto negro
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107), // Fondo amarillo
            foregroundColor: Colors.black, // Texto negro
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Tienda(), // Pantalla de Tienda
    const Categoria(), // Pantalla de Categoría
    const Promos(), // Pantalla de Promos ACTUALIZAR
    const Pedidos(), // Pantalla de Pedidos
    const Cuenta(), // Pantalla de Cuenta
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiendas Mass'),
      ),
      body: _screens[_currentIndex], // Muestra la pantalla seleccionada
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Cambia la pantalla al seleccionar un ítem
          });
        },
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Tienda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categoría',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_offer),
          label: 'Promos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Pedidos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Cuenta',
        ),
      ],
    );
  }
}