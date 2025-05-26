import 'package:flutter/material.dart';

class Pedidos extends StatelessWidget {
  const Pedidos({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista simulada de pedidos
    final List<Map<String, dynamic>> pedidos = [
      {
        'nombre': 'Pedido #001',
        'estado': 'En camino',
        'precio': 45.50,
        'fecha': '19/05/2025',
      },
      {
        'nombre': 'Pedido #002',
        'estado': 'Entregado',
        'precio': 120.00,
        'fecha': '18/05/2025',
      },
      {
        'nombre': 'Pedido #003',
        'estado': 'Pendiente',
        'precio': 75.30,
        'fecha': '17/05/2025',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos'), centerTitle: true),
      body:
          pedidos.isEmpty
              ? const Center(
                child: Text(
                  'No tienes pedidos registrados.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            pedido['estado'] == 'Entregado'
                                ? Colors.green
                                : pedido['estado'] == 'En camino'
                                ? Colors.orange
                                : Colors.red,
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        pedido['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado: ${pedido['estado']}'),
                          Text('Fecha: ${pedido['fecha']}'),
                        ],
                      ),
                      trailing: Text(
                        'S/ ${pedido['precio'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
