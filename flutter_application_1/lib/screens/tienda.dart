import 'package:flutter/material.dart';

class Tienda extends StatelessWidget {
  const Tienda({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'Producto 1', 'price': 10.0, 'icon': Icons.shopping_bag},
      {'name': 'Producto 2', 'price': 15.0, 'icon': Icons.local_drink},
      {'name': 'Producto 3', 'price': 20.0, 'icon': Icons.fastfood},
      {'name': 'Producto 4', 'price': 25.0, 'icon': Icons.coffee},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Acción para ir al carrito
              print('Ir al carrito');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Encabezado de bienvenida
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.storefront, size: 100, color: Colors.amber),
                const SizedBox(height: 10),
                const Text(
                  'Bienvenido a la Tienda',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Explora nuestros productos',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(),
          // Lista de productos
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.shade100,
                      child: Icon(
                        product['icon'] as IconData? ?? Icons.error, // Ícono predeterminado
                        color: Colors.amber,
                      ),
                    ),
                    title: Text(
                      product['name'] as String? ?? 'Producto desconocido', // Nombre predeterminado
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '\$${(product['price'] as double? ?? 0.0).toStringAsFixed(2)}', // Precio predeterminado
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Acción para agregar al carrito
                        print('${product['name']} agregado al carrito');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Agregar'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}