import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.yellow[800],
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sentiment_satisfied),
          label: 'Tienda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Categoría',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Promos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
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