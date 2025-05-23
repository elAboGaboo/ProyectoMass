import 'package:flutter/material.dart';
import 'productos_screen.dart';

class Categoria extends StatelessWidget {
  const Categoria({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Cigarros y Vapes', 'icon': Icons.smoking_rooms},
      {'name': 'Cervezas', 'icon': Icons.local_drink},
      {'name': 'RTDs', 'icon': Icons.sports_bar},
      {'name': 'Licores', 'icon': Icons.wine_bar},
      {'name': 'Comidas', 'icon': Icons.fastfood},
      {'name': 'Bebidas', 'icon': Icons.local_cafe},
      {'name': 'Antojos', 'icon': Icons.icecream},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Acción para el carrito
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de dirección
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dirección',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: 'Selecciona una dirección',
                  items: const [
                    DropdownMenuItem(
                      value: 'Selecciona una dirección',
                      child: Text('Selecciona una dirección'),
                    ),
                    DropdownMenuItem(value: 'Casa', child: Text('Casa')),
                    DropdownMenuItem(value: 'Oficina', child: Text('Oficina')),
                  ],
                  onChanged: (value) {
                    // Acción al seleccionar una dirección
                  },
                ),
              ],
            ),
          ),
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // Acción al buscar
              },
            ),
          ),
          const SizedBox(height: 16),
          // Lista de categorías
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade100,
                    child: Icon(
                      category['icon'] as IconData,
                      color: Colors.purple,
                    ),
                  ),
                  title: Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductosScreen(
                              categoria: category['name'] as String,
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
