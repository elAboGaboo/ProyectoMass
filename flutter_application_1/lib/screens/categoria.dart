import 'package:flutter/material.dart';

class Categoria extends StatelessWidget {
  const Categoria({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Comidas',
      'Bebidas',
      'Licores',
      'Abarrotes',
      'Cervezas',
      'Limpieza',
      'Promos',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CATEGORIA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CustomListTile(
            title: categories[index],
            subtitle: 'Ver productos',
            onEdit: () {},
            onDelete: () {},
          );
        },
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomListTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}