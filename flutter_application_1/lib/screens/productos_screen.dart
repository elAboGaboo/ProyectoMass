import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_global.dart';

String convertirEnlaceDriveADirecto(String url) {
  final regex = RegExp(r'd/([a-zA-Z0-9_-]+)');
  final match = regex.firstMatch(url);
  if (match != null) {
    final id = match.group(1);
    return 'https://drive.google.com/uc?export=download&id=$id';
  }
  return url;
}

class ProductosScreen extends StatelessWidget {
  final String categoria;
  const ProductosScreen({super.key, required this.categoria});

  void agregarAlCarrito(BuildContext context, Map<String, dynamic> producto) {
    final index = carrito.indexWhere((item) => item['id'] == producto['id']);
    if (index != -1) {
      carrito[index]['cantidad'] = (carrito[index]['cantidad'] ?? 1) + 1;
    } else {
      final nuevoProducto = Map<String, dynamic>.from(producto);
      nuevoProducto['cantidad'] = 1;
      carrito.add(nuevoProducto);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['nombre']} añadido al carrito'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void eliminarDelCarrito(BuildContext context, int index) {
    if ((carrito[index]['cantidad'] ?? 1) > 1) {
      carrito[index]['cantidad'] = carrito[index]['cantidad'] - 1;
    } else {
      carrito.removeAt(index);
      if (carrito.isEmpty) Navigator.of(context).pop();
    }
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Producto eliminado del carrito'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int totalProductosEnCarrito() {
    return carrito.fold<int>(
      0,
      (sum, item) => sum + ((item['cantidad'] ?? 1) as int),
    );
  }

  void mostrarCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8F3FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: false,
      builder:
          (_) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child:
                carrito.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('El carrito está vacío'),
                      ),
                    )
                    : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Carrito (${totalProductosEnCarrito()})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: carrito.length,
                            itemBuilder: (context, index) {
                              final item = carrito[index];
                              final imageUrl = convertirEnlaceDriveADirecto(
                                item['img'] ?? '',
                              );
                              return ListTile(
                                leading:
                                    imageUrl.isNotEmpty
                                        ? Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                  ),
                                        )
                                        : const Icon(Icons.image_not_supported),
                                title: Text(item['nombre'] ?? ''),
                                subtitle: Text(
                                  'Precio: \$${item['precio']}  |  Cantidad: ${item['cantidad']}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => eliminarDelCarrito(context, index),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          ),
    );
  }

  void mostrarDialogoProducto(
    BuildContext context, {
    String? id,
    String? nombre,
    String? descripcion,
    dynamic precio,
    String? img,
  }) {
    final nombreController = TextEditingController(text: nombre ?? '');
    final descripcionController = TextEditingController(
      text: descripcion ?? '',
    );
    final precioController = TextEditingController(
      text: precio?.toString() ?? '',
    );
    final imgController = TextEditingController(text: img ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Nuevo producto' : 'Editar producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                TextField(
                  controller: imgController,
                  decoration: const InputDecoration(labelText: 'URL Imagen'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final data = {
                  'nombre': nombreController.text,
                  'descripcion': descripcionController.text,
                  'precio': double.tryParse(precioController.text) ?? 0,
                  'img': imgController.text,
                  'categoria': categoria,
                };
                if (id == null) {
                  await FirebaseFirestore.instance
                      .collection('productos')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('productos')
                      .doc(id)
                      .update(data);
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productosRef = FirebaseFirestore.instance
        .collection('productos')
        .where('categoria', isEqualTo: categoria);

    return Scaffold(
      appBar: AppBar(
        title: Text('Productos de $categoria'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => mostrarCarrito(context),
                tooltip: 'Ver carrito',
              ),
              if (carrito.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${totalProductosEnCarrito()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: productosRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Error');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Sin productos'));
          return ListView(
            children:
                docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rawImgUrl = data['img'] ?? '';
                  final imageUrl = convertirEnlaceDriveADirecto(rawImgUrl);

                  return ListTile(
                    leading:
                        rawImgUrl.isNotEmpty
                            ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image, size: 40);
                              },
                            )
                            : const Icon(Icons.image_not_supported, size: 40),
                    title: Text(data['nombre'] ?? ''),
                    subtitle: Text(
                      '${data['descripcion'] ?? ''}\nPrecio: \$${data['precio']?.toString() ?? '0'}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.green,
                          ),
                          onPressed:
                              () => agregarAlCarrito(context, {
                                ...data,
                                'id': doc.id,
                                'img': rawImgUrl,
                              }),
                          tooltip: 'Agregar al carrito',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            mostrarDialogoProducto(
                              context,
                              id: doc.id,
                              nombre: data['nombre'],
                              descripcion: data['descripcion'],
                              precio: data['precio'],
                              img: rawImgUrl,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await doc.reference.delete();
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          mostrarDialogoProducto(context);
        },
      ),
    );
  }
}
